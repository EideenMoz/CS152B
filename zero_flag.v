`timescale 1ns / 1ps
module zero_flag(
    input  wire [15:0] result,
    output wire zero
);
    wire [15:0] temp;

    // OR all bits together structurally
    or u0(temp[0], result[0], result[1]);
    or u1(temp[1], result[2], result[3]);
    or u2(temp[2], result[4], result[5]);
    or u3(temp[3], result[6], result[7]);
    or u4(temp[4], result[8], result[9]);
    or u5(temp[5], result[10], result[11]);
    or u6(temp[6], result[12], result[13]);
    or u7(temp[7], result[14], result[15]);

    or u8(temp[8], temp[0], temp[1]);
    or u9(temp[9], temp[2], temp[3]);
    or u10(temp[10], temp[4], temp[5]);
    or u11(temp[11], temp[6], temp[7]);

    or u12(temp[12], temp[8], temp[9]);
    or u13(temp[13], temp[10], temp[11]);

    or u14(temp[14], temp[12], temp[13]);

    // zero flag = NOT(any bit is 1)
    not u15(zero, temp[14]);

endmodule
