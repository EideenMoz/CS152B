module alu_shifter_unit(
  output wire [15:0] out,
  output wire overflow,
  input wire [15:0] a,         // Data to shift
  input wire [15:0] b,         // b[3:0] is shift amount (check if any bits in b[15:4] are set)
  input wire [3:0] opcode     // 1100: ASL, 1110: ASR, 1000: LSL, 1010: LSR
);
  wire is_right, is_arith, fill_bit;
  wire [15:0] prepared_in, shifted_raw;

  // Decode opcode
  assign is_arith = opcode[1];    // bit 2: 0=Logic, 1=Arith
  assign is_right = opcode[2];    // bit 1: 0=Left, 1=Right

  // Determine the fill bit (logical:0, arith=a[15])
  mux2_1 fselect (fill_bit, 1'b0, a[15], is_arith);

  // Pre-reverse for left shift (so we can use our right shift core logic)
  // We reverse if is_right=0
  // prepared_in is our input to the right shifter (derived from input a)
  wire should_reverse;
  not(should_reverse, is_right);
  bit_reverser_16 pre_rev (prepared_in, a, should_reverse);

  // Perform right shift
  // if b > d'15:
  //    shift_amount=16
  // else: shift_amount=b[3:0]
  wire b_gt_15; // Structural OR reduction of b[15:4]
  or g_or_upper (b_gt_15, b[4], b[5], b[6], b[7], b[8], b[9], b[10], b[11], b[12], b[13], b[14], b[15]);
  wire [3:0] final_shift_amt;
  // For each bit of the shift amount:
  // If b_gt_15 is 1, output is 1 (from 4'b1111).
  // If b_gt_15 is 0, output is b[i].
  mux2_1 m0 (final_shift_amt[0], b[0], 1'b1, b_gt_15);
  mux2_1 m1 (final_shift_amt[1], b[1], 1'b1, b_gt_15);
  mux2_1 m2 (final_shift_amt[2], b[2], 1'b1, b_gt_15);
  mux2_1 m3 (final_shift_amt[3], b[3], 1'b1, b_gt_15);
  barrel_core_16 core (shifted_raw, prepared_in, final_shift_amt, fill_bit);

  // Post-shift-reverse (handle case when opcode specifies left shift)
  bit_reverser_16 post_rev (out, shifted_raw, should_reverse);

  wire arithmetic_overflow;
  xor(arithmetic_overflow, a[15], out[15]); // Overflow if MSB changes during an arithmetic shift
  and(overflow, is_arith, arithmetic_overflow); // Only consider overflow for arithmetic shifts
endmodule
  

  
  

  

  
  
  
  
