module tb();
reg clk;
reg rst;
reg send;
reg [7:0] data;
wire tx_line;

tx transmitter(
    .clk(clk),
    .rst(rst),
    .send(send),
    .data(data),
    .tx_line(tx_line)
);

initial clk=0;
always #5 clk = ~clk; 

initial begin
    rst=1;
    send=0;
    #100;
    rst=0;
    data=8'b10101010;
    send=1;
    #15;
    send=0;
end

endmodule
