`timescale 1ns / 1ps

module pmod_mic_spi (
    input  wire         mclk,         // 12.288 MHz clock for internal logic stability
    input  wire         reset,        // System reset
    input  wire         i2s_sck,      // 3.072 MHz clock (will be forwarded to mic_sck)
    input  wire         i2s_lrck,     // 48 kHz clock to trigger the start of conversion

    // Physical Pmod MIC Connections
    input  wire         mic_miso,     // Raw data from Mic (Pin 3)

    // Signals to control the Pmod MIC
    output reg          mic_ss = 1'b1,// Chip Select (Pin 1) - Active Low
    output wire         mic_sck,      // Clock to Mic (Pin 4)
    
    // Output audio Data 
    output reg [11:0]   audio_sample = 12'd0,
    output reg          sample_ready = 1'b0
);

    //states
    localparam IDLE   = 1'b0;
    localparam ACTIVE = 1'b1;
    
    reg state = IDLE;

    // Edge-detection to capture when LRCK changes state (48,000 times a second per channel)
    reg lrck_delay = 1'b0;
    wire start_conversion;
    
    always @(posedge mclk or posedge reset) begin
        if (reset) begin
            lrck_delay <= 1'b0;
        end else begin
            lrck_delay <= i2s_lrck;
        end
    end

    // Detect when lrck clock changes state (0-->1 or 1-->0)
    assign start_conversion = (i2s_lrck != lrck_delay);

    // =========================================================================
    // Internal Registers & SCK Edge Detection
    // =========================================================================
    reg        sck_gate    = 1'b0; // Gates the output clock so it only runs for 16 cycles
    reg [4:0]  bit_count   = 5'd0; // Counts 0 to 16 cycles
    reg [15:0] shift_reg   = 16'd0;
    
    // Create an edge detector for the serial bit clock (i2s_sck)
    reg sck_delay = 1'b0;
    wire sck_rising_edge;
    wire sck_falling_edge;
    
    always @(posedge mclk) begin
        sck_delay <= i2s_sck;
    end
    assign sck_rising_edge  = (i2s_sck && !sck_delay);
    assign sck_falling_edge = (!i2s_sck && sck_delay);

    // Only drive mic_sck when we are actively reading a 16-bit word
    assign mic_sck = (sck_gate) ? i2s_sck : 1'b1;

    //state logic
    always @(posedge mclk or posedge reset) begin
        if (reset) begin
            state        <= IDLE;
            mic_ss       <= 1'b1;
            sck_gate     <= 1'b0;
            bit_count    <= 5'd0;
            shift_reg    <= 16'd0;
            audio_sample <= 12'd0;
            sample_ready <= 1'b0;
        end 
        else begin
            sample_ready <= 1'b0; // Default pulse length of 1 mclk cycle
            
            case (state)
                IDLE: begin
                    // Waiting for a new audio sample frame to drop
                    if (start_conversion) begin
                        mic_ss    <= 1'b0; // Pull Chip Select LOW to wake up ADC
                        sck_gate  <= 1'b1; // Open clock gate
                        bit_count <= 5'd0;
                        state     <= ACTIVE; // Jump to active state
                    end
                end 
                
                ACTIVE: begin
                    // Currently running through the 16 SPI clock cycles
                    if (sck_rising_edge) begin
                        // Shift in MISO data on the rising edge
                        shift_reg <= {shift_reg[14:0], mic_miso};
                        bit_count <= bit_count + 1'b1;
                    end
                    
                    // On the 16th falling edge, finalize transaction
                    if (bit_count == 5'd16 && sck_falling_edge) begin
                        mic_ss       <= 1'b1; // Put ADC back to sleep
                        sck_gate     <= 1'b0; // Close clock gate
                        
                        // Shift the window up by 1 bit to fix alignment
                        audio_sample <= {shift_reg[10:0], 1'b0}; 
                        
                        sample_ready <= 1'b1; // Alert the next module that data is finished
                        state        <= IDLE; // Return to idle state
                    end
                end

            // Failsafe catch to prevent latch-ups in hardware
            default: state <= IDLE;
            endcase
        end
    end

endmodule