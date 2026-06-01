`timescale 1ns / 1ps

// ============================================================
// Module: fir_lowpass_simple
//
// Step 15 version:
//   31-tap coefficient FIR low-pass filter.
//
// Filter design:
//   Sample rate:       48,000 Hz
//   Cutoff frequency:  4,000 Hz
//   Number of taps:    31
//   Window:            Hamming
//   Coefficients:      signed Q1.15 fixed-point
//
// Why keep the old module name?
//   top.v already instantiates fir_lowpass_simple.
//   By keeping the same module name and ports, we do not need
//   to edit the rest of the project.
//
// Important beginner explanation:
//
//   A FIR filter computes:
//
//     y[n] = h0*x[n] + h1*x[n-1] + ... + h30*x[n-30]
//
//   x[n] means the newest input sample.
//   x[n-1] means the previous sample.
//   h0, h1, ..., h30 are fixed coefficients.
//
//   This module uses one multiplier repeatedly.
//   It does not compute all 31 multiplications at the same time.
// ============================================================

module fir_lowpass_simple (
    // --------------------------------------------------------
    // 12.288 MHz audio clock.
    // --------------------------------------------------------
    input wire audio_clk,

    // --------------------------------------------------------
    // Clock locked signal from the Clocking Wizard.
    //
    // When this is 0, reset the filter state.
    // --------------------------------------------------------
    input wire audio_clk_locked,

    // --------------------------------------------------------
    // sample_valid is high for one audio-clock cycle whenever
    // a new audio sample should enter the filter.
    //
    // In this project, that happens 48,000 times per second.
    // --------------------------------------------------------
    input wire sample_valid,

    // --------------------------------------------------------
    // New signed 16-bit input audio sample.
    // --------------------------------------------------------
    input wire signed [15:0] input_sample,

    // --------------------------------------------------------
    // Signed 16-bit filtered output audio sample.
    // --------------------------------------------------------
    output reg signed [15:0] output_sample
);

    // ========================================================
    // 1. Filter constants
    // ========================================================

    // Number of FIR taps.
    //
    // A tap is one sample in the FIR delay line.
    localparam NUM_TAPS = 31;


    // ========================================================
    // 2. Coefficient lookup function
    // ========================================================

    // This function returns the coefficient for a given tap.
    //
    // The coefficients are signed Q1.15 fixed-point numbers.
    //
    // Q1.15 means:
    //   real_value ≈ integer_value / 32768
    //
    // Example:
    //   16384 represents about 0.5
    //   32767 represents almost 1.0
    //
    // These coefficients implement a 31-tap low-pass filter
    // with approximately 4 kHz cutoff at 48 kHz sample rate.
    function signed [15:0] coefficient;
        input [4:0] tap_index;
        begin
            case (tap_index)
                5'd0:  coefficient = 16'sd55;
                5'd1:  coefficient = 16'sd58;
                5'd2:  coefficient = 16'sd48;
                5'd3:  coefficient = 16'sd0;
                5'd4:  coefficient = -16'sd110;
                5'd5:  coefficient = -16'sd279;
                5'd6:  coefficient = -16'sd460;
                5'd7:  coefficient = -16'sd554;
                5'd8:  coefficient = -16'sd437;
                5'd9:  coefficient = 16'sd0;
                5'd10: coefficient = 16'sd801;
                5'd11: coefficient = 16'sd1908;
                5'd12: coefficient = 16'sd3161;
                5'd13: coefficient = 16'sd4323;
                5'd14: coefficient = 16'sd5146;
                5'd15: coefficient = 16'sd5444;
                5'd16: coefficient = 16'sd5146;
                5'd17: coefficient = 16'sd4323;
                5'd18: coefficient = 16'sd3161;
                5'd19: coefficient = 16'sd1908;
                5'd20: coefficient = 16'sd801;
                5'd21: coefficient = 16'sd0;
                5'd22: coefficient = -16'sd437;
                5'd23: coefficient = -16'sd554;
                5'd24: coefficient = -16'sd460;
                5'd25: coefficient = -16'sd279;
                5'd26: coefficient = -16'sd110;
                5'd27: coefficient = 16'sd0;
                5'd28: coefficient = 16'sd48;
                5'd29: coefficient = 16'sd58;
                5'd30: coefficient = 16'sd55;

                // Safe default.
                default: coefficient = 16'sd0;
            endcase
        end
    endfunction


    // ========================================================
    // 3. Sample history delay line
    // ========================================================

    // sample_history stores the newest 31 input samples.
    //
    // sample_history[0]  = newest sample, x[n]
    // sample_history[1]  = previous sample, x[n-1]
    // ...
    // sample_history[30] = oldest sample, x[n-30]
    reg signed [15:0] sample_history [0:30];


    // ========================================================
    // 4. Multiply-accumulate hardware
    // ========================================================

    // tap_counter tells us which tap is currently being processed.
    //
    // It counts from 0 to 30.
    reg [4:0] tap_counter = 5'd0;

    // busy means the FIR engine is currently computing one
    // output sample.
    //
    // busy = 0: waiting for a new sample
    // busy = 1: computing the 31 multiply-add operations
    reg busy = 1'b0;

    // accumulator stores the running sum of products.
    //
    // Each product is:
    //   16-bit sample × 16-bit coefficient = 32-bit product
    //
    // The sum of 31 products needs more than 32 bits, so we use
    // a 40-bit signed accumulator for safety.
    reg signed [39:0] accumulator = 40'sd0;

    // Current coefficient selected by tap_counter.
    wire signed [15:0] current_coefficient;
    assign current_coefficient = coefficient(tap_counter);

    // Current sample selected by tap_counter.
    wire signed [15:0] current_sample;
    assign current_sample = sample_history[tap_counter];

    // Product of current sample and current coefficient.
    //
    // 16-bit signed × 16-bit signed gives a 32-bit signed result.
    wire signed [31:0] current_product;
    assign current_product = current_sample * current_coefficient;

    // Sign-extend the 32-bit product to 40 bits before adding it
    // to the 40-bit accumulator.
    wire signed [39:0] current_product_extended;
    assign current_product_extended = {{8{current_product[31]}}, current_product};

    // The next accumulator value after adding the current product.
    wire signed [39:0] next_accumulator;
    assign next_accumulator = accumulator + current_product_extended;

    // After all 31 products are summed, we shift right by 15
    // bits because the coefficients are Q1.15.
    //
    // This converts the result back to normal signed 16-bit
    // audio scale.
    wire signed [39:0] scaled_result;
    assign scaled_result = next_accumulator >>> 15;


    // ========================================================
    // 5. Main filter logic
    // ========================================================

    integer i;

    always @(posedge audio_clk) begin

        if (audio_clk_locked == 1'b0) begin

            // ------------------------------------------------
            // Reset the sample history.
            // ------------------------------------------------
            for (i = 0; i < NUM_TAPS; i = i + 1) begin
                sample_history[i] <= 16'sd0;
            end

            // ------------------------------------------------
            // Reset the computation state.
            // ------------------------------------------------
            tap_counter   <= 5'd0;
            busy          <= 1'b0;
            accumulator   <= 40'sd0;
            output_sample <= 16'sd0;

        end else begin

            // ------------------------------------------------
            // Start a new FIR calculation when a new sample
            // arrives and the FIR engine is not busy.
            //
            // In this project, the FIR finishes in 31 audio
            // clock cycles, and a new sample arrives every 256
            // audio clock cycles. So it should always be ready.
            // ------------------------------------------------
            if ((sample_valid == 1'b1) && (busy == 1'b0)) begin

                // Shift the sample history.
                //
                // The oldest sample is discarded.
                // Every stored sample moves one position older.
                for (i = NUM_TAPS-1; i > 0; i = i - 1) begin
                    sample_history[i] <= sample_history[i-1];
                end

                // Store the newest input sample at position 0.
                sample_history[0] <= input_sample;

                // Prepare to compute the FIR output.
                //
                // The actual multiply-add operations begin on
                // the following audio clock cycle, after the
                // sample history has been updated.
                tap_counter <= 5'd0;
                accumulator <= 40'sd0;
                busy        <= 1'b1;

            end else if (busy == 1'b1) begin

                // ------------------------------------------------
                // Add one tap product into the accumulator.
                //
                // This line performs:
                //
                //   accumulator = accumulator
                //               + sample_history[tap_counter]
                //               * coefficient[tap_counter]
                //
                // One tap is processed per audio clock cycle.
                // ------------------------------------------------
                accumulator <= next_accumulator;

                // ------------------------------------------------
                // If this is the final tap, produce the output.
                // ------------------------------------------------
                if (tap_counter == 5'd30) begin

                    // The full result is wider than 16 bits.
                    // For this beginner project, we simply take
                    // bits [15:0] after scaling.
                    //
                    // Because the coefficients sum to about 1.0
                    // and our input amplitudes are moderate, this
                    // should not overflow in normal use.
                    output_sample <= scaled_result[15:0];

                    // Finish this FIR calculation.
                    busy        <= 1'b0;
                    tap_counter <= 5'd0;

                end else begin

                    // Move to the next tap.
                    tap_counter <= tap_counter + 1'b1;

                end
            end
        end
    end

endmodule
