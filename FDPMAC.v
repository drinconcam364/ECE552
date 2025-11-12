module FDPMAC(rs1, rs2, rs3, clk, out);
    input [31:0] rs1, rs2, rs3;
    input clk;
    output reg [31:0] out;
    wire sign_a, sign_b, sign_c, sign_d;
    wire [4:0] exponent;
    wire [10:0] mantissa_a, mantissa_b, mantissa_c, mantissa_d;
    // Align a, b, c, and d with same exponent block so all mantissas can be added together and have a fused partial product wallace tree
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
    // Obtain partial products from a * b
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
    // Obtain partial products from c * d
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
    // Use wallace tree to reduce the 12 partial products from a*b + c*d into a sum and carry
    wire [23:0] wallace_sum, wallace_carry;
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
    localparam [7:0] FP32_BIAS = 8'd127;
    localparam [4:0] FP16_BIAS = 5'd15;
    wire [7:0] prod_exp;
    assign prod_exp = FP32_BIAS + {3'b000, exponent} - {3'b000, FP16_BIAS};
    wire acc_sign;
    wire [7:0] acc_exp, final_exp;
    wire[23:0] acc_mantissa, acc_mantissa_scaled;
    fp32_unpack acc_unpack(
        .in(rs3),
        .sign(acc_sign),
        .exp(acc_exp),
        .mantissa(acc_mantissa)
    );
    wire [7:0] shift_prod;
    //Align exponents of accumulator and wallace sum and carry so that they can all 3 be added together in CSA
    align_acc aa(
        .acc_exp(acc_exp),
        .prod_exp(prod_exp),
        .acc_mantissa(acc_mantissa),
        .acc_mantissa_scaled(acc_mantissa_scaled),
        .final_exp(final_exp),
        .shift_prod(shift_prod)
    );
    wire [23:0] wallace_sum_scaled, wallace_carry_scaled;
    wire [24:0] mantissa_final;
    assign wallace_sum_scaled = wallace_sum >> shift_prod;
    assign wallace_carry_scaled = wallace_carry >> shift_prod;
    prod_acc blahhhh(
        .wallace_sum_scaled(wallace_sum_scaled),
        .wallace_carry_scaled(wallace_carry_scaled),
        .acc_mantissa_scaled(acc_mantissa_scaled),
        .mantissa_final(mantissa_final)
    );
    wire[31:0] final_result;
    normalize norm(
        .mantissa_in(mantissa_final), 
        .exp_in(final_exp), 
        .sign_in(1'b0),
        .out(final_result)
    );
    always @(posedge clk) begin
        out <= final_result;
    end
endmodule
