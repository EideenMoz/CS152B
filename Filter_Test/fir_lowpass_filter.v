`timescale 1ns / 1ps

// ============================================================
// Module: fir_lowpass_simple
//
// 31-tap signed FIR low-pass filter for the Basys-3 audio
// project that drives the Digilent Pmod I2S2 / Pmod12S-style
// I2S interface from a 100 MHz Vivado design clock.
//
// Project timing assumptions:
//   System clock:          100 MHz
//   I2S LRCK/sample rate:  100 MHz / 2048 = 48,828.125 Hz
//   sample_valid:          one clk pulse per I2S output sample
//
// audio_top currently advances the ROM address once every
// DOWNSAMPLE_FACTOR = 8 I2S samples, so the ROM source advances
// at approximately 6,103.516 samples/s. This FIR still runs at
// the I2S output rate because the repeated/held ROM samples are
// presented to this module every I2S sample period.
//
// Filter design used here:
//   Effective FIR sample rate: 48,828.125 Hz
//   Target cutoff:             about 2.25 kHz
//   Number of taps:            31
//   Window:                    Hamming
//   Coefficients:              signed Q1.15 fixed-point
//
// Notes:
//   - output_sample is updated after the 31 multiply-accumulate
//     cycles complete.
//   - At 100 MHz this takes only 310 ns, which is complete before
//     i2s_tx begins shifting the next 16-bit audio word.
//   - The module uses one multiplier repeatedly instead of 31
//     parallel multipliers.
// ============================================================

module fir_lowpass_simple (
    input wire audio_clk,
    input wire audio_clk_locked,
    input wire sample_valid,
    input wire signed [15:0] input_sample,
    output reg signed [15:0] output_sample
);

    localparam NUM_TAPS = 31;

    // Signed Q1.15 coefficients for a 31-tap Hamming-windowed
    // low-pass FIR, normalized for approximately unity DC gain.
    function signed [15:0] coefficient;
        input [4:0] tap_index;
        begin
            case (tap_index)
                5'd0:  coefficient = -16'sd54;
                5'd1:  coefficient = -16'sd55;
                5'd2:  coefficient = -16'sd58;
                5'd3:  coefficient = -16'sd50;
                5'd4:  coefficient = -16'sd10;
                5'd5:  coefficient =  16'sd82;
                5'd6:  coefficient =  16'sd245;
                5'd7:  coefficient =  16'sd490;
                5'd8:  coefficient =  16'sd818;
                5'd9:  coefficient =  16'sd1216;
                5'd10: coefficient =  16'sd1657;
                5'd11: coefficient =  16'sd2105;
                5'd12: coefficient =  16'sd2517;
                5'd13: coefficient =  16'sd2849;
                5'd14: coefficient =  16'sd3064;
                5'd15: coefficient =  16'sd3139;
                5'd16: coefficient =  16'sd3064;
                5'd17: coefficient =  16'sd2849;
                5'd18: coefficient =  16'sd2517;
                5'd19: coefficient =  16'sd2105;
                5'd20: coefficient =  16'sd1657;
                5'd21: coefficient =  16'sd1216;
                5'd22: coefficient =  16'sd818;
                5'd23: coefficient =  16'sd490;
                5'd24: coefficient =  16'sd245;
                5'd25: coefficient =  16'sd82;
                5'd26: coefficient = -16'sd10;
                5'd27: coefficient = -16'sd50;
                5'd28: coefficient = -16'sd58;
                5'd29: coefficient = -16'sd55;
                5'd30: coefficient = -16'sd54;
                default: coefficient = 16'sd0;
            endcase
        end
    endfunction

    reg signed [15:0] sample_history [0:30];
    reg [4:0] tap_counter = 5'd0;
    reg busy = 1'b0;
    reg signed [39:0] accumulator = 40'sd0;

    wire signed [15:0] current_coefficient = coefficient(tap_counter);
    wire signed [15:0] current_sample = sample_history[tap_counter];
    wire signed [31:0] current_product = current_sample * current_coefficient;
    wire signed [39:0] current_product_extended = {{8{current_product[31]}}, current_product};
    wire signed [39:0] next_accumulator = accumulator + current_product_extended;

    // Convert Q1.15-scaled accumulator back to signed 16-bit audio scale.
    wire signed [39:0] scaled_result = next_accumulator >>> 15;

    integer i;

    always @(posedge audio_clk) begin
        if (audio_clk_locked == 1'b0) begin
            for (i = 0; i < NUM_TAPS; i = i + 1) begin
                sample_history[i] <= 16'sd0;
            end

            tap_counter   <= 5'd0;
            busy          <= 1'b0;
            accumulator   <= 40'sd0;
            output_sample <= 16'sd0;
        end else begin
            if ((sample_valid == 1'b1) && (busy == 1'b0)) begin
                for (i = NUM_TAPS-1; i > 0; i = i - 1) begin
                    sample_history[i] <= sample_history[i-1];
                end
                sample_history[0] <= input_sample;

                tap_counter <= 5'd0;
                accumulator <= 40'sd0;
                busy        <= 1'b1;
            end else if (busy == 1'b1) begin
                accumulator <= next_accumulator;

                if (tap_counter == NUM_TAPS-1) begin
                    // Saturate rather than wrap if a full-scale waveform plus
                    // coefficient quantization slightly exceeds 16-bit range.
                    if (scaled_result > 40'sd32767)
                        output_sample <= 16'sd32767;
                    else if (scaled_result < -40'sd32768)
                        output_sample <= -16'sd32768;
                    else
                        output_sample <= scaled_result[15:0];

                    busy        <= 1'b0;
                    tap_counter <= 5'd0;
                end else begin
                    tap_counter <= tap_counter + 1'b1;
                end
            end
        end
    end

endmodule
