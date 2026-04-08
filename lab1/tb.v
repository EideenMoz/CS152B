`timescale 1ns / 1ps
module tb();

wire [15:0] result_S;
wire cout;
wire overflow;
reg [15:0] a;
reg [15:0] b;
reg cin;

addition16 add (
    .sum(result_S),
    .cout(cout),
    .overflow(overflow),
    .a(a),
    .b(b),
    .cin(cin)
);

initial begin 
    //INT_MAX=32767, INT_MIN=-32,768

    //===TEST addition16===//

    //Regular sums
    a=16'h0000; b=16'h0000; cin=0; #10;
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
    a = -1; b = -1; cin = 0; #10;
    a = -5; b = 3; #10;
    a=-15000; b=-10111; #10;

    // Overflow tests
    a = -32768; b = -1; #10;
    a = -20000; b = -20000; #10;
    a = -32768; b = -0; #10;

    // Carry vs overflow
    a = 16'hFFFF; b = 1; #10;

    // CIN tests
    a = 0; b = 0; cin = 1; #10;
    a = 32767; b = 0; cin = 1; #10;

    // Boundary
    a = -32768; b = 1; #10;
    a = 32767; b = -1; #10;


    $finish;
end
endmodule
