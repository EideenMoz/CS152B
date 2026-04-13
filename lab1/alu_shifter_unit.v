module alu_shifter_unit(
  output wire [15:0] out,
  input wire [15:0] A,         // Data to shift
  input wire [15:0] B,         // B[3:0] is shift amount (check if any bits in B[15:4] are set)
  input wire [3:0] opcode,     // 1100: ASL, 1110: ASR, 1000: LSL, 1010: LSR
);
  wire is_right, is_arith, fill_bit;
  wire [15:0] prepared_in, shifted_raw;

  // Decode opcode
  assign is_arith = opcode[1];    // bit 2: 0=Logic, 1=Arith
  assign is_right = opcode[2];    // bit 1: 0=Left, 1=Right

  // Determine the fill bit (logical:0, arith=A[15])
  mux2_1 fselect (fill_bit, 1'b0, A[15], is_arith);

  // Pre-reverse for left shift (so we can use our right shift core logic)
  // We reverse if is_right=0
  // prepared_in is our input to the right shifter (derived from input A)
  wire should_reverse;
  not(should_reverse, is_right);
  bit_reverser_16 pre_rev (prepared_in, A, should_reverse);

  // Perform right shift
  // if B > d'15:
  //    shift_amount=16
  // else: shift_amount=B[3:0]
  barrel_core_16 core (shifted_raw, prepared_in, B[3:0], fill_bit);

  // Post-shift-reverse (handle case when opcode specifies left shift)
  bit_reverser_16 post_rev (out, shifted_raw, should_reverse);
endmodule
  

  
  

  

  
  
  
  
