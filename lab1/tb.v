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

    // Regular differences
    a=16'h0000; b=16'h0000; #10; // 0 - 0 = 0
    a=16'h0001; b=16'h0000; #10; // 1 - 0 = 1
    a=16'h0000; b=16'h0001; #10; // 0 - 1 = -1
    a=16'h0001; b=16'h0001; #10; // 1 - 1 = 0
    a=5;        b=3;        #10; // 5 - 3 = 2
    a=30;       b=25;       #10; // 30 - 25 = 5
    a=15000;    b=10111;    #10; // large positive result

    // Overflow (positive - negative)
    a=32767;    b=-1;       #10; // TMAX - (-1), overflows to TMIN
    a=30000;    b=-30000;   #10; // large positive overflow
    a=32767;    b=-32768;   #10; // TMAX - TMIN, most extreme overflow

    // Negative small tests
    a=-1;       b=-1;       #10; // -1 - (-1) = 0
    a=-5;       b=3;        #10; // -5 - 3 = -8
    a=-15000;   b=10111;    #10; // large negative result

    // Overflow (negative - positive)
    a=-32768;   b=1;        #10; // TMIN - 1, underflows to TMAX
    a=-20000;   b=20000;    #10; // large negative overflow
    a=-32768;   b=32767;    #10; // TMIN - TMAX, most extreme underflow

    // Carry vs overflow
    a=16'hFFFF; b=16'hFFFF; #10; // -1 - (-1) = 0, carry but no overflow
    a=16'hFFFF; b=1;        #10; // -1 - 1 = -2, no overflow

    // Boundary: results landing exactly on TMIN/TMAX
    a=32767;    b=0;        #10; // TMAX - 0 = TMAX
    a=-32768;   b=0;        #10; // TMIN - 0 = TMIN
    a=0;        b=-32768;   #10; // 0 - TMIN overflows (no positive counterpart)
    a=32767;    b=32767;    #10; // TMAX - TMAX = 0

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

    //===TEST set less than equal===\\
    opcode=9;
    a=1;        b=1;        #10; // 1 ≤ 1, should output 1
    a=0;        b=1;        #10; // 0 ≤ 1, should output 1
    a=1;        b=0;        #10; // 1 ≤ 0, should output 0
    a=0;        b=0;        #10; // 0 ≤ 0, should output 1
    a=-1;       b=0;        #10; // -1 ≤ 0, should output 1
    a=0;        b=-1;       #10; // 0 ≤ -1, should output 0
    a=-1;       b=-1;       #10; // -1 ≤ -1, should output 1
    a=-32768;   b=32767;    #10; // TMIN ≤ TMAX, should output 1
    a=32767;    b=-32768;   #10; // TMAX ≤ TMIN, should output 0
    a=-32768;   b=-32768;   #10; // TMIN ≤ TMIN, should output 1
    a=32767;    b=32767;    #10; // TMAX ≤ TMAX, should output 1
    a=-32768;   b=0;        #10; // TMIN ≤ 0, different signs, should output 1
    a=0;        b=-32768;   #10; // 0 ≤ TMIN, different signs, should output 0

    //===TEST arithmetic left shift===\\
    opcode=12;
    a=16'h0001; b=0;        #10; // 1 << 0 = 1, no shift
    a=16'h0001; b=1;        #10; // 1 << 1 = 2
    a=16'h0001; b=14;       #10; // 1 << 14 = 0x4000, still positive
    a=16'h0001; b=15;       #10; // 1 << 15 = 0x8000, overflows into sign bit
    a=16'h0001; b=16;       #10; // shift >= 16, result = 0
    a=16'h7FFF; b=1;        #10; // TMAX << 1, overflows into sign bit
    a=16'h8000; b=1;        #10; // TMIN << 1, MSB shifted out, result = 0
    a=16'hFFFF; b=1;        #10; // -1 << 1 = -2 (0xFFFE)
    a=16'hFFFF; b=15;       #10; // -1 << 15 = 0x8000 (TMIN)
    a=16'h0000; b=15;       #10; // 0 << anything = 0

    //===TEST arithmetic right shift===\\
    opcode=14;
    a=16'h0001; b=0;        #10; // 1 >> 0 = 1, no shift
    a=16'h0001; b=1;        #10; // 1 >> 1 = 0, shift out only bit
    a=16'h7FFF; b=1;        #10; // TMAX >> 1 = 0x3FFF, sign preserved (0)
    a=16'h7FFF; b=15;       #10; // TMAX >> 15 = 0, all bits shifted out
    a=16'h8000; b=1;        #10; // TMIN >> 1 = 0xC000, sign bit replicated
    a=16'h8000; b=15;       #10; // TMIN >> 15 = 0xFFFF (-1), all sign bits
    a=16'hFFFF; b=1;        #10; // -1 >> 1 = -1 (0xFFFF), sign preserved
    a=16'hFFFF; b=15;       #10; // -1 >> 15 = -1 (0xFFFF), sign preserved
    a=16'hFFFF; b=16;       #10; // shift >= 16, result = 0xFFFF (-1), all sign
    a=16'h0000; b=15;       #10; // 0 >> anything = 0

    //===TEST logical left shift===\\
    opcode=8;
    a=16'h0001; b=0;        #10; // 1 << 0 = 1, no shift
    a=16'h0001; b=1;        #10; // 1 << 1 = 2
    a=16'h0001; b=15;       #10; // 1 << 15 = 0x8000, shifted into MSB
    a=16'h0001; b=16;       #10; // shift >= 16, result = 0
    a=16'hFFFF; b=1;        #10; // 0xFFFF << 1 = 0xFFFE, LSB zeroed
    a=16'hFFFF; b=15;       #10; // 0xFFFF << 15 = 0x8000, only MSB remains
    a=16'hFFFF; b=16;       #10; // shift >= 16, result = 0
    a=16'h8000; b=1;        #10; // MSB shifted out, result = 0
    a=16'h0000; b=15;       #10; // 0 << anything = 0

    //===TEST logical right shift===\\
    opcode=10;
    a=16'h0001; b=0;        #10; // 1 >> 0 = 1, no shift
    a=16'h0001; b=1;        #10; // 1 >> 1 = 0, bit shifted out
    a=16'h8000; b=1;        #10; // 0x8000 >> 1 = 0x4000, MSB zeroed (unlike arithmetic)
    a=16'h8000; b=15;       #10; // 0x8000 >> 15 = 0x0001
    a=16'h8000; b=16;       #10; // shift >= 16, result = 0
    a=16'hFFFF; b=1;        #10; // 0xFFFF >> 1 = 0x7FFF, MSB zeroed
    a=16'hFFFF; b=15;       #10; // 0xFFFF >> 15 = 0x0001
    a=16'hFFFF; b=16;       #10; // shift >= 16, result = 0
    a=16'h0000; b=15;       #10; // 0 >> anything = 0

    $finish;

end
endmodule
