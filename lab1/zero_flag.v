`timescale 1ns / 1ps
module zero_flag(
    input  wire [15:0] result,
    output wire zero
);
    wire [15:0] temp;

    // OR all bits together structurally
    or(temp[0], result[0], result[1]);
    or(temp[1], result[2], result[3]);
    or(temp[2], result[4], result[5]);
    or(temp[3], result[6], result[7]);
    or(temp[4], result[8], result[9]);
    or(temp[5], result[10], result[11]);
    or(temp[6], result[12], result[13]);
    or(temp[7], result[14], result[15]);

    or(temp[8], temp[0], temp[1]);
    or(temp[9], temp[2], temp[3]);
    or(temp[10], temp[4], temp[5]);
    or(temp[11], temp[6], temp[7]);

    or(temp[12], temp[8], temp[9]);
    or(temp[13], temp[10], temp[11]);

    or(temp[14], temp[12], temp[13]);

    // zero flag = NOT(any bit is 1)
    not(zero, temp[14]);

endmodule
