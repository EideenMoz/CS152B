module invert16(
    input wire [15:0] a,
    output wire [15:0] y,
    output overflow
);

    //flip bits
    wire [15:0] flipped;
    genvar i;
    generate
        for(i = 0; i < 16; i = i + 1) begin : invert
            not (flipped[i], a[i]);
        end
    endgenerate

    //add 1 to get two's complement
    addition16 add_one (
        .sum(y),
        .overflow(overflow),
        .a(flipped),
        .b(16'h0001),
        .cin(0)
    );
    
    // //overflow is really weird in this case: only TMIN.
    // wire [15:0] comparison;
    // wire [15:0] TMIN = 16'b1000_0000_0000_0000;
    // genvar j; 
    // generate
    //     for(j = 0; j < 16; j = j + 1) begin : check_TMIN
    //         xor (comparison[j], a[j], TMIN [j]); 
    //     end
    // endgenerate

    // //use zero flag logic to see if compare is 0. If it is, then we had TMIN and overflow should be 1. Otherwise, overflow is 0.
    // zero_flag check_zero (
    //     .result(comparison),
    //     .zero(overflow)
    // );

endmodule