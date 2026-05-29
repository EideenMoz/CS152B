`timescale 1ns / 1ps

module top (
    input  wire        basys3_100MHz_clk,
    input  wire        reset,      // BTN L in the XDC below

    // PmodMIC on JB
    input  wire        mic_miso,   // JB3
    output wire        mic_ss,     // JB1, active-low chip select
    output wire        mic_sck,    // JB4

    // Basys-3 LEDs
    output wire [15:0] led
);

    wire [11:0] mic_sample;
    wire        sample_ready;

    pmodmic_reader mic_reader (
        .clk_100mhz    (basys3_100MHz_clk),
        .reset         (reset),
        .mic_miso      (mic_miso),
        .mic_ss        (mic_ss),
        .mic_sck       (mic_sck),
        .sample        (mic_sample),
        .sample_ready  (sample_ready)
    );

    // Convert unsigned 12-bit ADC value to signed magnitude around midscale.
    // The microphone ADC is nominally centered near 2048.
    wire signed [12:0] centered_sample = {1'b0, mic_sample} - 13'sd2048;
    wire [12:0] abs_sample = centered_sample[12] ?
                              (~centered_sample + 13'd1) :
                               centered_sample;

    // Peak detector for visible LED activity.
    // sample_ready is too fast to see directly, so accumulate peak level
    // and refresh the LED bar at about 20 Hz.
    reg [12:0] peak = 13'd0;
    reg [22:0] refresh_count = 23'd0;
    reg [14:0] led_bar = 15'd0;
    reg [25:0] heartbeat = 26'd0;

    always @(posedge basys3_100MHz_clk or posedge reset) begin
        if (reset) begin
            peak          <= 13'd0;
            refresh_count <= 23'd0;
            led_bar       <= 15'd0;
            heartbeat     <= 26'd0;
        end else begin
            heartbeat <= heartbeat + 1'b1;

            if (sample_ready && abs_sample > peak)
                peak <= abs_sample;

            if (refresh_count == 23'd4_999_999) begin
                refresh_count <= 23'd0;

                led_bar[0]  <= (peak > 13'd4);
                led_bar[1]  <= (peak > 13'd8);
                led_bar[2]  <= (peak > 13'd16);
                led_bar[3]  <= (peak > 13'd32);
                led_bar[4]  <= (peak > 13'd64);
                led_bar[5]  <= (peak > 13'd96);
                led_bar[6]  <= (peak > 13'd128);
                led_bar[7]  <= (peak > 13'd192);
                led_bar[8]  <= (peak > 13'd256);
                led_bar[9]  <= (peak > 13'd384);
                led_bar[10] <= (peak > 13'd512);
                led_bar[11] <= (peak > 13'd768);
                led_bar[12] <= (peak > 13'd1024);
                led_bar[13] <= (peak > 13'd1536);
                led_bar[14] <= (peak > 13'd2047);

                peak <= 13'd0;
            end else begin
                refresh_count <= refresh_count + 1'b1;
            end
        end
    end

    assign led[14:0] = led_bar;
    assign led[15]   = heartbeat[25]; // slow blink proving FPGA is running

endmodule
