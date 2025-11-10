module unpack(in, sign, exp, mantissa);
    input [15:0] in;
    output sign;
    output [4:0] exp;
    output [10:0] mantissa;
    assign sign = in[15];
    assign exp = in[14:10];
    assign mantissa = (exp == 5'b0) ? {1'b0, in[9:0]} : {0'b0, in[9:0]};
end module

