`timescale 1ns / 1ps

module audio_top(
    input clk,
    input btn,           // start button
    input [1:0] sw,      // 2-bit switch for gain control

    // Pmod I2S pins mapped in the XDC file
    output mclk,
    output lrck,
    output sclk,
    output sdin
);

// 1. Audio Memory
localparam MAX_ADDR = 7487;
localparam DOWNSAMPLE_FACTOR = 8;

reg [15:0] audio_rom [0:MAX_ADDR];
initial begin
    $readmemh("audio_data.mem", audio_rom);
end

// 2. Button Edge Detection
reg [1:0] btn_sync = 2'b00;
wire btn_pulse = (btn_sync == 2'b01);

always @(posedge clk) begin
    btn_sync <= {btn_sync[0], btn};
end

// 3. ROM Playback State Logic
reg [16:0] address = 17'd0;
reg [7:0]  hold_counter = 8'd0;
reg playing = 1'b0;

wire next_sample;

always @(posedge clk) begin
    if (btn_pulse && !playing) begin
        playing      <= 1'b1;
        address      <= 17'd0;
        hold_counter <= 8'd0;
    end else if (playing && next_sample) begin
        if (hold_counter == (DOWNSAMPLE_FACTOR - 1)) begin
            hold_counter <= 8'd0;

            if (address < MAX_ADDR) begin
                address <= address + 1'b1;
            end else begin
                playing <= 1'b0;
                address <= 17'd0;
            end
        end else begin
            hold_counter <= hold_counter + 1'b1;
        end
    end
end

// Present the current ROM sample directly to the FIR when next_sample is
// asserted. The address update occurs on the same clock edge, so this gives
// the FIR the intended current held sample rather than a stale registered copy.
wire signed [15:0] sample_to_filter = playing ? $signed(audio_rom[address]) : 16'sd0;

// 4. FIR Low-Pass Filter
wire signed [15:0] filtered_audio;

fir_lowpass_simple lowpass_filter (
    .audio_clk(clk),
    .audio_clk_locked(playing),
    .sample_valid(next_sample),
    .input_sample(sample_to_filter),
    .output_sample(filtered_audio)
);

// 5. Digital Gain Module
wire signed [15:0] gained_audio;

audio_gain volume_control (
    .sw(sw),
    .audio_in(filtered_audio),
    .audio_out(gained_audio)
);

// 6. I2S Transmitter
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
