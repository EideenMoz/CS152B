`timescale 1ns / 1ps

module top (
    input  wire        basys3_100MHz_clk,
    input  wire        reset,       // BTN L

    // PmodMIC on JB
    input  wire        mic_miso,    // JB3
    output wire        mic_ss,      // JB1
    output wire        mic_sck,     // JB4

    // PmodI2S DAC on JA
    output wire        i2s_mclk,    // JA1
    output wire        i2s_lrck,    // JA2
    output wire        i2s_sck,     // JA3
    output wire        i2s_sdin,    // JA4

    // Debug LEDs
    output wire [15:0] led
);

    wire clk_audio;   // 12.288 MHz
    wire clk_locked;

    // Create this IP in Vivado:
    // Clocking Wizard name: clk_wiz_0
    // Input clock: 100 MHz
    // Output clk_out1: 12.288 MHz
    clk_wiz_0 audio_clock (
        .clk_in1  (basys3_100MHz_clk),
        .reset    (reset),
        .clk_out1 (clk_audio),
        .locked   (clk_locked)
    );

    wire audio_reset = reset | ~clk_locked;

    assign i2s_mclk = clk_audio;

    i2s_clock_gen clocks (
        .mclk     (clk_audio),
        .reset    (audio_reset),
        .i2s_sck  (i2s_sck),
        .i2s_lrck (i2s_lrck)
    );

    wire [11:0] mic_sample;
    wire        mic_sample_ready;

    pmodmic_reader_12m mic_reader (
        .mclk         (clk_audio),
        .reset        (audio_reset),
        .sample_tick  (i2s_lrck_rising),
        .mic_miso     (mic_miso),
        .mic_ss       (mic_ss),
        .mic_sck      (mic_sck),
        .sample       (mic_sample),
        .sample_ready (mic_sample_ready)
    );

    // Detect rising edge of LRCK in the 12.288 MHz domain.
    // This triggers one MIC sample per 48 kHz audio frame.
    reg lrck_d = 1'b0;
    always @(posedge clk_audio) begin
        if (audio_reset)
            lrck_d <= 1'b0;
        else
            lrck_d <= i2s_lrck;
    end

    wire i2s_lrck_rising = i2s_lrck & ~lrck_d;

    // PmodMIC ADC sample is unsigned 12-bit, nominally centered near 2048.
    // Convert to signed audio centered around zero.
    wire signed [12:0] mic_centered = {1'b0, mic_sample} - 13'sd2048;

    // Convert signed 13-bit microphone sample to signed 24-bit PCM.
    // This leaves some headroom and avoids immediate clipping.
    wire signed [23:0] pcm_sample = {mic_centered, 11'b0};

    pmod_i2s_tx i2s_tx (
        .mclk       (clk_audio),
        .reset      (audio_reset),
        .i2s_sck    (i2s_sck),
        .i2s_lrck   (i2s_lrck),
        .pcm_left   (pcm_sample),
        .pcm_right  (pcm_sample),
        .i2s_sdin   (i2s_sdin)
    );

    // LED debug: raw ADC value on lower 12 LEDs.
    assign led[11:0] = mic_sample;
    assign led[14:12] = 3'b000;
    assign led[15] = clk_locked;

endmodule
