module csa_32(a, b, c, sum, carry);
    input [23:0] a, b, c;
    output reg [23:0] sum, carry;
    integer i;
    always @* begin
        for (i = 0; i <24; i = i + 1) begin
            sum[i] = a[i] ^ b[i] ^ c[i];
            carry[i] = (a[i] & b[i]) | (a[i] & c[i]) | (b[i] & c[i]);
        end
    end
endmodule