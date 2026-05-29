`timescale 1ns / 1ps

module audio_gain(
    input [1:0] sw,
    input signed [15:0] audio_in,     // Audio is 2's complement signed data
    output reg signed [15:0] audio_out
    );

    // We need a larger register to hold the multiplied value temporarily
    // 16 bits shifted left by 3 (8x gain) needs 19 bits. We use 20 to be safe.
    reg signed [19:0] amplified;

    always @(*) begin
        // Apply digital gain using an arithmetic left shift (<<<)
        // This shifts the bits while preserving the positive/negative sign bit
        case(sw)
            2'b00: amplified = audio_in;           // 1x gain
            2'b01: amplified = audio_in <<< 1;     // 2x gain
            2'b10: amplified = audio_in <<< 2;     // 4x gain
            2'b11: amplified = audio_in <<< 3;     // 8x gain
            default: amplified = audio_in;
        endcase

        // Saturation / Clipping logic to prevent integer overflow
        if (amplified > 20'sd32767)
            audio_out = 16'sd32767;      // Clamp to max positive 16-bit value
        else if (amplified < -20'sd32768)
            audio_out = -16'sd32768;     // Clamp to max negative 16-bit value
        else
            audio_out = amplified[15:0]; // Safe to output normally
    end

endmodule