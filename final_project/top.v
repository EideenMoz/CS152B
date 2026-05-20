module top (
    input  wire basys3_100MHz_clk,

    // PmodMIC (Input) Ports
    input  wire mic_miso,    // Pin 3 on PmodMIC
    output wire mic_ss,      // Pin 1 on PmodMIC
    output wire mic_sck,     // Pin 4 on PmodMIC
    
    // Legacy PmodI2S (Output) Ports
    output wire i2s_mclk,    // Pin 1 on Legacy PmodI2S (12.288 MHz)
    output wire i2s_lrck,    // Pin 2 on Legacy PmodI2S (48 kHz)
    output wire i2s_sck,     // Pin 3 on Legacy PmodI2S (3.072 MHz)
    output wire i2s_sdin     // Pin 4 on Legacy PmodI2S
);

//Clocking Wizard to get our 12.288 MHz clock  --> 12.288 MHz gets us 48KHz sampling frequency (about 2x human hearing frequency)
wire mclk_12_288;
clk_wiz_0 clock_divider (
    .clk_in1(basys3_100MHz_clk),
    .clk_out1(mclk_12_288)
);

// Connect internal MCLK straight to the physical PmodI2S MCLK pin
assign i2s_mclk = mclk_12_288;

// TODO: Instantiate Audio Clock Divider
// TODO: Instantiate SPI Master (PmodMIC)
// TODO: Instantiate I2S Transmitter (PmodI2S)

endmodule