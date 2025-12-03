// Aligns the smaller mantissa by the exponent difference
// and produces Guard (G), Round (R), and Sticky (S).
module align_smaller #(parameter W = 24) (
    input  [W-1:0] in_val,       // incoming mantissa (with hidden bit)
    input  [7:0]   shift_amt,    // exponent difference
    output [W-1:0] aligned_val,  // aligned mantissa
    output         guard,        // first bit shifted out
    output         round,        // second bit shifted out
    output         sticky        // OR of all remaining bits shifted out
);

    reg [W-1:0] shifted;
    reg g_reg, r_reg, s_reg;
    integer i;

    always @(*) begin
        // Defaults
        shifted = in_val;
        g_reg   = 1'b0;
        r_reg   = 1'b0;
        s_reg   = 1'b0;

        // No shift
        if (shift_amt == 0) begin
            shifted = in_val;
        end

        // Shift amount >= width: everything shifts out, sticky = OR(all bits)
        else if (shift_amt >= W[7:0]) begin
            shifted = {W{1'b0}};
            g_reg   = 1'b0;
            r_reg   = 1'b0;
            s_reg   = 1'b0;
            for (i = 0; i < W; i = i + 1)
                s_reg = s_reg | in_val[i];
        end

        // Normal case: 1 <= shift_amt < W
        else begin
            shifted = in_val >> shift_amt;

            // Guard = bit just below new LSB
            g_reg  = in_val[shift_amt-1];

            // Round = next bit below guard (if it exists)
            if (shift_amt > 1)
                r_reg = in_val[shift_amt-2];
            else
                r_reg = 1'b0;

            // Sticky = OR of all bits below round
            s_reg = 1'b0;
            if (shift_amt > 2) begin
                for (i = 0; i < W; i = i + 1) begin
                    if (i < shift_amt-2)
                        s_reg = s_reg | in_val[i];
                end
            end
        end
    end

    assign aligned_val = shifted;
    assign guard       = g_reg;
    assign round       = r_reg;
    assign sticky      = s_reg;

endmodule
