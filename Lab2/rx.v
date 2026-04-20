module rx (
    input clk,
    input rst,
    input rx_line,
    output reg [7:0] data
);
//This reads a START bit (0), then 8 bits of data, then a STOP bit (1) from rx_line in 10 clock cycles.
//We need to implement error checking


endmodule