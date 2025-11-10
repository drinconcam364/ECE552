module mult(sign_a, sign_b,exp_a,exp_b, mantissa_a, mantissa_b);
    input sign_a, sign_b;
    input [4:0] exp_a, exp_b;
    input [10:0] mantissa_a, mantissa_b;
    output sign_out;
    output [9:0] exp_out;
    output [21:0] mantissa_out;
    assign sign_out = sign_a ^ sign_b;
    wire [5:0] exp_sum;
    exp_adder addd(.operandA(exp_a), .operandB(exp_b), .out(exp_sum));
    mantissa_mult mm(.multiplicand(mantissa_a), .multiplier(mantissa_b), .out(mant_product));
    assign mantissa_out = mant_product;
    

end module