module mux2_1_16bit (
  output wire [15:0] out,       // 16-bit output line
  input wire [15:0] a,          // 16-bit input A
  input wire [15:0] b,          // 16-bit input B
  input wire sel               // 1-bit selector for a 2:1 MUX
);
  genvar i;
  generate
    for (i=0; i<16; i=i+1) begin : MUX2_1_16
      mux2_1(out[i], a[i], b[i], sel);      // Out = A if sel is 0 else B
    end
  endgenerate
endmodule
    
