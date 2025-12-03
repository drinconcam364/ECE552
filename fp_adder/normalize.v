// =======================================================
// fp_normalize27
//  - Input lane: [26]=headroom | [25:2]=sig24 | [1]=G | [0]=R
//  - add_sub = 0: same-sign add path
//  - add_sub = 1: subtract / cancellation path
//  - sticky_in: sticky accumulated so far (from alignment / earlier)
//  - Outputs: normalized mantissa + G/R/S + adjusted exponent + zero flag
// =======================================================
module fp_normalize27 (
  input  [26:0] sum27,      // CLA result lane
  input         add_sub,    // 0 = add path, 1 = sub (cancellation) path
  input         carry,      // UNUSED in this implementation (kept for interface)
  input  [8:0]  exp_in,     // working exponent of larger operand
  input         sticky_in,  // sticky accumulated so far
  output [23:0] mant24_out, // normalized 24-bit mantissa (1.int23 or 0)
  output        G_out,      // guard bit after normalization
  output        R_out,      // round bit after normalization
  output        sticky_out, // sticky after normalization
  output [8:0]  exp_out,    // adjusted exponent
  output        is_zero     // magnitude exactly zero
);

  // Magnitude zero?
  wire zero_mag = (sum27 == 27'd0);

  // --------------------------
  // ADD path (same-sign add)
  // --------------------------
  // If headroom bit is set, result > 2.0 -> shift right by 1 and bump exponent
  wire        add_overflow = sum27[26];

  wire [26:0] add_lane =
      add_overflow ? {1'b0, sum27[26:1]} : sum27;

  wire [8:0]  add_exp  =
      add_overflow ? (exp_in + 9'd1) : exp_in;

  // Dropped bit when shifting right contributes to sticky
  wire        add_stky =
      add_overflow ? (sticky_in | sum27[0]) : sticky_in;

  // --------------------------
  // SUB path (cancellation)
  // --------------------------
  // Count leading zeros on 24-bit segment [25:2]
  wire [4:0] lzc;
  lzc24 u_lzc24 (
    .in   (sum27[25:2]),
    .count(lzc)
  );

  // Clip shift so exponent never underflows (unsigned wrap)
  // If exp_in is too small, we only shift as much as exponent allows.
  wire [4:0] exp_lsb   = exp_in[4:0];
  wire [4:0] sub_shift = (exp_lsb < lzc) ? exp_lsb : lzc;

  // Left-shift to restore leading 1 (as much as exponent permits)
  wire [26:0] sub_lane = zero_mag ? 27'd0 : (sum27 << sub_shift);
  wire [8:0]  sub_exp  = exp_in - {4'd0, sub_shift};

  // Left shift does not create new low-order bits; keep sticky as-is
  wire        sub_stky = sticky_in;

  // --------------------------
  // Select ADD vs SUB path
  // --------------------------
  wire [26:0] lane_sel = add_sub ? sub_lane : add_lane;
  wire [8:0]  exp_sel  = add_sub ? sub_exp  : add_exp;
  wire        stky_sel = add_sub ? sub_stky : add_stky;

  // Extract normalized mantissa and G/R from lane
  assign mant24_out = lane_sel[25:2];
  assign G_out      = lane_sel[1];
  assign R_out      = lane_sel[0];
  assign sticky_out = stky_sel;

  // For exact zero, force exponent to 0 and flag is_zero
  assign exp_out = zero_mag ? 9'd0 : exp_sel;
  assign is_zero = zero_mag;

endmodule


// =======================================================
// lzc24 : 24-bit leading-zero counter (MSB at bit 23)
//  - count = number of leading zeros in 'in'
//  - if in==0, count = 24
// =======================================================
module lzc24 (
  input  [23:0] in,
  output [4:0]  count
);
  reg [4:0] c;
  integer i;
  reg found;

  always @(*) begin
    if (in == 24'd0) begin
      c = 5'd24;
    end else begin
      c     = 5'd0;
      found = 1'b0;
      // Scan from MSB down to LSB
      for (i = 23; i >= 0; i = i - 1) begin
        if (!found && in[i]) begin
          c     = 5'd23 - i;  // number of leading zeros
          found = 1'b1;
        end
      end
    end
  end

  assign count = c;
endmodule
