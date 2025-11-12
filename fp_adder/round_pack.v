module round_pack (
  input  [23:0] mant24_in,  // normalized: {hidden1, frac[22:0]}
  input         G,          // guard (bit just below LSB of frac)
  input         R,          // round bit
  input         S,          // sticky (OR of remaining discarded bits)
  input  [8:0]  E_in,       // biased working exponent (after normalize)
  input         sign_in,
  output [31:0] result
);

  // -------- RNE increment predicate --------
  wire lsb      = mant24_in[0];
  wire inc_rne  = G & (R | S | lsb);

  // -------- Add 1 ULP to the 24-bit mantissa --------
  wire [24:0] mant25_sum   = {1'b0, mant24_in} + {24'd0, inc_rne};
  wire        mant_ovf     = mant25_sum[24];         // carry out
  wire [23:0] mant24_post  = mant25_sum[23:0];

  // If mantissa overflowed, shift right by 1 and bump exponent
  wire [23:0] mant24_final = mant_ovf ? {1'b1, mant24_post[23:1]} : mant24_post;
  wire [8:0]  E_round      = mant_ovf ? (E_in + 9'd1) : E_in;

  // -------- Exponent edge handling --------
  // Overflow to infinity if exponent reaches or exceeds 255 after rounding
  wire exp_overflow = (E_round >= 9'd255);

  // (MVP) Underflow: flush-to-zero if exponent <= 0 after rounding
  // You can replace this with true subnormal handling later.
  wire exp_underflow = (E_round <= 9'd0);

  // -------- Pack --------
  wire [7:0]  exp_field   = E_round[7:0];
  wire [22:0] frac_field  = mant24_final[22:0];

  wire [31:0] packed_norm = {sign_in, exp_field, frac_field};
  wire [31:0] packed_inf  = {sign_in, 8'hFF, 23'h000000};
  wire [31:0] packed_zero = {sign_in, 8'h00, 23'h000000};

  assign result =
      exp_overflow  ? packed_inf  :
      exp_underflow ? packed_zero :
                      packed_norm;

endmodule