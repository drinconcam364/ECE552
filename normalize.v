module normalize( mantissa_in, exp_in, mantissa_out, exp_out(abcd_32_exponent));
    input [23:0] mantissa_in;
    input [4:0] exp_in;
    output reg [7:0] exp_out;
    output reg [23:0] mantissa_out;

    localparam [7:0] FP32_BIAS = 8'd127;
    always @* begin
        if (mant_in[23]) begin
            mant_out = mant_in;
            exp_out  = FP32_BIAS + {3'b000, exp_block};  // 127 + exp_block
        end else begin
            mant_out = mant_in << 1;
            exp_out  = FP32_BIAS + {3'b000, exp_block} - 1;
        end
    end
endmodule
