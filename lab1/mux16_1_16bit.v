module mux16_1_16bit (
  output wire [15:0] out,
  input wire [15:0] in0, in1, in2, in3, in4, in5, in6, in7, in8,
  input wire [15:0] in8, in9, in10, in11, in12, in13, in14, in15,
  input wire [3:0] sel
);
  wire [15:0] low_eight, high_eight;

  // First stage: Two 8:1 Muxes using lower bits sel[2:0]
  mux8_1_16bit(low_eight, in0, in1, in2, in3, in4, in5, in6, in7, sel[2:0]);
  mux8_1_16bit(high_eight, in8, in9, in10, in11, in12, in13, in14, in15, sel[2:0]);

  // Second stage: One 2:1 Mux using MSB sel[3]
  mux2_1_16bit(out, low_eight, high_eight, sel[3]);
endmodule
