module top (
    input wire basys3_100MHz_clk, // 100 Mhz
    input wire reset,        // btnL

    // PmodMIC (Input) Ports JB
    input  wire mic_miso,    // Pin 3 PmodMIC
    output wire mic_ss,      // Pin 1 PmodMIC
    output wire mic_sck,     // Pin 4 PmodMIC
    
    // PmodI2S (Output) Ports JA
    output wire i2s_mclk,    // Pin 1 PmodI2S (12.288 MHz)
    output wire i2s_lrck,    // Pin 2 PmodI2S (48 kHz)
    output wire i2s_sck,     // Pin 3 PmodI2S (3.072 MHz)
    output wire i2s_sdin     // Pin 4 PmodI2S
);

//Clocking Wizard (Vivado auto-generated module) to get our 12.288 MHz clock. 12.288 MHz gets us 48KHz sampling frequency (about 2x human hearing frequency)
wire mclk_12_288;
clk_wiz_0 clock_divider_12_888 (
    .clk_in1(basys3_100MHz_clk),
    .reset(reset),
    .clk_out1(mclk_12_288)
);

clk_divider_48k_3_072M clock_divider_48k_3_072M (
    .mclk(mclk_12_288),
    .reset(reset),
    .i2s_sck(i2s_sck),
    .i2s_lrck(i2s_lrck)
);

// Connect internal MCLK to PmodI2S MCLK pin
assign i2s_mclk = mclk_12_288;

wire [11:0] audio_sample;
wire sample_ready;
pmod_mic_spi mic_interface (
    .mclk(mclk_12_288),
    .reset(reset),
    .i2s_sck(i2s_sck),
    .i2s_lrck(i2s_lrck),
    .mic_miso(mic_miso),
    .mic_ss(mic_ss),
    .mic_sck(mic_sck),
    .audio_sample(audio_sample),
    .sample_ready(sample_ready)
);

pmod_i2s_tx i2s_transmitter (
    .mclk(mclk_12_288),
    .reset(reset),
    .i2s_sck(i2s_sck),
    .i2s_lrck(i2s_lrck),
    .audio_sample(audio_sample),
    .i2s_sdin(i2s_sdin)
);

endmodule