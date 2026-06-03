`timescale 1ns / 1ps

module audio_gain(
    input [1:0] sw,                   
    input is_filter_on,                // boosts gain when filtering
    input signed [15:0] audio_in,      // Audio is 2's complement signed data
    output reg signed [15:0] audio_out
);

    reg signed [23:0] amplified;
    reg [2:0] total_shift;

    always @(*) begin
        case(sw)
            3'b000:  total_shift = 3'd0; // 1x gain (no shift)
            3'b001:  total_shift = 3'd1; // 2x gain
            3'b010:  total_shift = 3'd2; // 4x gain
            3'b011:  total_shift = 3'd3; // 8x gain
            default: total_shift = 3'd0; // Default fallback to 1x
        endcase

        // 2. If the filter is on, add 1 to the shift count (effectively doubling the gain)
        if (is_filter_on) begin
            amplified = audio_in <<< (total_shift + 1);
        end else begin
            amplified = audio_in <<< total_shift;
        end

        // 3. Saturation / Clipping logic
        if (amplified > 24'sd32767)
            audio_out = 16'sd32767;      // Clamp to max positive 16-bit value
        else if (amplified < -24'sd32768)
            audio_out = -16'sd32768;     // Clamp to max negative 16-bit value
        else
            audio_out = amplified[15:0]; // Safe to output normally
    end

endmodule