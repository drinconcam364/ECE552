module align_exps(a, b, c, d, sign_a, sign_b, sign_c, sign_d, prod_exp, mantissa_a, mantissa_b, mantissa_c, mantissa_d);
    input [15:0] a, b, c, d;
    output sign_a, sign_b, sign_c, sign_d;
    output [7:0] prod_exp;
    //wire [10:0] mantissa_a, mantissa_b, mantissa_c, mantissa_d;
    output [10:0] mantissa_a, mantissa_b, mantissa_c, mantissa_d;
    wire [4:0] exp_a, exp_b, exp_c, exp_d;

    // Unpack fp16s to extract sign, exponent, and mantissa
    fp16_unpack unpack_a(.in(a), .sign(sign_a), .exp(exp_a), .mantissa(mantissa_a));
    fp16_unpack unpack_b(.in(b), .sign(sign_b), .exp(exp_b), .mantissa(mantissa_b));
    fp16_unpack unpack_c(.in(c), .sign(sign_c), .exp(exp_c), .mantissa(mantissa_c));
    fp16_unpack unpack_d(.in(d), .sign(sign_d), .exp(exp_d), .mantissa(mantissa_d));

    localparam [7:0] PROD_BIAS_ADJUST = 8'd97;   //FP32_BIAS - (FP16_BIAS << 1); // = 97
    wire [7:0] exp_a_exp = {3'b000, exp_a};
    wire [7:0] exp_b_exp = {3'b000, exp_b};
    wire [7:0] exp_c_exp = {3'b000, exp_c};
    wire [7:0] exp_d_exp = {3'b000, exp_d};
    wire [8:0] exp32_ab_pre = exp_a_exp + exp_b_exp + PROD_BIAS_ADJUST;
    wire [8:0] exp32_cd_pre = exp_c_exp + exp_d_exp + PROD_BIAS_ADJUST;
    wire [8:0] exp32_prod_pre = (exp32_ab_pre > exp32_cd_pre) ? exp32_ab_pre : exp32_cd_pre;
    assign prod_exp = exp32_prod_pre[7:0];
endmodule
    // // find largest exponent out of a, b, c, and d
    // wire [4:0] exp_max_ab = (exp_a > exp_b) ? exp_a : exp_b;
    // wire [4:0] exp_max_cd = (exp_c > exp_d) ? exp_c : exp_d;
    // wire [4:0] exp_max    = (exp_max_ab > exp_max_cd) ? exp_max_ab : exp_max_cd;
    // assign exp = exp_max;

    // //Shift amount for each mantissa
    // wire [4:0] sh_a = exp_max - exp_a;
    // wire [4:0] sh_b = exp_max - exp_b;
    // wire [4:0] sh_c = exp_max - exp_c;
    // wire [4:0] sh_d = exp_max - exp_d;

    // //Shift mantissas down to share same exponenet domain so that their partial products can be combined later in wallace tree
    // function [10:0] shift_down;
    //     input [10:0] mantissa_in;
    //     input [4:0] shift_amount;
    //     begin
    //         shift_down = mantissa_in >> shift_amount;
    //     end
    // endfunction

    // assign mantissa_a_scaled = shift_down(mantissa_a, sh_a);
    // assign mantissa_b_scaled = shift_down(mantissa_b, sh_b);
    // assign mantissa_c_scaled = shift_down(mantissa_c, sh_c);
    // assign mantissa_d_scaled = shift_down(mantissa_d, sh_d);
    // assign mantissa_a_scaled = mantissa_a;
    // assign mantissa_b_scaled = mantissa_b;
    // assign mantissa_c_scaled = mantissa_c;
    // assign mantissa_d_scaled = mantissa_d;
