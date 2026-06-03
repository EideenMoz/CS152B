`timescale 1ns / 1ps
// FIR filter:
// y[n] = h0*x[n] + h1*x[n-1] + ... + h30*x[n-30]

module fir_lowpass_simple (
    input wire audio_clk,
    input wire audio_clk_locked,
    input wire sample_valid,
    input wire signed [15:0] input_sample,

    output reg signed [15:0] output_sample
);
    localparam NUM_TAPS = 31;
    // get auto generated coefficients from Python script
    function signed [15:0] coefficient;
        input [4:0] tap_index;
        begin
            case (tap_index)
                // Pull the calculated filter coefficients textually
                `include "fir_coefficients.vh"
                default: coefficient = 16'sd0;
            endcase
        end
    endfunction


    // sample_history[0]  = newest sample, x[n]
    // sample_history[30] = oldest sample, x[n-30]
    reg signed [15:0] sample_history [0:30];

    //multiply-accumulate 
    reg [4:0] tap_counter = 5'd0;

    // busy means the FIR engine is currently computing one output sample.
    reg busy = 1'b0;

    // accumulator stores the running sum of products. Each product is:
    // 16-bit sample × 16-bit coefficient = 32-bit product
    reg signed [39:0] accumulator = 40'sd0;

    // Current coefficient selected by tap_counter.
    wire signed [15:0] current_coefficient;
    assign current_coefficient = coefficient(tap_counter);

    // Current sample selected by tap_counter.
    wire signed [15:0] current_sample;
    assign current_sample = sample_history[tap_counter];

    // Product of current sample and current coefficient.
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

    // After all 31 products are summed, we shift right by 15 bits because the coefficients are Q1.15.
    // This converts the result back to normal signed 16-bit audio scale.
    wire signed [39:0] scaled_result;
    assign scaled_result = next_accumulator >>> 15;

    //Filter Logic:

    integer i;
    always @(posedge audio_clk) begin

        if (audio_clk_locked == 1'b0) begin
            // RESET
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

                // Store the newest input sample at position 0.
                sample_history[0] <= input_sample;

                // Prepare to compute the FIR output.
                // The actual multiply-add operations begin on
                // the following audio clock cycle, after the
                // sample history has been updated.
                tap_counter <= 5'd0;
                accumulator <= 40'sd0;
                busy        <= 1'b1;

            end else if (busy == 1'b1) begin

                // accumulator = accumulator + sample_history[tap_counter] * coefficient[tap_counter]
                // One tap is processed per audio clock cycle.
                accumulator <= next_accumulator;

                // Output if final tap
                if (tap_counter == 5'd30) begin
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
