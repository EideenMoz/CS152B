module subtract16 (
    output [15:0] out,
    output        cout,
    output        overflow,
    input  [15:0] A,
    input  [15:0] B
);

    wire [15:0] B_inverted;
    wire [15:0] B_twos;
    wire        inc_cout;
    wire        inc_overflow;

    // Step 1: invert B
    invert16 INV_B (
        B,
        B_inverted,
        overlow
    );

    // Step 2: add 1 to make two's complement
    increment16 INC_B (
        B_twos,
        inc_cout,
        inc_overflow,
        B_inverted
    );

    // Step 3: add A + two's complement of B
    adder16 ADD_SUB (
        out,
        cout,
        overflow,
        A,
        B_twos,
        1'b0
    );

endmodule