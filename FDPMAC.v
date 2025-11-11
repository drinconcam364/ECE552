module FDPMAC(
    rs1, rs2, rs3, clk);
    input [31:0] rs1, rs2, rs3;
    input clk;
    output reg [31:0] out;
    wire sign_a, sign_b, sign_c, sign_d, acc_sign;
    wire [4:0] exponent;
    wire [10:0] mantissa_a, mantissa_b, mantissa_c, mantissa_d;
    // Align a, b, c, and c with same exponent block so all mantissas can be added together and have a fused partial product wallace tree
    align_exps align(
        .a(rs1[15:0]), 
        .b(rs1[31:16]), 
        .c(rs2[15:0]), 
        .d(rs2[31:16]), 
        .sign_a(sign_a), 
        .sign_b(sign_b), 
        .sign_c(sign_c), 
        .sign_d(sign_d), 
        .exp(exponent), 
        .mantissa_a_scaled(mantissa_a), 
        .mantissa_b_scaled(mantissa_b), 
        .mantissa_c_scaled(mantissa_c), 
        .mantissa_d_scaled(mantissa_d)
    );
    wire signed[23:0] pp0, pp1, pp2, pp3, pp4, pp5, pp6, pp7, pp8, pp9, pp10, pp11;
    radix4 ab(
        .multiplicand(mantissa_a), 
        .multiplier(mantissa_b), 
        .pp0(pp0),
        .pp1(pp1), 
        .pp2(pp2), 
        .pp3(pp3), 
        .pp4(pp4), 
        .pp5(pp5)
    );
    radix4 cd(
        .multiplicand(mantissa_c), 
        .multiplier(mantissa_d), 
        .pp0(pp6),
        .pp1(pp7), 
        .pp2(pp8), 
        .pp3(pp9), 
        .pp4(pp10), 
        .pp5(pp11)
    );
    wire [23:0] wallace_sum, wallace_carry, mantissa_ab_cd_sum;
    wallace_12x24 wallace(
        .pp0(pp0), 
        .pp1(pp1), 
        .pp2(pp2), 
        .pp3(pp3), 
        .pp4(pp4), 
        .pp5(pp5), 
        .pp6(pp6), 
        .pp7(pp7), 
        .pp8(pp8), 
        .pp9(pp9), 
        .pp10(pp10), 
        .pp11(pp11),
        .sum(wallace_sum), 
        .carry(wallace_carry)
    );
    // Once wallace outputs sum and carry, use CLA adder to add sum and carry, giving final mantissa, then normalize, round, and pack 
    assign mantissa_ab_cd_sum = wallace_sum + (wallace_carry << 1);
    wire [7:0] abcd_32_exponent, acc_exp;
    wire [23:0] abcd_32_mantissa, acc_mantissa;
    normalize norm(
        .mantissa_in(mantissa_ab_cd_sum), 
        .exp_in(exponent), 
        .mantissa_out(abcd_32_mantissa), 
        .exp_out(abcd_32_exponent)
    );
    fp32_unpack acc_unpack(
        .in(rs3),
        .sign(acc_sign),
        .exp(acc_exp),
        .mantissa(acc_mantissa)
    );




endmodule
