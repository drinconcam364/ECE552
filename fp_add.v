module fp_add(
    input [31:0] a,
    input [31:0] b,
    input clk,
    output [31:0] result
);
    // Unpack inputs
    wire sign_a, sign_b;
    wire [7:0] exp_a, exp_b;
    wire [23:0] mantissa_a, mantissa_b;

    unpack32 unpack_a(.in(a), .sign(sign_a), .exp(exp_a), .mantissa(mantissa_a));
    unpack32 unpack_b(.in(b), .sign(sign_b), .exp(exp_b), .mantissa(mantissa_b));

    wire a_gt_b;
    wire [7:0] exp_diff;
    wire [7:0] exp_large, exp_small;
    wire [23:0] mantissa_large, mantissa_small;
    wire sign_large, sign_small;

    compare_fp comp_fp(
        .sign_a(sign_a),
        .exp_a(exp_a),
        .mantissa_a(mantissa_a),
        .sign_b(sign_b),
        .exp_b(exp_b),
        .mantissa_b(mantissa_b),
        .a_gt_b(a_gt_b)
    );

    wire guard, round, sticky;
    wire [23:0] mantissa_small_aligned;


    align_smaller align_sm(
        .in_val(mantissa_small),
        .shift_amt(exp_diff),
        .aligned_val(mantissa_small_aligned)
        .guard(guard),
        .round(round),
        .sticky(sticky)
    );

    wire add_sub;
    assign add_sub = sign_large ^ sign_small; // 0 for add, 1 for subtract
    wire [26:0] X_pre = {1'b0, mantissa_large,   2'b00};
    wire [26:0] Y_pre = {1'b0, mantissa_small_aligned, 2'b00};
    wire [31:0] A32 = {5'b0, X_pre};
    wire [31:0] B32_in = {5'b0, Y_pre};
    wire [31:0] B32_eff = add_sub ? ~B32_in : B32_in;
    wire Cin = add_sub;

    wire c_out;
    wire [31:0] S32, dbg_and, dbg_or;

    second_level_lookahead u_cla32 (
  .data_operandA (A32),
  .data_operandB (B32_eff),
  .Cin (Cin),
  .C32out (c_out),
  .S (S32),
  .AandB (dbg_and),
  .AorB (dbg_or)
  );

    wire [26:0] sum27 = S32[26:0];
    wire carry = c_out;

    wire sticky_accum = sticky_small;
    


endmodule