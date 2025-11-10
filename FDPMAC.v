module FDPMAC(
    rs1, rs2, rs3, clk);
    input [31:0] rs1, rs2, rs3;
    input clk;
    output reg [31:0] out;
    wire sign_a, sign_b, sign_c, sign_d;
    wire [4:0] exp_a, exp_b, exp_c, exp_d;
    wire [10:0] mantissa_a, mantissa_b, mantissa_c, mantissa_d;
    unpack unpack_a(.in(rs1[15:0]), .sign(sign_a), .exp(exp_a), .mantissa(mantissa_a));
    unpack unpack_b(.in(rs1[31:16]), .sign(sign_b), .exp(exp_b), .mantissa(mantissa_b));
    unpack unpack_c(.in(rs2[15:0]), .sign(sign_c), .exp(exp_c), .mantissa(mantissa_c));
    unpack unpack_d(.in(rs2[31:16]), .sign(sign_d), .exp(exp_d), .mantissa(mantissa_d));
    mult a_mul_b(.sign_a(sign_a), .sign_b(sign_b), .exp_a(exp_a), .exp_b(exp_b), .mantissa_a(mantissa_a), .mantissa_b(mantissa_b));
    




end module