`timescale 1ns / 1ps

module audio_top(
    input clk,
    output [15:0] led,
    
    // Pmod I2S pins (Mapped to Port JA)
    output mclk,
    output lrck,
    output sclk,
    output sdin
    );

    // 1. Audio Memory (Adjust the size to match your .mem file exactly!)
    // e.g., If your Python script output 50,000 samples, change to 49999
    localparam MAX_ADDR = 29951; 
    
    reg [15:0] audio_rom [0:MAX_ADDR];
    initial begin
        $readmemh("audio_data.mem", audio_rom);
    end

    // 2. ROM Read Logic
    localparam DOWNSAMPLE_FACTOR = 2; 
    
    reg [16:0] address = 0;
    reg [15:0] current_audio = 0;
    reg [7:0]  hold_counter = 0; // Counter to hold the sample
    wire next_sample;

    always @(posedge clk) begin
        if (next_sample) begin
            // Only increment address when we've held the sample long enough
            if (hold_counter == (DOWNSAMPLE_FACTOR - 1)) begin
                hold_counter <= 0;
                
                if (address < MAX_ADDR)
                    address <= address + 1;
                else
                    address <= 0; // Loop audio
            end else begin
                hold_counter <= hold_counter + 1;
            end
        end
        
        current_audio <= audio_rom[address]; 
    end
    
    // Use LEDs as a visual progress bar of the memory address
    assign led = address[16:1]; 

    // 3. I2S Transmitter Instantiation
    i2s_tx i2s_tx (
        .clk(clk),
        .audio_in(current_audio),
        .mclk(mclk),
        .lrck(lrck),
        .sclk(sclk),
        .sdin(sdin),
        .next_sample(next_sample)
    );

endmodule