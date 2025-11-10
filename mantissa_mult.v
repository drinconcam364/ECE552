module mantissa_mult(multiplicand, multiplier, out);
    input [10:0] multiplicand, multiplier;
    output [21:0] out;
    radix4 ppgen(.multiplicand(multiplicand), .multiplier(multiplier))
end module