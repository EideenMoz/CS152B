`timescale 1ns / 1ps
`include "audio_config.vh"

module audio_top(
input clk,
input btn,           // start button
input [1:0] sw,     // 3-bit switch for gain control
input is_filter_on,
//output [15:0] led,

// Pmod I2S pins (Mapped to Port JA)
output mclk,
output lrck,
output sclk,
output sdin
);

// Auto generated audio memory 
localparam MAX_ADDR          = `CONFIG_MAX_ADDR; 
localparam DOWNSAMPLE_FACTOR = `CONFIG_DOWNSAMPLE;

reg [15:0] audio_rom [0:MAX_ADDR];
initial begin
    $readmemh("audio_data.mem", audio_rom);
end

// Button Edge Detection
reg [1:0] btn_sync = 0;
wire btn_pulse = (btn_sync == 2'b01);

always @(posedge clk) begin
    btn_sync <= {btn_sync[0], btn};
end

// ROM Read & State Logic
reg [16:0] address = 0;
reg [15:0] current_audio = 0;
reg [7:0]  hold_counter = 0; 
reg playing = 0; // NEW: Keeps track of playback state

wire next_sample;

always @(posedge clk) begin
    // Start playback on button press
    if (btn_pulse && !playing) begin
        playing <= 1'b1;
        address <= 0;
        hold_counter <= 0;
    end 
    // Handle playback progression
    else if (playing && next_sample) begin
        if (hold_counter == (DOWNSAMPLE_FACTOR - 1)) begin
            hold_counter <= 0;
            
            if (address < MAX_ADDR) begin
                address <= address + 1;
            end else begin
                playing <= 1'b0; // STOP playing when we reach the end
                address <= 0;
            end
        end else begin
            hold_counter <= hold_counter + 1;
        end
    end
    
    // Output silence (0) when not playing, otherwise output memory data
    current_audio <= playing ? audio_rom[address] : 16'd0; 
end

// Filter and apply gain
wire [15:0] filtered_audio;
fir_lowpass_simple lowpass_filter (
    .audio_clk(clk),                
    .audio_clk_locked(1'b1),       
    .sample_valid(next_sample),     
    .input_sample(current_audio),    
    .output_sample(filtered_audio)   
);

// Select between filtered and unfiltered audio based on the switch
wire [15:0] input_audio = is_filter_on ? filtered_audio : current_audio;
wire [15:0] gained_audio;
audio_gain volume_control (
    .sw(sw),                     
    .is_filter_on(is_filter_on), //higher gain when filter is on to compensate for being quieter
    .audio_in(input_audio),
    .audio_out(gained_audio)
);

// I2S Transmitter
i2s_tx i2s_tx (
    .clk(clk),
    .audio_in(gained_audio),
    .mclk(mclk),
    .lrck(lrck),
    .sclk(sclk),
    .sdin(sdin),
    .next_sample(next_sample)
);
endmodule