// module wallace_12x24(pp0,pp1, pp2, pp3, pp4, pp5, pp6, pp7,pp8,pp9,pp10,pp11, sum, carry);
//     input signed [23:0] pp0, pp1, pp2, pp3, pp4, pp5, pp6, pp7, pp8, pp9, pp10, pp11;
//     output signed [23:0] sum, carry;
//     wire signed [24:0] s1, s2, s3, s4, c1, c2, c3, c4;
//     wire signed [24:0] p0 = pp0, p1 = pp1, p2 = pp2, p3 = pp3, p4 = pp4, p5 = pp5, p6 = pp6, p7 = pp7, p8 = pp8, p9 = pp9, p10 = pp10, p11 = pp11; 
//     //------Stage 1------- 12 -> 8 rows
//     csa_32 one(
//         .a(p0), 
//         .b(p1), 
//         .c(p2), 
//         .sum(s1), 
//         .carry(c1)
//     );
//     csa_32 two(
//         .a(p3), 
//         .b(p4), 
//         .c(p5), 
//         .sum(s2), 
//         .carry(c2)
//     );
//     csa_32 three(
//         .a(p6), 
//         .b(p7), 
//         .c(p8), 
//         .sum(s3), 
//         .carry(c3)
//     );
//     csa_32 four(.a(p9), .b(p10), .c(p11), .sum(s4), .carry(c4));
//     // need to left logically shift all carries by 1
//     //----Stage 2 ----- 8 -> 6 rows
//     wire [24:0] s2_1, s2_2, c2_1, c2_2;
//     csa_32 five(.a(s1), .b({c1[23:0], 1'b0}), .c(s2), .sum(s2_1), .carry(c2_1));
//     csa_32 six(.a(c2<<<1), .b(s3), .c(c3<<<1), .sum(s2_2), .carry(c2_2));
//     // ---- Stage 3 ----- 6 -> 4 rows
//     wire [24:0] s3_1, s3_2, c3_1, c3_2;
//     csa_32 seven(.a(s2_1), .b(s2_2), .c({c4[23:0], 1'b0}), .sum(s3_1), .carry(c3_1));
//     csa_32 eight(.a(s4), .b(c2_1 <<<1), .c(c2_2 <<< 1), .sum(s3_2), .carry(c3_2));
//     // ----- Stage 4 ----- 4 rows -> 3 rows
//     wire [24:0] s4_1, c4_1;
//     csa_32 nine(.a(s3_1), .b(s3_2), .c(c3_1 <<< 1), .sum(s4_1), .carry(c4_1));
//     // ---- Stage 5 ---- 3 rows -> 2 rows
//     wire [24:0] s5_1, c5_1;
//     csa_32 ten(.a(s4_1), .b(c4_1 <<< 1), .c(c3_2 <<< 1), .sum(s5_1), .carry(c5_1));
//     assign sum = s5_1[23:0];
//     assign carry = c5_1[23:0];
// endmodule

module wallace_12x24(pp0,pp1, pp2, pp3, pp4, pp5, pp6, pp7,pp8,pp9,pp10,pp11, sum, carry);
    input signed [23:0] pp0, pp1, pp2, pp3, pp4, pp5, pp6, pp7, pp8, pp9, pp10, pp11;
    output signed [23:0] sum, carry;
    wire signed [23:0] s1, s2, s3, s4, c1, c2, c3, c4;
    //------Stage 1------- 12 -> 8 rows
    csa_32 one(
        .a(pp0), 
        .b(pp1), 
        .c(pp2), 
        .sum(s1), 
        .carry(c1)
    );
    csa_32 two(
        .a(pp3), 
        .b(pp4), 
        .c(pp5), 
        .sum(s2), 
        .carry(c2)
    );
    csa_32 three(
        .a(pp6), 
        .b(pp7), 
        .c(pp8), 
        .sum(s3), 
        .carry(c3)
    );
    csa_32 four(.a(pp9), .b(pp10), .c(pp11), .sum(s4), .carry(c4));
    // need to left logically shift all carries by 1
    //----Stage 2 ----- 8 -> 6 rows
    wire signed [23:0] s2_1, s2_2, c2_1, c2_2;
    csa_32 five(.a(s1), .b(c1 <<< 1), .c(s2), .sum(s2_1), .carry(c2_1));
    csa_32 six(.a(c2 <<< 1), .b(s3), .c(c3 <<< 1), .sum(s2_2), .carry(c2_2));
    // ---- Stage 3 ----- 6 -> 4 rows
    wire signed [23:0] s3_1, s3_2, c3_1, c3_2;
    csa_32 seven(.a(s2_1), .b(s2_2), .c(c4 <<< 1), .sum(s3_1), .carry(c3_1));
    csa_32 eight(.a(s4), .b(c2_1 <<< 1), .c(c2_2 <<< 1), .sum(s3_2), .carry(c3_2));
    // ----- Stage 4 ----- 4 rows -> 3 rows
    wire signed [23:0] s4_1, c4_1;
    csa_32 nine(.a(s3_1), .b(s3_2), .c(c3_1 <<< 1), .sum(s4_1), .carry(c4_1));
    // ---- Stage 5 ---- 3 rows -> 2 rows
    wire signed [23:0] s5_1, c5_1;
    csa_32 ten(.a(s4_1), .b(c4_1 <<< 1), .c(c3_2 <<< 1), .sum(s5_1), .carry(c5_1));
    assign sum = s5_1;
    assign carry = c5_1;
endmodule
