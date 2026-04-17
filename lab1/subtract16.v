module subtract16 (
    output [15:0] out,
    output        overflow,
    input  [15:0] a,
    input  [15:0] b
);

    wire [15:0] inverted_b;
    wire overflow_inv, overflow_add;

    //note invert inverts sign (not bitwise NOT)
    invert16 inv_sub (
        .a(b),
        .y(inverted_b)
    );

    addition16 add_sub (
        .sum(out),
        .overflow(overflow),
        .a(a),
        .b(inverted_b)
    );

    or(overflow, overflow_inv, overflow_add);
    
endmodule