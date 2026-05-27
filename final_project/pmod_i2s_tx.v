`timescale 1ns / 1ps

module pmod_i2s_tx (
    input  wire        mclk,         // 12.288 MHz master clock
    input  wire        reset,        // System reset
    input  wire        i2s_sck,      // 3.072 MHz bit clock
    input  wire        i2s_lrck,     // 48 kHz word select clock
    
    input  wire [11:0] audio_sample, // The 12-bit data from your SPI Master
    output reg         i2s_sdin = 1'b0 // Serial data out to PmodI2S (Pin 4)
);

    // Edge Detection for SCK and LRCK
    reg sck_delay  = 1'b0;
    reg lrck_delay = 1'b0;
    wire sck_falling_edge;
    wire lrck_edge;

    // store the previous state of slower clocks to detect edges
    always @(posedge mclk) begin
        sck_delay  <= i2s_sck;
        lrck_delay <= i2s_lrck;
    end

    // We shift data out on the falling edge of SCK so the DAC can safely read it on the rising edge
    assign sck_falling_edge = (sck_delay && !i2s_sck);
    
    // Detect anytime the Left/Right clock changes channels
    assign lrck_edge = (lrck_delay != i2s_lrck); 

    // 32-bit Shift Register
    reg [31:0] shift_reg = 32'd0;

    always @(posedge mclk or posedge reset) begin
        if (reset) begin
            shift_reg <= 32'd0;
            i2s_sdin  <= 1'b0;
        end else begin
            if (sck_falling_edge) begin
                
                // If LRCK just flipped, we are starting a brand new audio channel
                if (lrck_edge) begin
                    // Load the 12-bit audio sample, pad the remaining 20 bits with zeros
                    shift_reg <= {audio_sample, 20'd0}; 
                    
                    // Output a 0 for this exact cycle to fulfill the I2S "1-clock delay" rule
                    i2s_sdin  <= 1'b0; 
                end 
                
                // Otherwise, we are in the middle of a word, so just keep shifting left
                else begin
                    shift_reg <= {shift_reg[30:0], 1'b0};
                    i2s_sdin  <= shift_reg[31]; // Push the next highest bit to the physical pin
                end
                
            end
        end
    end

endmodule