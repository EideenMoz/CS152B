module decrement16 (
    output [15:0] out,
    output        cout,
    output        overflow,
    input  [15:0] in
);

    // subtract 1 = add 0xFFFF
    addition16 DEC (
        out,
        cout,
        overflow,
        in,
        16'hFFFF,
        1'b0
    );

endmodule