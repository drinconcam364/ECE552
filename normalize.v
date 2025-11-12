module normalize(mantissa_in, exp_in, sign_in, out);
    input [24:0] mantissa_in;
    input [7:0] exp_in;
    input sign_in;
    output [31:0] out;
    reg [7:0]  normalized_exp;
    reg [23:0] normalized_mantissa;
    always @* begin
        normalized_exp  = exp_in;
        normalized_mantissa = mantissa_in[23:0];

        // If mant_total overflowed into bit 24, normalize:
        // - shift mantissa right by 1
        // - increment exponent
        if (mantissa_in[24]) begin
            normalized_mantissa = mantissa_in[24:1]; // keep top 24 bits after shift
            normalized_exp  = exp_in + 1'b1;
        end
    end
    wire [22:0] frac_out = normalized_mantissa[22:0];
    assign out = {sign_in, normalized_exp, frac_out};
endmodule
