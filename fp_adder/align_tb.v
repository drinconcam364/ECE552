`timescale 1ns / 1ps

module align_tb;

  // Match your module parameter
  localparam W = 24;

  // DUT I/O
  reg  [W-1:0] in_val;
  reg  [7:0]   shift_amt;
  wire [W-1:0] aligned_val;
  wire         guard, round, sticky;

  // Instantiate DUT
  align_smaller #(.W(W)) dut (
    .in_val(in_val),
    .shift_amt(shift_amt),
    .aligned_val(aligned_val),
    .guard(guard),
    .round(round),
    .sticky(sticky)
  );

  initial begin
    $display("time  in_val           sh  | aligned_val      G R S");
    $display("------------------------------------------------------");

    // Case 1: no shift
    in_val    = 24'h800000;  // 1.000... (MSB set)
    shift_amt = 8'd0;
    #1 $display("%4t  0x%06h   %2d | 0x%06h       %b %b %b",
                $time, in_val, shift_amt, aligned_val, guard, round, sticky);

    // Case 2: shift by 1
    shift_amt = 8'd1;
    #1 $display("%4t  0x%06h   %2d | 0x%06h       %b %b %b",
                $time, in_val, shift_amt, aligned_val, guard, round, sticky);

    // Case 3: shift by 2
    shift_amt = 8'd2;
    #1 $display("%4t  0x%06h   %2d | 0x%06h       %b %b %b",
                $time, in_val, shift_amt, aligned_val, guard, round, sticky);

    // Case 4: a mixed pattern, moderate shift
    in_val    = 24'hA5A5A5;
    shift_amt = 8'd5;
    #1 $display("%4t  0x%06h   %2d | 0x%06h       %b %b %b",
                $time, in_val, shift_amt, aligned_val, guard, round, sticky);

    // Case 5: boundary shift (W)
    shift_amt = W[7:0];
    #1 $display("%4t  0x%06h   %2d | 0x%06h       %b %b %b",
                $time, in_val, shift_amt, aligned_val, guard, round, sticky);

    $finish;
  end

endmodule
