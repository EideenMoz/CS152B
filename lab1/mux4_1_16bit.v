module mux4_1_16bit (
  output wire [15:0] out,
  input wire [15:0] in0, in1, in2, in3,
  input wire [1:0] sel
);
  wire [15:0] mux_low, mux_high;

  // First stage: Select one element from each of the sets (in0,in1), (in2,in3)
  mux2_1_16bit(mux_low, in0, in1, sel[0]);     // Check LSB of I0 and I1
  mux2_1_16bit(mux_high, in2, in3, sel[0]);    // Check LSB of I2 and I3

  // Second stage: Look at MSB
  mux2_1_16bit(out, mux_low, mux_high, sel[1]);
endmodule
  
  
