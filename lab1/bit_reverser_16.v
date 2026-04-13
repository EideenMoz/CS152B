// Helper module for alu_shifter_unit. The barrel_core_16 only implements right shift.
// To implement a left shift using only operations of right shift and reverse available, 
// first apply the reverse operation, then apply the right shift operation, then apply the reverse operation again.
module bit_reverser_16 (
  output wire [15:0] out,
  input wire [15:0] in,
  input wire reverse    // Reverse "in" if reverse = 1 else do nothing
);
  genvar i;
  generate
    for (i=0; i<16; i=i+1) begin : REV_ARRAY
      mux2_1 m (out[i], in[1], in[15-i], reverse);    // out[i]<--in[i] if reverse==0 else out[i]=in[15-i]
    end
  endgenerate
endmodule
      
