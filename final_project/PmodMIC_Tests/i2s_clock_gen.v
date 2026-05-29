`timescale 1ns / 1ps

module i2s_clock_gen (
    input  wire mclk,       // 12.288 MHz
    input  wire reset,
    output wire i2s_sck,    // 3.072 MHz
    output wire i2s_lrck    // 48 kHz
);

    reg [7:0] counter = 8'd0;

    always @(posedge mclk or posedge reset) begin
        if (reset)
            counter <= 8'd0;
        else
            counter <= counter + 1'b1;
    end

    // 12.288 MHz / 4   = 3.072 MHz bit clock
    // 12.288 MHz / 256 = 48 kHz left/right clock
    assign i2s_sck  = counter[1];
    assign i2s_lrck = counter[7];

endmodule
