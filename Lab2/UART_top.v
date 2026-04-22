module UART_top(
    input clk,
    input rst,
    input send,
    input [7:0] write_data,
    input rx_line,
    output tx_line,
    output [7:0] receiver_data,
    output done
);

rx receiver (
    .clk(baud_rate_clk),
    .rst(rst),
    .rx_line(rx_line),
    .data(receiver_data),
    .done(done)
);

tx transmitter (
    .clk(baud_rate_clk),
    .rst(rst),
    .send(send),
    .data(write_data),
    .tx_line(tx_line)
);
endmodule