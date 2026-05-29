`timescale 1ns / 1ps

module audio_top(
input clk,
input btn,           // start button
input [1:0] sw,     // 2-bit switch for gain control
//output [15:0] led,

// Pmod I2S pins (Mapped to Port JA)
output mclk,
output lrck,
output sclk,
output sdin
);

// 1. Audio Memory (Adjust the size to match your .mem file exactly!)
localparam MAX_ADDR = 7487; 
localparam DOWNSAMPLE_FACTOR = 8; 

reg [15:0] audio_rom [0:MAX_ADDR];
initial begin
    $readmemh("audio_data.mem", audio_rom);
end

// 2. Button Edge Detection
// This ensures pressing the button creates a single, 1-clock-cycle pulse,
// so holding the button down doesn't glitch the audio.
reg [1:0] btn_sync = 0;
wire btn_pulse = (btn_sync == 2'b01);

always @(posedge clk) begin
    btn_sync <= {btn_sync[0], btn};
end

// 3. ROM Read & State Logic
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

// 3. Digital Gain Module Instantiation
wire [15:0] gained_audio;

audio_gain volume_control (
    .sw(sw),
    .audio_in(current_audio),
    .audio_out(gained_audio)
);

// 4. I2S Transmitter Instantiation
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