`include "HardFloat_consts.vi"
`include "HardFloat_specialize.vi"

module Berk_MAC_wrapper (
    input              clk,
    input              rst_n,
    input  [32:0]      a,
    input  [32:0]      b,
    input  [32:0]      c,
    input  [1:0]       op,
    input  [2:0]       roundingMode,
    input  [(`floatControlWidth-1):0] control,
    output reg [32:0]  out,
    output reg [4:0]   exceptionFlags
);
    // input regs
    reg [32:0] a_q, b_q, c_q;
    reg [1:0]  op_q;
    reg [2:0]  rm_q;
    reg [(`floatControlWidth-1):0] ctrl_q;

    wire [32:0] out_c;
    wire [4:0]  exc_c;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            a_q   <= 33'd0;
            b_q   <= 33'd0;
            c_q   <= 33'd0;
            op_q  <= 2'd0;
            rm_q  <= 3'd0;
            ctrl_q<= {`floatControlWidth{1'b0}};
        end else begin
            a_q   <= a;
            b_q   <= b;
            c_q   <= c;
            op_q  <= op;
            rm_q  <= roundingMode;
            ctrl_q<= control;
        end
    end

    mulAddRecFN #(
        .expWidth(8),
        .sigWidth(24)
    ) u_mac (
        .control      (ctrl_q),
        .op           (op_q),
        .a            (a_q),
        .b            (b_q),
        .c            (c_q),
        .roundingMode (rm_q),
        .out          (out_c),
        .exceptionFlags(exc_c)
    );

    // output regs
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            out            <= 33'd0;
            exceptionFlags <= 5'd0;
        end else begin
            out            <= out_c;
            exceptionFlags <= exc_c;
        end
    end
endmodule
