module tx (
    input clk,
    input rst,
    input send,     //not on spec, but ig we need some way to leave idle state
    input [7:0] data,
    output reg tx_line
);
// This should output START (0) - DATA {8 bits} - STOP (1) over tx_line in 10 clock cycles after send is set to 1. 
localparam IDLE = 0;
localparam SEND_DATA = 1;

reg state;
reg next_state;
reg [3:0] position; 


//next state logic
always @(*) begin
    case (state) 
        IDLE: begin
            if (send)
                next_state = SEND_DATA;
            else
                next_state = IDLE;
        end
        SEND_DATA: begin
            if (position == 8)
                next_state = IDLE;
            else
                next_state = SEND_DATA;
        end
    endcase
end

//logic for each state
always @(posedge clk or posedge rst) begin
    if (rst) begin
        tx_line <= 1; // Idle state is high
        position <= 0;
    end 
    else begin 
        case (state)
            IDLE: begin
                if (next_state == SEND_DATA) //if send=1 (but next_state is combinational so we check that instead)
                    tx_line <= 0; // Start bit
                else
                    tx_line <= 1; // Idle
            end
            SEND_DATA: begin
                if (position < 8) begin
                    tx_line <= data[position];
                    position <= position + 1;
                end else begin 
                    tx_line <= 1; // Stop bit
                    position <= 0;  
                end
            end
        endcase
    end
end

//update state
always @(posedge clk or posedge rst) begin
    if (rst)
        state <= IDLE;
    else
        state <= next_state;
end
endmodule