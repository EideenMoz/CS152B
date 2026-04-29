module rx (
    input clk,
    input rst,
    input rx_line,
    output reg [7:0] data,
    output reg done,
    output reg error
);
//This reads a START bit (0), then 8 bits of data, then a STOP bit (1) from rx_line in 10 clock cycles.
//We need to implement error checking

localparam IDLE      = 0;
localparam READ_DATA = 1;
localparam STOP_BIT  = 2;

reg [1:0] state, next_state;
reg [2:0] position;

// next-state logic
always @(*) begin
    case (state)
        IDLE: begin
            if (rx_line == 0)
                next_state = READ_DATA;   // saw start bit
            else
                next_state = IDLE;
        end

        READ_DATA: begin
            if (position == 7)
                next_state = STOP_BIT;
            else
                next_state = READ_DATA;
        end

        STOP_BIT: begin
            next_state = IDLE;
        end

        default: next_state = IDLE;
    endcase
end

// state + datapath
always @(posedge clk or posedge rst) begin
    if (rst) begin
        state    <= IDLE;
        position <= 3'd0;
        data     <= 8'd0;
        done     <= 1'b0;
        error    <= 1'b0;
    end
    else begin
        state <= next_state;

        // default pulse behavior
        error <= 1'b0;

        case (state)
            IDLE: begin
                position <= 3'd0;
            end

            READ_DATA: begin
                done <=0; 
                data[position] <= rx_line;   // LSB first
                if (position < 3'd7)
                    position <= position + 1'b1;
            end

            STOP_BIT: begin
                if (rx_line == 1'b1) begin
                    done <= 1'b1;           // valid byte received
                end
                else begin
                    error <= 1'b1;          // invalid stop bit
                end
                position <= 3'd0;
            end
        endcase
    end
end

endmodule
