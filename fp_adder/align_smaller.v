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
    reg guard_bit, round_bit, sticky_bit;

    // NEW: declare a mask and a loop index
    reg [W-1:0] sticky_mask;
    integer i;

    always @(*) begin
        // Defaults
        shifted     = in_val;
        guard_bit   = 1'b0;
        round_bit   = 1'b0;
        sticky_bit  = 1'b0;
        sticky_mask = {W{1'b0}};

        // No shift
        if (shift_amt == 0) begin
            shifted    = in_val;

        // Everything shifted out (kept LSB and G/R are off-bus)
        end else if (shift_amt >= (W + 2)) begin
            shifted    = {W{1'b0}};
            sticky_bit = |in_val;

        // General case: 1 .. W+1
        end else begin
            shifted    = in_val >> shift_amt;

            // Guard = bit just below the kept LSB after shift
            guard_bit  = (shift_amt <= W) ? in_val[shift_amt-1] : 1'b0;

            // Round = next bit below guard
            round_bit  = (shift_amt > 1)  ? in_val[shift_amt-2] : 1'b0;

            // Sticky = OR of all bits below round
            if (shift_amt > 2) begin
                // Build a mask with ones in positions [0 .. shift_amt-3]
                sticky_mask = {W{1'b0}};
                for (i = 0; i < W; i = i + 1) begin
                    if (i < (shift_amt - 2))
                        sticky_mask[i] = 1'b1;
                end
                sticky_bit = |(in_val & sticky_mask);
            end
        end
    end

    assign aligned_val = shifted;
    assign guard  = guard_bit;
    assign round  = round_bit;
    assign sticky = sticky_bit;

endmodule
