`timescale 1ns / 1ps

module rp_tb;

  reg  [23:0] mant24_in;  // {hidden1, frac[22:0]}
  reg         G, R, S;
  reg  [8:0]  E_in;       // biased exponent
  reg         sign_in;
  wire [31:0] result;

  // Instantiate DUT
  round_pack dut (
    .mant24_in(mant24_in),
    .G(G), .R(R), .S(S),
    .E_in(E_in),
    .sign_in(sign_in),
    .result(result)
  );

  initial begin
    $display(" time | mant24_in   E  G R S sign | result");
    $display("------------------------------------------------");

    // Case 1: No rounding (G=R=S=0) -> unchanged
    mant24_in = 24'h800000;  // 1.000000...
    E_in      = 9'd127;      // exp = 127 (value ~1.0)
    {G,R,S}   = 3'b000;
    sign_in   = 1'b0;
    #1 $display("%4t | 0x%06h %3d  %b %b %b   %b   | 0x%08h",
                $time, mant24_in, E_in, G, R, S, sign_in, result);

    // Case 2: Round up (G=1, R=1) -> increment mantissa
    {G,R,S}   = 3'b110;      // ensures inc
    #1 $display("%4t | 0x%06h %3d  %b %b %b   %b   | 0x%08h",
                $time, mant24_in, E_in, G, R, S, sign_in, result);

    // Case 3: Tie-to-even, LSB=0 (G=1,R=0,S=0) -> no increment
    mant24_in = 24'h800000;  // LSB=0
    {G,R,S}   = 3'b100;
    #1 $display("%4t | 0x%06h %3d  %b %b %b   %b   | 0x%08h",
                $time, mant24_in, E_in, G, R, S, sign_in, result);

    // Case 4: Tie-to-even, LSB=1 (G=1,R=0,S=0) -> increment (to even)
    mant24_in = 24'h800001;  // LSB=1
    {G,R,S}   = 3'b100;
    #1 $display("%4t | 0x%06h %3d  %b %b %b   %b   | 0x%08h",
                $time, mant24_in, E_in, G, R, S, sign_in, result);
    $finish;
    end

endmodule
