module fp_add (
  input         clk,
  input         rst_n,
  input         in_valid,
  input  [31:0] a,
  input  [31:0] b,
  output        out_valid,
  output [31:0] result
);

  // ----------------------------
  // Valid pipeline (3 stages)
  // ----------------------------
  reg v1, v2, v3;
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) {v1,v2,v3} <= 3'b0;
    else begin
      v1 <= in_valid;
      v2 <= v1;
      v3 <= v2;
    end
  end
  assign out_valid = v3;

  // =====================================================
  // S1 — Unpack, compare, align-prep + align (COMB)
  // =====================================================
  wire        s1_sign_a, s1_sign_b;
  wire [7:0]  s1_exp_a,  s1_exp_b;
  wire [23:0] s1_sig_a,  s1_sig_b;

  unpack32 u_up_a(
    .in       (a),
    .sign     (s1_sign_a),
    .exp      (s1_exp_a),
    .mantissa (s1_sig_a)
  );

  unpack32 u_up_b(
    .in       (b),
    .sign     (s1_sign_b),
    .exp      (s1_exp_b),
    .mantissa (s1_sig_b)
  );

  // Effective exponents (subnormals -> 1)
  wire [8:0] s1_Eeff_a = (s1_exp_a == 8'h00) ? 9'd1 : {1'b0, s1_exp_a};
  wire [8:0] s1_Eeff_b = (s1_exp_b == 8'h00) ? 9'd1 : {1'b0, s1_exp_b};

  // Compare big/small (by exponent then significand)
  wire s1_a_ge_b = (s1_Eeff_a > s1_Eeff_b) ? 1'b1 :
                   (s1_Eeff_a < s1_Eeff_b) ? 1'b0 :
                   (s1_sig_a >= s1_sig_b);

  wire        s1_sign_big   = s1_a_ge_b ? s1_sign_a : s1_sign_b;
  wire        s1_sign_small = s1_a_ge_b ? s1_sign_b : s1_sign_a;
  wire [8:0]  s1_E_big      = s1_a_ge_b ? s1_Eeff_a : s1_Eeff_b;
  wire [8:0]  s1_E_small    = s1_a_ge_b ? s1_Eeff_b : s1_Eeff_a;
  wire [23:0] s1_M_big      = s1_a_ge_b ? s1_sig_a  : s1_sig_b;
  wire [23:0] s1_M_small    = s1_a_ge_b ? s1_sig_b  : s1_sig_a;

  // Shift amount (cap at lane width 27)
  wire [8:0]  s1_shift_raw  = s1_E_big - s1_E_small;
  wire [5:0]  s1_shift_amt  = (s1_shift_raw > 9'd27) ? 6'd27 : s1_shift_raw[5:0];

  // Effective op: same sign = add, different = subtract
  wire s1_eff_sub = s1_sign_a ^ s1_sign_b;

  // 27-bit lane: [26]=headroom | [25:2]=sig24 | [1]=G | [0]=R
  wire [26:0] s1_X_pre = {1'b0, s1_M_big,   2'b00};
  wire [26:0] s1_Y_pre = {1'b0, s1_M_small, 2'b00};

  wire [26:0] s1_Y_aligned;
  wire        s1_guard_unused, s1_round_unused, s1_sticky_align;

  align_smaller #(.W(27)) u_align (
    .in_val      (s1_Y_pre),
    .shift_amt   ({2'b00, s1_shift_amt}), // widen to 8b
    .aligned_val (s1_Y_aligned),
    .guard       (s1_guard_unused),
    .round       (s1_round_unused),
    .sticky      (s1_sticky_align)
  );

  // S1->S2 regs
  reg [26:0] r2_X_pre, r2_Y_aligned;
  reg        r2_sticky, r2_eff_sub, r2_sign_big;
  reg [8:0]  r2_E_big;

  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      r2_X_pre      <= 27'd0;
      r2_Y_aligned  <= 27'd0;
      r2_sticky     <= 1'b0;
      r2_eff_sub    <= 1'b0;
      r2_sign_big   <= 1'b0;
      r2_E_big      <= 9'd0;
    end else begin
      r2_X_pre      <= s1_X_pre;
      r2_Y_aligned  <= s1_Y_aligned;
      r2_sticky     <= s1_sticky_align;
      r2_eff_sub    <= s1_eff_sub;
      r2_sign_big   <= s1_sign_big;
      r2_E_big      <= s1_E_big;
    end
  end

  // =====================================================
  // S2 — Magnitude add/sub with CLA + Normalize
  // =====================================================
  wire [31:0] s2_A32     = {5'b0, r2_X_pre};
  wire [31:0] s2_B32_in  = {5'b0, r2_Y_aligned};
  wire [31:0] s2_B32_eff = r2_eff_sub ? ~s2_B32_in : s2_B32_in;
  wire        s2_Cin     = r2_eff_sub;

  wire        s2_cout;
  wire [31:0] s2_S32, s2_dbg_and, s2_dbg_or;

  second_level_lookahead u_cla (
    .data_operandA (s2_A32),
    .data_operandB (s2_B32_eff),
    .Cin           (s2_Cin),
    .C32out        (s2_cout),
    .S             (s2_S32),
    .AandB         (s2_dbg_and),
    .AorB          (s2_dbg_or)
  );

  wire [26:0] s2_sum27 = s2_S32[26:0];

  // Normalize
  wire [23:0] s2_mant24;
  wire        s2_G, s2_R, s2_S;
  wire [8:0]  s2_E;
  wire        s2_is_zero;

  fp_normalize27 u_norm (
    .sum27      (s2_sum27),
    .add_sub    (r2_eff_sub), // 0=add, 1=sub
    .carry      (s2_cout),    // unused inside, but wired for interface
    .exp_in     (r2_E_big),
    .sticky_in  (r2_sticky),
    .mant24_out (s2_mant24),
    .G_out      (s2_G),
    .R_out      (s2_R),
    .sticky_out (s2_S),
    .exp_out    (s2_E),
    .is_zero    (s2_is_zero)
  );

  // S2->S3 regs
  reg [23:0] r3_mant24;
  reg        r3_G, r3_R, r3_S, r3_sign, r3_is_zero;
  reg [8:0]  r3_E;

  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      r3_mant24  <= 24'd0;
      r3_G       <= 1'b0;
      r3_R       <= 1'b0;
      r3_S       <= 1'b0;
      r3_E       <= 9'd0;
      r3_sign    <= 1'b0;
      r3_is_zero <= 1'b0;
    end else begin
      r3_mant24  <= s2_mant24;
      r3_G       <= s2_G;
      r3_R       <= s2_R;
      r3_S       <= s2_S;
      r3_E       <= s2_E;
      r3_sign    <= r2_sign_big;
      r3_is_zero <= s2_is_zero;
    end
  end

  // =====================================================
  // S3 — Round & Pack
  // =====================================================
  wire [31:0] s3_result;

  round_pack u_rp (
    .mant24_in (r3_mant24),
    .G         (r3_G),
    .R         (r3_R),
    .S         (r3_S),
    .E_in      (r3_E),
    .sign_in   (r3_sign),
    .is_zero_in(r3_is_zero),
    .result    (s3_result)
  );

  // Output reg
  reg [31:0] r_out;
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) r_out <= 32'd0;
    else        r_out <= s3_result;
  end

  assign result = r_out;

endmodule