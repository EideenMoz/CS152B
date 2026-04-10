module mux8_1_16bit (
  output wire [15:0] out, 
  input wire [15:0] in0, in1, in2, in3, in4, in5, in6, in7,
  inout wire [2:0] sel
);
  wire [15:0] low_four, high_four;

  // First stage: Two 4:1 Muxes using lower bits sel[1:0]
  mux4_1_16bit m0(low_four, in0, in1, in2, in3, sel[1:0]);
  mux4_1_16bit m1(high_four, in4, in5, in6, in7, sel[1:0]);

  // Second stage: One 2:1 Mux using MSB sel[2]
  mux2_1_16bit m2(out, low_four, high_four, sel[2]);
endmodule
