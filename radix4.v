module radix4(multiplicand, multiplier, pp0, pp1, pp2, pp3, pp4, pp5);
    input [10: 0] multiplicand, multiplier;
    output reg signed [23:0] pp0, pp1, pp2, pp3, pp4, pp5;
    wire signed [11:0] A = {1'b0, multiplicand};
    //wire signed [11:0] negative_multiplicand = {1'b1, multiplicand};
    wire signed [11:0] A2 = positive_multiplicand <<< 1; //MIGHT NEED TO CREATE CUSTOM SHIFTING MODULE?
    wire [12:0] ext_multiplier = {1'b0, multiplier, 1'b0};
    wire [2:0] pp0_bits, pp1_bits, pp2_bits, pp3_bits, pp4_bits, pp5_bits;
    wire [11:0] pp0_temp, pp1_temp, pp2_temp, pp3_temp, pp4_temp, pp5_temp;

    assign pp0_bits = ext_multiplier[2:0];
    assign pp1_bits = ext_multiplier[4:2];
    assign pp2_bits = ext_multiplier[6:4];
    assign pp3_bits = ext_multiplier[8:6];
    assign pp4_bits = ext_multiplier[10:8];
    assign pp5_bits = ext_multiplier[12:10];

    function signed[11:0] partial:
        input [2:0] bits;
        reg [2:0] bit_reg;
        reg signed [11:0] part;
    begin
        bit_reg = bits;
        case (bit_reg)
            3'b000,
            3'b111: part = 12'd0;    // 0 * A
            3'b001,
            3'b010: part = A;         // +1 * A
            3'b011: part = A2;        // +2 * A
            3'b100: part = -A2;       // -2 * A
            3'b101,
            3'b110: part = -A;        // -1 * A
            default: part = 12'd0;
        endcase
    end
    endfunction

    always @* begin
        pp0 = {12'b0, partial(pp0_bits)};
        pp1 = {10'b0, partial(pp1_bits), 2'b0};
        pp2 = {8'b0, partial(pp2_bits), 4'b0};
        pp3 = {6'b0, partial(pp3_bits), 6'b0};
        pp4 = {4'b0, partial(pp4_bits), 8'b0};
        pp5 ={2'b0, partial(pp5_bits), 10'b0};
    end
endmodule