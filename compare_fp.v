module compare_fp(mantissa_a, sign_a, exp_a, mantissa_b, sign_b, exp_b, 
                a_gt_b, exp_diff, exp_large, exp_small, mantissa_large, mantissa_small, 
                sign_large, sign_small);
    input sign_a, sign_b;
    input [7:0] exp_a, exp_b;
    input [23:0] mantissa_a, mantissa_b;
    output a_gt_b;
    output [7:0] exp_diff;
    output [7:0] exp_large, exp_small;
    output [23:0] mantissa_large, mantissa_small;
    output sign_large, sign_small;

assign a_gt_b = (exp_a > exp_b) || (exp_a == exp_b && mantissa_a >= mantissa_b);
    assign exp_diff = a_gt_b ? (exp_a - exp_b) : (exp_b - exp_a);
    assign exp_large = a_gt_b ? exp_a : exp_b;
    assign exp_small = a_gt_b ? exp_b : exp_a;
    assign mantissa_large = a_gt_b ? mantissa_a : mantissa_b;
    assign mantissa_small = a_gt_b ? mantissa_b : mantissa_a;
    assign sign_large = a_gt_b ? sign_a : sign_b;
    assign sign_small = a_gt_b ? sign_b : sign_a;

endmodule