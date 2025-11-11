module FDPMAC(
    rs1, rs2, rs3, clk);
    input [31:0] rs1, rs2, rs3;
    input clk;
    output reg [31:0] out;
    wire sign_a, sign_b, sign_c, sign_d;
    wire [4:0] exp_a, exp_b, exp_c, exp_d;
    wire [10:0] mantissa_a, mantissa_b, mantissa_c, mantissa_d;
    wire signed[23:0] pp0, pp1, pp2, pp3, pp4, pp5, pp6, pp7, pp8, pp9, pp10, pp11;
    unpack unpack_a(.in(rs1[15:0]), .sign(sign_a), .exp(exp_a), .mantissa(mantissa_a));
    unpack unpack_b(.in(rs1[31:16]), .sign(sign_b), .exp(exp_b), .mantissa(mantissa_b));
    unpack unpack_c(.in(rs2[15:0]), .sign(sign_c), .exp(exp_c), .mantissa(mantissa_c));
    unpack unpack_d(.in(rs2[31:16]), .sign(sign_d), .exp(exp_d), .mantissa(mantissa_d));
    // Need to compare exponent of (a*b) with exponent of (c*d), the larger one acts as the reference, and get exp_difference by subtracting the larger exponent by the smaller exponent, 
    radix4 a_mul_b(.multiplicand(mantissa_a), .multiplier(mantissa_b), .pp0(pp0),.pp1(pp1), .pp2(pp2), .pp3(pp3), .pp4(pp4), .pp5(pp5));
    radix4 c_mul_d(.multiplicand(mantissa_c), .multiplier(mantissa_d), .pp0(pp6),.pp1(pp7), .pp2(pp8), .pp3(pp9), .pp4(pp10), .pp5(pp11));
    wallace_12x24 wallace(.pp0(pp0), .pp1(pp1), .pp2(pp2), .pp3(pp3), .pp4(pp4), .pp5(pp5), .pp6(pp6), .pp7(pp7), .pp8(pp8), .pp9(pp9), .pp10(pp10), .pp11(pp11).sum(wallace_sum), .carry(wallace_carry));
    // Once wallace outputs sum and carry, use CLA adder to add sum and carry, giving final mantissa, then normalize, round, and pack 
    




endmodule
