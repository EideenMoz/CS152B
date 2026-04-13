// This module implements a 16-bit barrel logical/arithmetic (determined by fill bit) RIGHT SHIFTER.
module barrel_core_16 (
  output wire [15:0] out,
  input wire [15:0] in,
  input wire [3:0] amt,
  input wire fill
);
  wire [15:0] s0, s1, s2;

  // Stage 0: Shift 1
  mux2_1_16bit st0 (s0, in, {fill, in[15:1]}, amt[0]);
  // Stage 1: Shift 2
  mux2_1_16bit st1 (s1, s0, {{2{fill}}, s0[15:2]}, amt[1]);
  // Stage 2: Shift 4
  mux2_1_16bit st2 (s2, s1, {{4{fill}}, s1[15:4]}, amt[2]);
  // Stage 3: Shift 8
  mux2_1_16bit st3 (out, s2, {{8{fill}}, s2[15:8]}, amt[3]);
endmodule
  
