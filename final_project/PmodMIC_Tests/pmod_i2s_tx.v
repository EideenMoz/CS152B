`timescale 1ns / 1ps

module pmod_i2s_tx (
    input  wire               mclk,       // 12.288 MHz
    input  wire               reset,
    input  wire               i2s_sck,    // 3.072 MHz
    input  wire               i2s_lrck,   // 48 kHz

    input  wire signed [23:0] pcm_left,
    input  wire signed [23:0] pcm_right,

    output reg                i2s_sdin
);

    reg sck_d  = 1'b0;
    reg lrck_d = 1'b0;

    always @(posedge mclk) begin
        if (reset) begin
            sck_d  <= 1'b0;
            lrck_d <= 1'b0;
        end else begin
            sck_d  <= i2s_sck;
            lrck_d <= i2s_lrck;
        end
    end

    wire sck_falling = sck_d & ~i2s_sck;
    wire lrck_edge   = lrck_d ^ i2s_lrck;

    reg [31:0] shift_reg = 32'd0;

    always @(posedge mclk or posedge reset) begin
        if (reset) begin
            shift_reg <= 32'd0;
            i2s_sdin  <= 1'b0;
        end else begin
            if (sck_falling) begin
                if (lrck_edge) begin
                    // I2S has a one-bit-clock delay after LRCK changes.
                    // LRCK low is commonly left, LRCK high is commonly right.
                    if (i2s_lrck == 1'b0)
                        shift_reg <= {pcm_left, 8'd0};
                    else
                        shift_reg <= {pcm_right, 8'd0};

                    i2s_sdin <= 1'b0;
                end else begin
                    i2s_sdin  <= shift_reg[31];
                    shift_reg <= {shift_reg[30:0], 1'b0};
                end
            end
        end
    end

endmodule
