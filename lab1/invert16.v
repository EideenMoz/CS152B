module invert16(
    input wire [15:0] a,
    output wire [15:0] y,
    output overflow
)

    genvar i;
    generate
        for(i = 0; i < 15; i = i + 1) begin : invert
            not (y[i], a[i]);
        end
    end generate
endmodule