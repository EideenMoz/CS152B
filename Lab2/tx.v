module tx (
    input clk,
    input rst,
    input [7:0] data,
    output reg tx_line
);
// This should output START (0) - DATA {8 bits} - STOP (1) over tx_line in 10 clock cycles. 
# define IDLE 0
# define SEND_DATA 1
reg state;

always @(posedge clk or posedge rst) begin
    if (rst) begin
        state <= IDLE;
    end 
    else begin 
        case (state)
            IDLE: begin
                tx_line <= 0; // START bit
                state <= SEND_DATA;
            end
            SEND_DATA: begin
                ;
            end
        endcase
    end
end
endmodule