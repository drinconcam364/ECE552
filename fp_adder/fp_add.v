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
  // Valid pipeline (5 stages)
  // ----------------------------
  reg v1, v2, v3, v4, v5;
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) {v1,v2,v3,v4,v5} <= 5'b0;
    else begin
      v1 <= in_valid;
      v2 <= v1;
      v3 <= v2;
      v4 <= v3;
      v5 <= v4;
    end
  end
  assign out_valid = v5;

  // =====================================================
  // S1 — Unpack, compare, align-prep (COMB)
  // =====================================================
  wire        s1_sign_a, s1_sign_b;
  wire [7:0]  s1_exp_a,  s1_exp_b;
  wire [23:0] s1_sig_a,  s1_sig_b;

  unpack32 u_up_a(.in(a), .sign(s1_sign_a), .exp(s1_exp_a), .mantissa(s1_sig_a));
  unpack32 u_up_b(.in(b), .sign(s1_sign_b), .exp(s1_exp_b), .mantissa(s1_sig_b));

  // Effective exponents (subnormals -> 1)
  wire [8:0] s1_Eeff_a = (s1_exp_a == 8'h00) ? 9'd1 : {1'b0, s1_exp_a};
  wire [8:0] s1_Eeff_b = (s1_exp_b == 8'h00) ? 9'd1 : {1'b0, s1_exp_b};

  // Compare → big/small (by exponent then significand)
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

  // S1→S2 regs
  reg        r2_sign_big, r2_eff_sub;
  reg [8:0]  r2_E_big;
  reg [23:0] r2_M_big, r2_M_small;
  reg [5:0]  r2_shift_amt;
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      r2_sign_big   <= 1'b0;
      r2_eff_sub    <= 1'b0;
      r2_E_big      <= 9'd0;
      r2_M_big      <= 24'd0;
      r2_M_small    <= 24'd0;
      r2_shift_amt  <= 6'd0;
    end else if (v1) begin
      r2_sign_big   <= s1_sign_big;
      r2_eff_sub    <= s1_eff_sub;
      r2_E_big      <= s1_E_big;
      r2_M_big      <= s1_M_big;
      r2_M_small    <= s1_M_small;
      r2_shift_amt  <= s1_shift_amt;
    end
  end

  // =====================================================
  // S2 — Align small (27-bit lane) + accumulate sticky (COMB)
  // Lane layout: [26]=headroom | [25:2]=24b significand | [1]=G | [0]=R
  // =====================================================
  wire [26:0] s2_X_pre = {1'b0, r2_M_big,   2'b00};
  wire [26:0] s2_Y_pre = {1'b0, r2_M_small, 2'b00};

  wire [26:0] s2_Y_aligned;
  wire s2_guard_unused, s2_round_unused, s2_sticky;

  align_smaller #(.W(27)) u_align (
    .in_val     (s2_Y_pre),
    .shift_amt  ({2'b00, r2_shift_amt}), // widen to 8b
    .aligned_val(s2_Y_aligned),
    .guard      (s2_guard_unused),   
    .round      (s2_round_unused),
    .sticky     (s2_sticky)  
  );

  // S2→S3 regs
  reg [26:0] r3_X_pre, r3_Y_aligned;
  reg        r3_sticky, r3_eff_sub, r3_sign_big;
  reg [8:0]  r3_E_big;
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      r3_X_pre      <= 27'd0;
      r3_Y_aligned  <= 27'd0;
      r3_sticky     <= 1'b0;
      r3_eff_sub    <= 1'b0;
      r3_sign_big   <= 1'b0;
      r3_E_big      <= 9'd0;
    end else if (v2) begin
      r3_X_pre      <= s2_X_pre;
      r3_Y_aligned  <= s2_Y_aligned;
      r3_sticky     <= s2_sticky;
      r3_eff_sub    <= r2_eff_sub;
      r3_sign_big   <= r2_sign_big;
      r3_E_big      <= r2_E_big;
    end
  end

  // =====================================================
  // S3 — Magnitude add/sub with CLA (COMB)
  // =====================================================
  wire [31:0] s3_A32     = {5'b0, r3_X_pre};
  wire [31:0] s3_B32_in  = {5'b0, r3_Y_aligned};
  wire [31:0] s3_B32_eff = r3_eff_sub ? ~s3_B32_in : s3_B32_in;
  wire        s3_Cin     = r3_eff_sub;

  wire        s3_cout;
  wire [31:0] s3_S32, s3_dbg_and, s3_dbg_or;

  second_level_lookahead u_cla (
    .data_operandA (s3_A32),
    .data_operandB (s3_B32_eff),
    .Cin           (s3_Cin),
    .C32out        (s3_cout),
    .S             (s3_S32),
    .AandB         (s3_dbg_and),
    .AorB          (s3_dbg_or)
  );

  wire [26:0] s3_sum27 = s3_S32[26:0];

  // S3→S4 regs
  reg [26:0] r4_sum27;
  reg        r4_carry, r4_sticky, r4_eff_sub, r4_sign_big;
  reg [8:0]  r4_E_big;
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      r4_sum27    <= 27'd0;
      r4_carry    <= 1'b0;
      r4_sticky   <= 1'b0;
      r4_eff_sub  <= 1'b0;
      r4_sign_big <= 1'b0;
      r4_E_big    <= 9'd0;
    end else if (v3) begin
      r4_sum27    <= s3_sum27;
      r4_carry    <= s3_cout;
      r4_sticky   <= r3_sticky;   // carry sticky forward
      r4_eff_sub  <= r3_eff_sub;
      r4_sign_big <= r3_sign_big;
      r4_E_big    <= r3_E_big;
    end
  end

  // =====================================================
  // S4 — Normalize (COMB, one-shot; no loops)
  // =====================================================
  wire [23:0] s4_mant24;
  wire        s4_G, s4_R, s4_S;
  wire [8:0]  s4_E;
  wire        s4_is_zero;

  fp_normalize27 u_norm (
    .sum27      (r4_sum27),
    .add_sub    (r4_eff_sub),   // 0=add, 1=sub
    .carry      (r4_carry),
    .exp_in     (r4_E_big),
    .sticky_in  (r4_sticky),
    .mant24_out (s4_mant24),
    .G_out      (s4_G),
    .R_out      (s4_R),
    .sticky_out (s4_S),         // updated sticky including normalize drops
    .exp_out    (s4_E),
    .is_zero    (s4_is_zero)
  );

  // S4→S5 regs
  reg [23:0] r5_mant24;
  reg        r5_G, r5_R, r5_S, r5_sign;
  reg [8:0]  r5_E;
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      r5_mant24 <= 24'd0;
      r5_G      <= 1'b0;
      r5_R      <= 1'b0;
      r5_S      <= 1'b0;
      r5_E      <= 9'd0;
      r5_sign   <= 1'b0;
    end else if (v4) begin
      r5_mant24 <= s4_mant24;
      r5_G      <= s4_G;        // these are the ONLY G/R used for rounding
      r5_R      <= s4_R;
      r5_S      <= s4_S;
      r5_E      <= s4_E;
      r5_sign   <= r4_sign_big; // sign policy (big's sign for non-zero)
    end
  end

  // =====================================================
  // S5 — Round & Pack (COMB)
  // =====================================================
  wire [31:0] s5_result;
  round_pack rp (
    .mant24_in (r5_mant24),
    .G         (r5_G),
    .R         (r5_R),
    .S         (r5_S),
    .E_in      (r5_E),
    .sign_in   (r5_sign),
    .result    (s5_result)
  );

  // Output reg
  reg [31:0] r_out;
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) r_out <= 32'd0;
    else if (v5) r_out <= s5_result;
  end
  assign result = r_out;

endmodule