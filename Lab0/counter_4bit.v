`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 04/01/2026 10:12:28 AM
// Design Name: 
// Module Name: counter_4bit
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


module counter_4bit(
    input wire clk,
    input wire rst,
    output wire [3:0] count
    );

    
    reg [3:0] ctr = 0;
    always @(posedge clk or posedge rst) begin
        if(rst) begin
            ctr <= 4'd0;
        end else begin
            if(ctr == 4'd15) 
                ctr <= 4'd0;
            else
                ctr <= ctr + 1'b1;
        end
    end
    
    assign count = ctr;
    
    
endmodule
