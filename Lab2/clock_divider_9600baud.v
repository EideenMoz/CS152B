module clock_divider_9600baud(
    input wire clk,    // Basys3 100 MHz
    input wire rst,
    output reg clk_9600    // Toggles at 9600 Hz
    );
    
    reg [31:0] clock_div_reg = 0;
    // 100 * 10^6 / 9600 / 2
    localparam clock_count = 5208;
       
    always @(posedge clk or posedge rst) begin
        if(rst) begin
            clock_div_reg <= 32'd0;
            clk_9600 <= 1'b0;
        end else begin
            if(clock_div_reg > clock_count) begin
                clk_9600 <= ~clk_9600;
                clock_div_reg <= 32'd0;
            end else begin
                clock_div_reg <= clock_div_reg + 1;
            end
        end
    end
endmodule
