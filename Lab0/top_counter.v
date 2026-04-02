`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 04/01/2026 11:08:09 AM
// Design Name: 
// Module Name: top_counter
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


module top_counter(
    input wire clk,
    input wire rst,
    output wire [3:0] count
    );
    wire clk_1hz;
    clock_divider_1hz divider (
        .clk(clk),
        .rst(rst),
        .clk_1hz(clk_1hz)
    );
    counter_4bit counter(
        .clk(clk_1hz),
        .rst(rst),
        .count(count)
    );
endmodule
