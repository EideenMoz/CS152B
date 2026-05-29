`timescale 1ns / 1ps

module pmodmic_reader (
    input  wire        clk_100mhz,
    input  wire        reset,

    input  wire        mic_miso,
    output reg         mic_ss,
    output reg         mic_sck,

    output reg [11:0]  sample,
    output reg         sample_ready
);

    // 100 MHz / (2 * 4) = 12.5 MHz SCK.
    // This matches the clock rate used by Digilent's old 50 MHz reference component,
    // which divided 50 MHz down to 12.5 MHz.
    localparam integer SCK_HALF_PERIOD_CLKS = 4;

    // Approximate audio-rate sampling.
    // 100 MHz / 2048 = 48.828 kHz.
    // Exact 48 kHz is not needed for this bring-up test.
    localparam integer SAMPLE_PERIOD_CLKS = 2048;

    localparam ST_IDLE      = 2'd0;
    localparam ST_SCK_LOW   = 2'd1;
    localparam ST_SCK_HIGH  = 2'd2;

    reg [1:0]  state = ST_IDLE;
    reg [2:0]  half_count = 3'd0;
    reg [4:0]  bit_count = 5'd0;
    reg [15:0] shift_reg = 16'd0;
    reg [11:0] sample_timer = 12'd0;

    wire sample_tick = (sample_timer == SAMPLE_PERIOD_CLKS - 1);

    always @(posedge clk_100mhz or posedge reset) begin
        if (reset) begin
            state        <= ST_IDLE;
            half_count   <= 3'd0;
            bit_count    <= 5'd0;
            shift_reg    <= 16'd0;
            sample       <= 12'd0;
            sample_ready <= 1'b0;
            sample_timer <= 12'd0;
            mic_ss       <= 1'b1;
            mic_sck      <= 1'b1;
        end else begin
            sample_ready <= 1'b0;

            case (state)
                ST_IDLE: begin
                    mic_ss     <= 1'b1;
                    mic_sck    <= 1'b1;
                    half_count <= 3'd0;
                    bit_count  <= 5'd0;

                    if (sample_tick) begin
                        sample_timer <= 12'd0;

                        // Begin a new ADC frame.
                        // Hold SCK high when CS falls so the first falling edge is clean.
                        mic_ss    <= 1'b0;
                        mic_sck   <= 1'b1;
                        shift_reg <= 16'd0;
                        state     <= ST_SCK_LOW;
                    end else begin
                        sample_timer <= sample_timer + 1'b1;
                    end
                end

                ST_SCK_LOW: begin
                    if (half_count == SCK_HALF_PERIOD_CLKS - 1) begin
                        half_count <= 3'd0;
                        mic_sck    <= 1'b0;
                        state      <= ST_SCK_HIGH;
                    end else begin
                        half_count <= half_count + 1'b1;
                    end
                end

                ST_SCK_HIGH: begin
                    if (half_count == SCK_HALF_PERIOD_CLKS - 1) begin
                        half_count <= 3'd0;
                        mic_sck    <= 1'b1;

                        // ADC changes data after SCK falling edge.
                        // Sample it on the following rising edge.
                        if (bit_count == 5'd15) begin
                            sample       <= {shift_reg[10:0], mic_miso};
                            sample_ready <= 1'b1;
                            mic_ss       <= 1'b1;
                            state        <= ST_IDLE;
                        end else begin
                            shift_reg <= {shift_reg[14:0], mic_miso};
                            bit_count <= bit_count + 1'b1;
                            state     <= ST_SCK_LOW;
                        end
                    end else begin
                        half_count <= half_count + 1'b1;
                    end
                end

                default: begin
                    state   <= ST_IDLE;
                    mic_ss  <= 1'b1;
                    mic_sck <= 1'b1;
                end
            endcase
        end
    end

endmodule
