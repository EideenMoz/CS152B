`timescale 1ns / 1ps

module i2s_tx(
    input clk,             // 100 MHz Basys 3 clock
    input [15:0] audio_in, // 16-bit audio sample
    output mclk,           // Master Clock
    output lrck,           // Left/Right Clock (Word Select)
    output sclk,           // Serial Clock (Bit Clock)
    output sdin,           // Serial Data
    output reg next_sample // High for 1 clock cycle when we need a new sample
    );

    // 11-bit counter to divide the 100 MHz clock
    reg [10:0] cnt = 0;
    
    always @(posedge clk) begin
        cnt <= cnt + 1;
        // Trigger next sample request right before the frame ends
        // This gives the Block RAM enough time to fetch the next data
        if (cnt == 11'd2046) 
            next_sample <= 1'b1;
        else
            next_sample <= 1'b0;
    end

    // Clock generation directly from counter bits
    assign mclk = cnt[2];  // 12.5 MHz
    assign sclk = cnt[4];  // 3.125 MHz (64 SCLKs per LRCK frame)
    assign lrck = cnt[10]; // 48.828 kHz 
    
    // Data shift logic
    // cnt[9:5] represents the bit index within the current channel (0 to 31)
    wire [4:0] bit_index = cnt[9:5];
    
    // I2S delays data by 1 SCLK cycle. 
    // Bits 1 through 16 of the 32-bit channel frame contain our 16-bit audio.
    assign sdin = (bit_index >= 1 && bit_index <= 16) ? audio_in[16 - bit_index] : 1'b0;

endmodule