module unpack32(in, sign, exp, mantissa);
    input [31:0] in;
    output sign;
    output [7:0] exp;
    output [23:0] mantissa;

    assign sign = in[31];
    assign exp = in[30:23];
    wire [22:0] f = in[22:0];

    wire is_zero     = (exp == 8'h00) && (f == 23'd0);
    wire is_subnorm  = (exp == 8'h00) && (f != 23'd0);
    
    assign mantissa = is_zero ? 24'd0 : is_subnorm ? {1'b0, f} : {1'b1, f};
endmodule
