module fp32_upack(in, sign, exp, mantissa);
    input [31:0] in;
    output sign;
    output [7:0] exp;
    output [10:0] mantissa;
    assign sign = in[31];
    assign exp = in[30:23];
    assign mantissa = (exp == 5'b0) ? {1'b0, in[22:0]} : {0'b0, in[22:0]};
endmodule

