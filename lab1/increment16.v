module increment16 (
    output wire [15:0] out,
    output  wire      cout,
    output   wire     overflow,
    input  wire [15:0] in
);

    // increment: in + 0 + 1
    adder16 ADD_INC (
        out,
        cout,
        overflow,
        in,
        16'h0000,
        1'b1
    );

endmodule