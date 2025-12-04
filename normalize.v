// module normalize(mantissa_in, exp_in, sign_in, out);
//     input [24:0] mantissa_in;
//     input [7:0] exp_in;
//     input sign_in;
//     output [31:0] out;
//     wire [7:0]  normalized_exp;
//     wire [23:0] normalized_mantissa;
//     assign normalized_exp  = mantissa_in[24] ? exp_in + 1'b1: exp_in;
//     assign normalized_mantissa = mantissa_in[24] ? mantissa_in[24:1]: mantissa_in[23:0];
//         // // If mant_total overflowed into bit 24, normalize:
//         // // - shift mantissa right by 1
//         // // - increment exponent
//         // if (mantissa_in[24]) begin
//         //     normalized_mantissa = mantissa_in[24:1]; // keep top 24 bits after shift
//         //     normalized_exp  = exp_in + 1'b1;
//         // end
//     wire [22:0] frac_out = normalized_mantissa[22:0];
//     assign out = {sign_in, normalized_exp, frac_out};
// endmodule

module normalize (
    input  [28:0] mantissa_in,
    input  [7:0]  exp_in,
    input         sign_in,
    output [31:0] out
);

    reg [28:0] mant;
    reg [7:0] exp;

    always @(*) begin
        mant = mantissa_in;
        exp = exp_in;

        // Right-normalize overflow
        if (mant[28]) begin
            mant = mant >> 1;
            exp = exp + 1;
        end

        // Left-normalize underflow
        else begin
            while (!mant[27] && mant != 0) begin
                mant = mant << 1;
                exp = exp - 1;
            end
        end
    end

    // Slice EXACTLY these bits:
    assign out = {sign_in, exp, mant[26:4]};

endmodule





