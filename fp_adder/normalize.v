module fp_normalize27 (
  input  [26:0] sum27,     // CLA result lane
  input         add_sub,   // 0 = add path, 1 = sub (cancellation) path
  input         carry,     // carry-out from CLA (used in add path)
  input  [8:0]  exp_in,    // working (biased) exponent of the larger operand
  input         sticky_in, // accumulated sticky so far (from alignment)
  output [23:0] mant24_out,// normalized 24-bit significand (1.int23 or 0 for zero)
  output        G_out,     // guard bit after normalization
  output        R_out,     // round bit after normalization
  output        sticky_out,// accumulated sticky after normalization
  output [8:0]  exp_out,   // adjusted working exponent
  output        is_zero    // magnitude is exactly zero
);

  wire zero_mag = (sum27 == 27'd0);

  // --------------------------
  // ADD path (carry-based)
  // --------------------------
  wire [26:0] add_lane = carry ? {1'b0, sum27[26:1]} : sum27;
  wire [8:0]  add_exp  = carry ? (exp_in + 9'd1)     : exp_in;
  wire        add_stky = carry ? (sticky_in | sum27[0]) : sticky_in;

  // --------------------------
  // SUB path (cancellation)
  // --------------------------
  // Count leading zeros on the 24-bit significand field [25:2]
  wire [4:0] lzc;
  lzc24 u_lzc24 (.in(sum27[25:2]), .count(lzc));

  // Left shift by lzc to restore leading 1 (if not zero)
  wire [26:0] sub_lane = zero_mag ? 27'd0 : (sum27 << lzc);
  wire [8:0]  sub_exp  = exp_in - {4'd0, lzc};

  // Bits shifted out on the right during left shift contribute to sticky
  // Build a mask of the lowest 'lzc' bits: low_mask[ i ] = 1 iff i < lzc
  wire [26:0] low_mask = (lzc == 5'd0) ? 27'd0
                                       : ({27{1'b1}} >> (6'd27 - {1'b0,lzc}));
  wire        sub_drop = |(sum27 & low_mask);
  wire        sub_stky = sticky_in | sub_drop;

  // --------------------------
  // Select path
  // --------------------------
  wire [26:0] lane_sel = add_sub ? sub_lane : add_lane;
  wire [8:0]  exp_sel  = add_sub ? sub_exp  : add_exp;
  wire        stky_sel = add_sub ? sub_stky : add_stky;

  assign mant24_out = lane_sel[25:2];
  assign G_out      = lane_sel[1];
  assign R_out      = lane_sel[0];
  assign sticky_out = stky_sel;
  assign exp_out    = zero_mag ? exp_in : exp_sel;
  assign is_zero    = zero_mag;

endmodule

// 24-bit leading-zero counter (MSB at bit 23)
module lzc24 (
  input  [23:0] in,
  output [4:0]  count
);
  reg [4:0] c;
  integer i;
  always @(*) begin
    if (in == 24'd0) begin
      c = 5'd24;
    end else begin
      c = 5'd0;
      for (i = 23; i >= 0; i = i - 1) begin
        if (in[i]) begin
          c = 5'd23 - i; // number of leading zeros
          i = -1;        // break
        end
      end
    end
  end
  assign count = c;
endmodule