// module radix4(multiplicand, multiplier, pp0, pp1, pp2, pp3, pp4, pp5);
//     input [10: 0] multiplicand, multiplier;
//     output signed [23:0] pp0, pp1, pp2, pp3, pp4, pp5;
//     wire signed [11:0] A = $signed({1'b0, multiplicand});
//     //wire signed [11:0] A = {1'b0, multiplicand};
//     wire signed [11:0] A2 = A <<< 1; //MIGHT NEED TO CREATE CUSTOM SHIFTING MODULE?
//     wire [12:0] ext_multiplier = {1'b0, multiplier, 1'b0};
//     wire [2:0] pp0_bits, pp1_bits, pp2_bits, pp3_bits, pp4_bits, pp5_bits;
//     wire signed [12:0] p0_sign, p1_sign, p2_sign, p3_sign, p4_sign, p5_sign;

//     assign pp0_bits = ext_multiplier[2:0];
//     assign pp1_bits = ext_multiplier[4:2];
//     assign pp2_bits = ext_multiplier[6:4];
//     assign pp3_bits = ext_multiplier[8:6];
//     assign pp4_bits = ext_multiplier[10:8];
//     assign pp5_bits = ext_multiplier[12:10];

//     function signed[12:0] partial;
//         input [2:0] bits;
//         begin
//             case (bits)
//                 3'b000,
//                 3'b111: partial = 13'd0;    // 0 * A
//                 3'b001,
//                 3'b010: partial = A;         // +1 * A
//                 3'b011: partial = A2;        // +2 * A
//                 3'b100: partial = -A2;       // -2 * A
//                 3'b101,
//                 3'b110: partial = -A;        // -1 * A
//                 default: partial = 13'd0;
//             endcase
//         end
//     endfunction

//     assign p0_sign = partial(pp0_bits);
//     assign p1_sign = partial(pp1_bits);
//     assign p2_sign = partial(pp2_bits);
//     assign p3_sign = partial(pp3_bits);
//     assign p4_sign = partial(pp4_bits);
//     assign p5_sign = partial(pp5_bits);

//     assign pp0 = {{12{p0_sign[11]}}, p0_sign};            // << 0
//     assign pp1 = ({{12{p1_sign[11]}}, p1_sign}) <<< 2;    // << 2
//     assign pp2 = ({{12{p2_sign[11]}}, p2_sign}) <<< 4;    // << 4
//     assign pp3 = ({{12{p3_sign[11]}}, p3_sign}) <<< 6;    // << 6
//     assign pp4 = ({{12{p4_sign[11]}}, p4_sign}) <<< 8;    // << 8
//     assign pp5 = ({{12{p5_sign[11]}}, p5_sign}) <<< 10;   // << 10

// endmodule

// module radix4(multiplicand, multiplier, pp0, pp1, pp2, pp3, pp4, pp5);
//     input [10: 0] multiplicand, multiplier;
//     output reg signed [23:0] pp0, pp1, pp2, pp3, pp4, pp5;
//     wire signed [11:0] A = {1'b0, multiplicand};
//     //wire signed [11:0] negative_multiplicand = {1'b1, multiplicand};
//     wire signed [11:0] A2 = positive_multiplicand <<< 1; //MIGHT NEED TO CREATE CUSTOM SHIFTING MODULE?
//     wire [12:0] ext_multiplier = {1'b0, multiplier, 1'b0};
//     wire [2:0] pp0_bits, pp1_bits, pp2_bits, pp3_bits, pp4_bits, pp5_bits;
//     wire [11:0] pp0_temp, pp1_temp, pp2_temp, pp3_temp, pp4_temp, pp5_temp;

//     assign pp0_bits = ext_multiplier[2:0];
//     assign pp1_bits = ext_multiplier[4:2];
//     assign pp2_bits = ext_multiplier[6:4];
//     assign pp3_bits = ext_multiplier[8:6];
//     assign pp4_bits = ext_multiplier[10:8];
//     assign pp5_bits = ext_multiplier[12:10];

