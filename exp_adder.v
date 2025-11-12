module exp_adder(operandA, operandB, out);
    input [4: 0] operandA, operandB;
    output [4:0] out;
    wire [5:0] carry;
    assign carry[0] = 1'b0;
    genvar i;
    generate
        for (i = 0; i < 5; i = i + 1) begin : RCA
            assign out[i] = operandA[i] ^ operandB[i] ^ carry[i];
            assign carry[i + 1] = (operandA[i] & operandB[i]) | (operandA[i] & carry[i]) | (operandB[i] & carry[i]);
        end
    endgenerate
endmodule
