module second_level_lookahead(data_operandA, data_operandB, Cin, C32out, S, AandB, AorB);

input Cin;
input [31:0] data_operandA, data_operandB;
wire c8, c16, c24, c32;
wire w1,w2,w3,w4,w5,w6,w7,w8,w9,w10;
wire [3:0] G, P;
output C32out;
output [31:0] S, AorB, AandB;
wire [7:0] S7, S15, S23, S31, AandB7, AandB15, AandB23, AandB31, AorB7, AorB15, AorB23, AorB31;
assign S = {S31, S23, S15, S7};
assign AorB = {AorB31, AorB23, AorB15, AorB7};
assign AandB = {AandB31, AandB23, AandB15, AandB7};
//assign S = 32'b0;

// C8:
eight_bit_cla_adder block0(.S(S7), .Gout(G[0]), .Pout(P[0]), .A(data_operandA[7:0]), .B(data_operandB[7:0]), .Cin(Cin), .AandB(AandB7), .AorB(AorB7));

and and1(w1, P[0], Cin);
or c8or(c8, G[0], w1);


// C16:
eight_bit_cla_adder block1(.S(S15), .Gout(G[1]), .Pout(P[1]), .A(data_operandA[15:8]), .B(data_operandB[15:8]), .Cin(c8), .AandB(AandB15), .AorB(AorB15));
and and2(w2, P[1], G[0]);
and and3(w3, P[1], P[0], c8);
or c16or(c16, G[1], w2, w3);


// C24:
eight_bit_cla_adder block2(.S(S23), .Gout(G[2]), .Pout(P[2]), .A(data_operandA[23:16]), .B(data_operandB[23:16]), .Cin(c16), .AandB(AandB23), .AorB(AorB23));
and and4(w4, P[2], G[1]);
and and5(w5, P[2], P[1], G[0]);
and and6(w6, P[2], P[1], P[0], c16);
or c24or(c24, G[2], w4, w5, w6);

// C32:
eight_bit_cla_adder block3(.S(S31), .Gout(G[3]), .Pout(P[3]), .A(data_operandA[31:24]), .B(data_operandB[31:24]), .Cin(c24), .AandB(AandB31), .AorB(AorB31));
and and7(w7, P[3], G[2]);
and and8(w8, P[3], P[2], G[1]);
and and9(w9, P[3], P[2], P[1], G[0]);
and and10(w10, P[3], P[2], P[1], P[0], c24);
or c32or(c32, G[3], w7, w8, w9, w10);
assign C32out = c32;


endmodule