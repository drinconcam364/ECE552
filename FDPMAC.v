module FDPMAC(rs1, rs2, rs3, rm, clk, out);
    input [31:0] rs1, rs2, rs3;
    input clk;
    input [2:0] rm;
    output reg [31:0] out;
    wire sign_a, sign_b, sign_c, sign_d;
    wire [7:0] prod_exp;
    wire [10:0] mantissa_a, mantissa_b, mantissa_c, mantissa_d;

    //-----------------------------------------
    // Stage 1: Align Exponents, Align a, b, c, and d with same exponent block so all mantissas can be added together and have a fused partial product wallace tree
    align_exps align(
        .a(rs1[15:0]), 
        .b(rs1[31:16]), 
        .c(rs2[15:0]), 
        .d(rs2[31:16]), 
        .sign_a(sign_a), 
        .sign_b(sign_b), 
        .sign_c(sign_c), 
        .sign_d(sign_d), 
        .prod_exp(prod_exp), 
        .mantissa_a(mantissa_a), 
        .mantissa_b(mantissa_b), 
        .mantissa_c(mantissa_c), 
        .mantissa_d(mantissa_d)
    );

    //----------------------------------------
    // A|R 
    reg AR_sign_a_r, AR_sign_b_r, AR_sign_c_r, AR_sign_d_r;
    reg [2:0] AR_rm;
    reg [10:0] AR_mantissa_a_r, AR_mantissa_b_r, AR_mantissa_c_r, AR_mantissa_d_r;
    reg [31:0] AR_rs3;
    reg [7:0] AR_prod_exp;
    always @(posedge clk) begin
        AR_sign_a_r <= sign_a;
        AR_sign_b_r <= sign_b;
        AR_sign_c_r <= sign_c;
        AR_sign_d_r <= sign_d;
        AR_mantissa_a_r <= mantissa_a;
        AR_mantissa_b_r <= mantissa_b;
        AR_mantissa_c_r <= mantissa_c;
        AR_mantissa_d_r <= mantissa_d;
        AR_rs3 <= rs3;
        AR_rm <= rm;
        AR_prod_exp <= prod_exp;
    end

    //----------------------------------------
    // STAGE 2: Radix 4 Booth Encoding, obtain partial products from a * b and c * d
    wire signed [23:0] pp0, pp1, pp2, pp3, pp4, pp5, pp6, pp7, pp8, pp9, pp10, pp11;
    radix4 ab(
        .multiplicand(AR_mantissa_a_r), 
        .multiplier(AR_mantissa_b_r), 
        .pp0(pp0),
        .pp1(pp1), 
        .pp2(pp2), 
        .pp3(pp3), 
        .pp4(pp4), 
        .pp5(pp5)
    );
    radix4 cd(
        .multiplicand(AR_mantissa_c_r), 
        .multiplier(AR_mantissa_d_r), 
        .pp0(pp6),
        .pp1(pp7), 
        .pp2(pp8), 
        .pp3(pp9), 
        .pp4(pp10), 
        .pp5(pp11)
    );

    //----------------------------------------
    // R|W 
    reg signed [23:0] RW_pp0_r, RW_pp1_r, RW_pp2_r, RW_pp3_r, RW_pp4_r, RW_pp5_r, RW_pp6_r, RW_pp7_r, RW_pp8_r, RW_pp9_r, RW_pp10_r, RW_pp11_r;
    reg [31:0] RW_rs3;
    reg [2:0] RW_rm;
    reg RW_sign_a_r, RW_sign_b_r, RW_sign_c_r, RW_sign_d_r;
    reg [7:0] RW_prod_exp;
    always @(posedge clk) begin
        RW_pp0_r <= pp0;
        RW_pp1_r <= pp1;
        RW_pp2_r <= pp2;
        RW_pp3_r <= pp3;
        RW_pp4_r <= pp4;
        RW_pp5_r <= pp5;
        RW_pp6_r <= pp6;
        RW_pp7_r <= pp7;
        RW_pp8_r <= pp8;
        RW_pp9_r <= pp9;
        RW_pp10_r <= pp10;
        RW_pp11_r <= pp11;
        RW_rs3 <= AR_rs3;
        RW_rm <= AR_rm;
        RW_prod_exp <= AR_prod_exp;
    end
    //----------------------------------------

    //----------------------------------------
    // Stage 3: Wallace Tree, use wallace tree to reduce the 12 partial products from a*b + c*d into a sum and carry
    wire signed [23:0] wallace_sum, wallace_carry;
    wallace_12x24 wallace(
        .pp0(RW_pp0_r), 
        .pp1(RW_pp1_r), 
        .pp2(RW_pp2_r), 
        .pp3(RW_pp3_r), 
        .pp4(RW_pp4_r), 
        .pp5(RW_pp5_r), 
        .pp6(RW_pp6_r), 
        .pp7(RW_pp7_r), 
        .pp8(RW_pp8_r), 
        .pp9(RW_pp9_r), 
        .pp10(RW_pp10_r), 
        .pp11(RW_pp11_r),
        .sum(wallace_sum),  //24 bits
        .carry(wallace_carry) // 24 bits
    );

    wire signed [26:0] prod_raw;
    wire signed [25:0] wallace_sum_ext   = { {2{wallace_sum[23]}},   wallace_sum   };
    wire signed [25:0] wallace_carry_ext = { {2{wallace_carry[23]}}, wallace_carry };
    assign prod_raw = wallace_sum_ext + (wallace_carry_ext <<< 1);
    // 2) Extract sign and magnitude of the product
    wire        prod_sign = prod_raw[26];
    wire [26:0] prod_mag  = prod_sign ? -prod_raw : prod_raw;
    // 3) Widen magnitude to 29 bits for the normalize unit (leave guard bits at top)
    wire [28:0] mantissa_29 = {2'b00, prod_mag};  // [28:0] = [28:27]=0, [26:0]=prod_mag
    // 4) Normalize + round + pack into IEEE-754 single precision
    wire [31:0] fp_result;

    normalize u_norm (
        .mantissa_in(mantissa_29),   // 29-bit raw mantissa
        .exp_in     (prod_exp),      // common exponent from align_exps
        .sign_in    (prod_sign),
        .out        (fp_result)
    );
    wire [31:0] final_result;
    wire out_valid;
    fp_add addd(
        .clk(clk),
        .rst_n(1'b0),
        .in_valid(1'b1),
        .a(fp_result),
        .b(RW_rs3),
        .out_valid(out_valid),
        .result(final_result)
        );
    reg out_valid_r;
    reg signed [31:0] wallace_total;
    always @(posedge clk) begin
        out <= final_result;
        out_valid_r <= out_valid;
        wallace_total <= fp_result;
    end
endmodule



//iverilog -o fdpmac_tb.vvp FDPMAC_tb.v FDPMAC.v align_acc.v align_exps.v csa_32.v fp16_unpack.v fp32_unpack.v normalize.v prod_acc.v radix4.v wallace_12x24.v
//iverilog -o fdpmac_p_tb.vvp fdpmac_p_tb.v FDPMAC.v fp_add.v align_smaller.v second_level_lookahead.v round_pack.v fp_normalize27.v align_acc.v align_exps.v csa_32.v fp16_unpack.v fp32_unpack.v normalize.v prod_acc.v radix4.v wallace_12x24.v eight_bit_cla_adder
//iverilog -D FDPMAC_DEBUG -o fdpmac_p_tb.vvp fdpmac_p_tb.v FDPMAC.v align_acc.v align_exps.v csa_32.v fp16_unpack.v fp32_unpack.v normalize.v prod_acc.v radix4.v wallace_12x24.v
//iverilog -D FDPMAC_DEBUG -o fdpmac_p_tb.vvp fdpmac_p_tb.v FDPMAC.v fp_add.v align_smaller.v second_level_lookahead.v round_pack.v fp_normalize27.v align_acc.v align_exps.v csa_32.v fp16_unpack.v fp32_unpack.v normalize.v prod_acc.v radix4.v wallace_12x24.v eight_bit_cla_adder.v
