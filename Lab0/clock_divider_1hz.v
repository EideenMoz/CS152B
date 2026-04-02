`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 04/01/2026 11:03:13 AM
// Design Name: 
// Module Name: clock_divider_1hz
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


module clock_divider_1hz(
    input wire clk,
    input wire rst,
    output reg clk_1hz
    );
    
    reg [31:0] clock_div_reg = 0;
    localparam clock_count = 50_000_000;
       
    always @(posedge clk or posedge rst) begin
        if(rst) begin
            clock_div_reg <= 32'd0;
            clk_1hz <= 1'b0;
        end else begin
            if(clock_div_reg > clock_count) begin
                clk_1hz <= ~clk_1hz;
                clock_div_reg <= 32'd0;
            end else begin
                clock_div_reg <= clock_div_reg + 1;
            end
        end
    end
endmodule
