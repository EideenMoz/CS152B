module and16(
  output [15:0] y,
  input  wire [15:0] a,
  input  wire [15:0] b
);
  genvar i;
  generate
    for (i = 0; i < 16; i = i + 1) begin : ANDBITS
      and (y[i], a[i], b[i]);
    end
  endgenerate
endmodule
