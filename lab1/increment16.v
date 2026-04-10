module increment16 (
    output wire [15:0] out,
    output   wire     overflow,
    input  wire [15:0] in
);

    addition16 add_inc (
        .sum(out),
        .overflow(overflow),
        .a(in),
        .b(1)
    );

endmodule