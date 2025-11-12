module prod_acc(wallace_sum_scaled, wallace_carry_scaled, acc_mantissa_scaled, mantissa_final);
    input [23:0] wallace_sum_scaled, wallace_carry_scaled, acc_mantissa_scaled;
    output [24:0] mantissa_final;
    wire [23:0] csa_sum, csa_carry;
    csa_32 blahhh(
        .a(wallace_sum_scaled),
        .b({wallace_carry_scaled[22:0], 1'b0}),
        .c(acc_mantissa_scaled),
        .sum(csa_sum),
        .carry(csa_carry)
    );
    assign mantissa_final = {1'b0, csa_sum} + {csa_carry, 1'b0};
endmodule
