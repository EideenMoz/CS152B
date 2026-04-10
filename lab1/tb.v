`timescale 1ns / 1ps
module tb();

wire [15:0] S;
wire cout;
wire overflow;
wire zero;
reg [15:0] a;
reg [15:0] b;
reg [3:0] opcode;

ALU_top dut (
    .a(a),
    .b(b),
    .ALU_ctrl(opcode), 
    .result(S),
    .zero(zero),
    .overflow(overflow)
);

initial begin 
    //INT_MAX=32767, INT_MIN =-32,768

    //===TEST subtraction===\\
    opcode=0;

    //===TEST addition===\\
    opcode=1;

    //Regular sums
    a=16'h0000; b=16'h0000; #10;
    a=16'h0001; b=16'h0000; #10;
    a=16'h0000; b=16'h0001; #10;
    a=16'h0001; b=16'h0001; #10;
    a=5; b=3; #10;
    a=25; b=30; #10;
    a=15000; b=10111; #10;

    //overflow
    a=30000; b=30000; #10;
    a=32767; b=1; #10;
    a=32766; b=1; #10;

    // Negative smalltests
    a = -1; b = -1; #10;
    a = -5; b = 3; #10;
    a=-15000; b=-10111; #10;

    // Overflow tests
    a = -32768; b = -1; #10;
    a = -20000; b = -20000; #10;
    a = -32768; b = -0; #10;

    // Carry vs overflow
    a = 16'hFFFF; b = 1; #10;

    // Boundary
    a = -32768; b = 1; #10;
    a = 32767; b = -1; #10;

    //===TEST bitwise OR===\\
    opcode=2;

    // Regular OR
    a=16'h0000; b=16'h0000; #10; // all zeros
    a=16'hFFFF; b=16'h0000; #10; // all ones x all zeros
    a=16'h0000; b=16'hFFFF; #10; // all ones x all zeros
    a=16'hAAAA; b=16'h5555; #10; // alternating bits
    a=16'h8000; b=16'h0001; #10; // MSB and LSB

    // Edge OR cases
    a=16'hFFFF; b=16'hFFFF; #10; // all ones
    a=16'h7FFF; b=16'h8000; #10; // boundary
    a=16'h0001; b=16'h8000; #10; // first and last

    //===TEST bitwise AND===\\
    opcode=3;

    // Regular AND
    a=16'hFFFF; b=16'h0000; #10; //all ones x all zeros
    a=16'hFFFF; b=16'hFFFF; #10; //all ones
    a=16'hAAAA; b=16'h5555; #10; // alternating bits
    a=16'h8000; b=16'h0001; #10; // MSB and LSB

    // Edge AND cases
    a=16'h7FFF; b=16'h8000; #10; // boundary
    a=16'h0001; b=16'h8000; #10; // first and last
    a=16'h0000; b=16'h0000; #10; // all zeros

    //===TEST decrement===\\
    opcode=4;
    a=16'h0000; b=16'hxxxx; #10; // 0 → -1 (0xFFFF), crosses zero boundary
    a=16'h0001; b=16'hxxxx; #10; // 1 → 0, smallest positive to zero
    a=16'h8000; b=16'hxxxx; #10; // TMIN → TMIN-1, signed overflow (wraps to TMAX=0x7FFF)
    a=16'hFFFF; b=16'hxxxx; #10; // -1 → -2, typical negative value

    //===TEST increment===\\
    opcode=5;
    a=16'hFFFF; b=16'hxxxx; #10; // -1 → 0, crosses zero boundary
    a=16'h0000; b=16'hxxxx; #10; // 0 → 1, zero to smallest positive
    a=16'h7FFF; b=16'hxxxx; #10; // TMAX → TMAX+1, signed overflow (wraps to TMIN=0x8000)
    a=16'h8000; b=16'hxxxx; #10; // TMIN → TMIN+1, most negative value incremented

    //===TEST invert (two's complement negation)===\\
    opcode=6;
    a=16'h0001; b=16'hxxxx; #10; // 1 → -1 (0xFFFF)
    a=16'hFFFF; b=16'hxxxx; #10; // -1 → 1
    a=16'h0000; b=16'hxxxx; #10; // 0 → 0, negation of zero is zero
    a=16'h8000; b=16'hxxxx; #10; // TMIN → TMIN, only value that overflows (no positive counterpart)
    a=16'h7FFF; b=16'hxxxx; #10; // TMAX → -TMAX (0x8001)

    $finish;
end
endmodule
