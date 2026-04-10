module decrement16 (
    output [15:0] out,
    output        overflow,
    input  [15:0] in
);

    // subtract 1 = add 0xFFFF
    addition16 add_dec (
        .sum(out),
        .overflow(overflow),
        .a(in),
        .b(-1)
    );

endmodule