//     function signed[11:0] partial;
//         input [2:0] bits;
//         reg [2:0] bit_reg;
//         reg signed [11:0] part;
//         begin
//             bit_reg = bits;
//             case (bit_reg)
//                 3'b000,
//                 3'b111: part = 12'd0;    // 0 * A
//                 3'b001,
//                 3'b010: part = A;         // +1 * A
//                 3'b011: part = A2;        // +2 * A
//                 3'b100: part = -A2;       // -2 * A
//                 3'b101,
//                 3'b110: part = -A;        // -1 * A
//                 default: part = 12'd0;
//             endcase
//         end
//     endfunction

//     always @* begin
//         pp0 = {12'b0, partial(pp0_bits)};
//         pp1 = {10'b0, partial(pp1_bits), 2'b0};
//         pp2 = {8'b0, partial(pp2_bits), 4'b0};
//         pp3 = {6'b0, partial(pp3_bits), 6'b0};
//         pp4 = {4'b0, partial(pp4_bits), 8'b0};
//         pp5 ={2'b0, partial(pp5_bits), 10'b0};
//     end
// endmodule

module radix4 (
    input  [10:0] multiplicand,
    input  [10:0] multiplier,
    output signed [23:0] pp0,
    output signed [23:0] pp1,
    output signed [23:0] pp2,
    output signed [23:0] pp3,
    output signed [23:0] pp4,
    output signed [23:0] pp5
);

    // -----------------------------
    // Prepare multiplicand
    // -----------------------------
    wire signed [11:0] A  = {1'b0, multiplicand};   // +A
    wire signed [11:0] A2 = A <<< 1;                 // +2A

    // -----------------------------
    // Radix-4 Booth extension
    // CORRECT form for unsigned n:
    // {0, multiplier, 0}
    // -----------------------------
    wire [12:0] ext = {1'b0, multiplier, 1'b0};

    wire [2:0] b0 = ext[2:0];
    wire [2:0] b1 = ext[4:2];
    wire [2:0] b2 = ext[6:4];
    wire [2:0] b3 = ext[8:6];
    wire [2:0] b4 = ext[10:8];
    wire [2:0] b5 = ext[12:10];

    // -----------------------------
    // Booth decode function
    // -----------------------------
    function signed [11:0] booth_decode;
        input [2:0] bits;
        begin
            case(bits)
                3'b000,
                3'b111: booth_decode = 12'sd0;   // 0*A
                3'b001,
                3'b010: booth_decode =  A;       // +A
                3'b011: booth_decode =  A2;      // +2A
                3'b100: booth_decode = -A2;      // −2A
                3'b101,
                3'b110: booth_decode = -A;       // −A
                default: booth_decode = 12'sd0;
            endcase
        end
    endfunction

    // -----------------------------
    // Generate signed partials
    // -----------------------------
    wire signed [11:0] p0 = booth_decode(b0);
    wire signed [11:0] p1 = booth_decode(b1);
    wire signed [11:0] p2 = booth_decode(b2);
    wire signed [11:0] p3 = booth_decode(b3);
    wire signed [11:0] p4 = booth_decode(b4);
    wire signed [11:0] p5 = booth_decode(b5);

    // -----------------------------
    // Sign-extend and shift partials
    // -----------------------------
    assign pp0 = {{12{p0[11]}},p0};
    assign pp1 = {{10{p1[11]}},p1,2'b00};   // <<2
    assign pp2 = {{8 {p2[11]}},p2,4'b0000}; // <<4
    assign pp3 = {{6 {p3[11]}},p3,6'b0};    // <<6
    assign pp4 = {{4 {p4[11]}},p4,8'b0};    // <<8
    assign pp5 = {{2 {p5[11]}},p5,10'b0};   // <<10

endmodule

