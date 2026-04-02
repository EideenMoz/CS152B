`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 03/30/2026 11:45:26 AM
// Design Name: 
// Module Name: test_bench
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module tb_counter_4bit;
    reg clk;
    reg rst;
    wire [3:0] count;
    counter_4bit uut(
        .clk(clk),
        .rst(rst),
        .count(count)
    );
    initial begin
        clk = 0;
        forever #5 clk=~clk;
    end
    initial begin
        rst = 1;
        #12;
        rst = 0;
        #200;
        rst = 1;
        #7;
        rst = 0;
        #100;
        $finish;
    end
    initial begin
        $display("Time\tclk\trst\tcount");
        $monitor("%0t\t%b\t%b\t%0d", $time, clk, rst, count);
    end
endmodule
       
      
