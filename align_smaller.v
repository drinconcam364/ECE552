// Aligns the smaller mantissa by the exponent difference
// and produces Guard, Round, and Sticky bits
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
    integer i;

    always @(*) begin
        // Default values
        shifted    = in_val;
        guard_bit  = 1'b0;
        round_bit  = 1'b0;
        sticky_bit = 1'b0;

        // No shift case
        if (shift_amt == 0) begin
            shifted    = in_val;
            guard_bit  = 1'b0;
            round_bit  = 1'b0;
            sticky_bit = 1'b0;

        // If shift exceeds mantissa width → everything shifts out
        end else if (shift_amt >= (W + 3)) begin
            shifted    = {W{1'b0}};
            guard_bit  = 1'b0;
            round_bit  = 1'b0;
            sticky_bit = |in_val;  // if anything was 1, sticky = 1

        end else begin
            // Perform the right shift
            shifted = in_val >> shift_amt;

            // Extract G, R, and S bits
            // Guard = bit just below LSB after shift
            guard_bit  = (shift_amt <= W)   ? in_val[shift_amt-1] : 1'b0;
            round_bit  = (shift_amt+1 <= W) ? in_val[shift_amt]   : 1'b0;

            // Sticky = OR of all bits below round bit
            sticky_bit = (shift_amt > 1) ? |in_val[shift_amt-2:0] : 1'b0;
        end
    end

    assign aligned_val = shifted;
    assign guard  = guard_bit;
    assign round  = round_bit;
    assign sticky = sticky_bit;

endmodule
