module UART_top(
    input clk,
    input rst,
    input send,
    input [7:0] write_data,
    input rx_line,
    output tx_line,
    output reg [7:0] receiver_data
);
wire done;
wire temp_receiver_data;

rx receiver (
    .clk(baud_rate_clk),
    .rst(rst),
    .rx_line(rx_line),
    .data(temp_receiver_data),
    .done(done)
);

tx transmitter (
    .clk(baud_rate_clk),
    .rst(rst),
    .send(send),
    .data(write_data),
    .tx_line(tx_line)
);

clock_divider_9600baud baud_rate_gen (
    .clk(clk),
    .rst(rst),
    .clk_9600(baud_rate_clk)
);

always @(*) begin
    if (done) begin
        receiver_data = temp_receiver_data;
    end else begin
        receiver_data = 8'b0;
    end
end
endmodule