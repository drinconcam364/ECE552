module eight_bit_cla_adder(S, Gout, Pout, A, B, Cin, AandB, AorB);
    input [7:0] A, B;
    input Cin;
    output [7:0] S, AandB, AorB;
    output Gout, Pout;


    wire [7:0] C, G, P;
    wire w1, w2, w3, w4, w5, w6, w7, w8, w9, w10, w11, w12, w13, w14, w15, w16,w17,w18,w19,w20,w21,w22,w23,w24,w25,w26,w27,w28,w29,w30,w31,w32,w33,w34,w35;
    
    // making P0
    or por0(P[0], A[0], B[0]);
    or por1(P[1], A[1], B[1]);
    or por2(P[2], A[2], B[2]);
    or por3(P[3], A[3], B[3]);
    or por4(P[4], A[4], B[4]);
    or por5(P[5], A[5], B[5]);
    or por6(P[6], A[6], B[6]);
    or por7(P[7], A[7], B[7]);
    assign AorB = P;

    // making G0
    and gand0(G[0], A[0], B[0]);
    and gand1(G[1], A[1], B[1]);
    and gand2(G[2], A[2], B[2]);
    and gand3(G[3], A[3], B[3]);
    and gand4(G[4], A[4], B[4]);
    and gand5(G[5], A[5], B[5]);
    and gand6(G[6], A[6], B[6]);
    and gand7(G[7], A[7], B[7]);
    assign AandB = G;

    //C0:
    assign C[0] = Cin;
    
    // C1:
    and and1(w1, P[0], Cin);
    or c1or(C[1], G[0], w1);

    //C2:
    and and2(w2, P[1], G[0]);
    and and3(w3, P[1], P[0], Cin);
    or c2or(C[2], G[1], w2, w3);

    //C3:
    and and4(w4, P[2], G[1]);
    and and5(w5, P[2], P[1], G[0]);
    and and6(w6, P[2], P[1], P[0], Cin);
    or c3or(C[3], G[2], w4, w5, w6);
   
   //C4:
   and and7(w7, P[3], G[2]);
   and and8(w8, P[3], P[2], G[1]);
   and and9(w9, P[3], P[2], P[1], G[0]);
   and and10(w10, P[3], P[2], P[1], P[0], Cin);
   or c4or(C[4], G[3], w7, w8, w9, w10);

   //C5:
   and and11(w11, P[4], G[3]);
   and and12(w12, P[4], P[3], G[2]);
   and and13(w13, P[4], P[3], P[2], G[1]);
   and and14(w14, P[4], P[3], P[2], P[1], G[0]);
   and and15(w15, P[4], P[3], P[2], P[1], P[0], Cin);
   or c5or(C[5], G[4], w11, w12, w13, w14, w15);
   
    
    //C6:
    and and16(w16, P[5], G[4]);
    and and17(w17, P[5], P[4], G[3]);
    and and18(w18, P[5], P[4], P[3], G[2]);
    and and19(w19, P[5], P[4], P[3], P[2], G[1]);
    and and20(w20, P[5], P[4], P[3], P[2], P[1], G[0]);
    and and21(w21, P[5], P[4], P[3], P[2], P[1], P[0], Cin);
    or c6or(C[6], G[5], w16, w17, w18, w19, w20, w21);

    //C7:
    and and22(w22, P[6], G[5]);
    and and23(w23, P[6], P[5], G[4]);
    and and24(w24, P[6], P[5], P[4], G[3]);
    and and25(w25, P[6], P[5], P[4], P[3], G[2]);
    and and26(w26, P[6], P[5], P[4], P[3], P[2], G[1]);
    and and27(w27, P[6], P[5], P[4], P[3], P[2], P[1], G[0]);
    and and28(w28, P[6], P[5], P[4], P[3], P[2], P[1], P[0], Cin);
    or c7or(C[7], G[6], w22, w23, w24, w25, w26, w27, w28);

    //S:
    xor s0xor(S[0], A[0], B[0], C[0]);
    xor s1xor(S[1], A[1], B[1], C[1]);
    xor s2xor(S[2], A[2], B[2], C[2]);
    xor s3xor(S[3], A[3], B[3], C[3]);
    xor s4xor(S[4], A[4], B[4], C[4]);
    xor s5xor(S[5], A[5], B[5], C[5]);
    xor s6xor(S[6], A[6], B[6], C[6]);
    xor s7xor(S[7], A[7], B[7], C[7]);

    // calculate P and G bit outputs
    and poutor(Pout, P[7], P[6], P[5], P[4], P[3], P[2], P[1], P[0]);

    and and29(w29, P[7], G[6]);
    and and30(w30, P[7], P[6], G[5]);
    and and31(w31, P[7], P[6], P[5], G[4]);
    and and32(w32, P[7], P[6], P[5], P[4], G[3]);
    and and33(w33, P[7], P[6], P[5], P[4], P[3], G[2]);
    and and34(w34, P[7], P[6], P[5], P[4], P[3], P[2], G[1]);
    and and35(w35, P[7], P[6], P[5], P[4], P[3], P[2], P[1], G[0]);
    or g0or(Gout, w29, w30, w31, w32, w33, w34, w35, G[7]);


    endmodule