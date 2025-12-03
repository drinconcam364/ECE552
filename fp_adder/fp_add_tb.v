`timescale 1ns/1ps

module fp_add_tb;

  reg         clk;
  reg         rst_n;
  reg         in_valid;
  reg  [31:0] a, b;
  wire        out_valid;
  wire [31:0] result;

  // Instantiate the DUT
  fp_add dut (
    .clk       (clk),
    .rst_n     (rst_n),
    .in_valid  (in_valid),
    .a         (a),
    .b         (b),
    .out_valid (out_valid),
    .result    (result)
  );

  // 10ns period clock
  initial clk = 1'b0;
  always #5 clk = ~clk;

  reg [31:0] last_a, last_b;

  initial begin
    $dumpfile("fp_add.vcd");
    $dumpvars(0, fp_add_tb);

    // init + reset
    rst_n    = 1'b0;
    in_valid = 1'b0;
    a = 32'd0; b = 32'd0;
    repeat (3) @(posedge clk);
    rst_n = 1'b1;

    $display(" time |              a              b  |           result");
    $display("----------------------------------------------------------");

    // -------- Vector 1: 0.5 + 0.25 = 0.75 (0x3F400000) --------
    @(posedge clk);
    a <= 32'h3F000000; b <= 32'h3E800000; in_valid <= 1'b1;
    last_a <= 32'h3F000000; last_b <= 32'h3E800000;
    @(posedge clk);
    in_valid <= 1'b0;

    // wait until out_valid is seen at a clock edge, then print on the next edge
    @(posedge clk); while (!out_valid) @(posedge clk);
    @(posedge clk);
    $display("%4t | 0x%08h 0x%08h | 0x%08h", $time, last_a, last_b, result);

    // -------- Vector 2: 1.5 + 2.25 = 3.75 (0x40700000) --------
    @(posedge clk);
    a <= 32'h3FC00000; b <= 32'h40100000; in_valid <= 1'b1;
    last_a <= 32'h3FC00000; last_b <= 32'h40100000;
    @(posedge clk);
    in_valid <= 1'b0;

    @(posedge clk); while (!out_valid) @(posedge clk);
    @(posedge clk);
    $display("%4t | 0x%08h 0x%08h | 0x%08h", $time, last_a, last_b, result);

    // -------- Vector 3: 5.75 + 0.43 = +6.18 (0x40c5c28f) --------
    @(posedge clk);
    a <= 32'h40b80000; b <= 32'h3edc28f6; in_valid <= 1'b1;
    last_a <= 32'h40b80000; last_b <= 32'h3edc28f6;
    @(posedge clk);
    in_valid <= 1'b0;

    @(posedge clk); while (!out_valid) @(posedge clk);
    @(posedge clk);
    $display("%4t | 0x%08h 0x%08h | 0x%08h", $time, last_a, last_b, result);

    // finish
    repeat (2) @(posedge clk);
    $finish;
  end

endmodule