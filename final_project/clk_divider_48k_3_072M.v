`timescale 1ns / 1ps

module clk_divider_48k_3_072M (
    input  wire mclk,         // 12.288 MHz input clock from Clocking Wizard
    input  wire reset,        // System reset (active high)
    output wire i2s_sck,      // 3.072 MHz output (Bit Clock)
    output wire i2s_lrck      // 48 kHz output (Left/Right Word Select)
);

    // An 8-bit counter counts from 0 to 255
    reg [7:0] clk_counter = 8'b0;

    always @(posedge mclk or posedge reset) begin
        if (reset) begin
            clk_counter <= 8'b0;
        end else begin
            clk_counter <= clk_counter + 1'b1;
        end
    end

    // Bit 1 toggles every 4 MCLK cycles (3.072 MHz) -> Our SCK
    // Bit 7 toggles every 256 MCLK cycles (48 kHz)  -> Our LRCK
    assign i2s_sck  = clk_counter[1];
    assign i2s_lrck = clk_counter[7];

endmodule