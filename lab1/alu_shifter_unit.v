module alu_shifter_unit(
  output wire [15:0] out,
  output wire overflow,
  input wire [15:0] a,         // Data to shift
  input wire [15:0] b,         // b[3:0] is shift amount (check if any bits in b[15:4] are set)
  input wire [3:0] opcode     // 1100: ASL, 1110: ASR, 1000: LSL, 1010: LSR
);

  wire is_right, is_arith, fill_bit, use_sign_extension;
  wire [15:0] prepared_in, shifted_raw;

  // Decode opcode
  assign is_arith = opcode[2];    // bit 2: 0=Logic, 1=Arith
  assign is_right = opcode[1];    // bit 1: 0=Left, 1=Right

  // Sign extension is ONLY for Arithmetic AND Right shifts (ASR).
  // ASL, LSL, and LSR all shift in zeros.
  and g_fill_check (use_sign_extension, is_arith, is_right);
  mux2_1 fselect (fill_bit, 1'b0, a[15], use_sign_extension);

  // Pre-reverse for left shift (so we can use our right shift core logic)
  // We reverse if is_right=0
  // prepared_in is our input to the right shifter (derived from input a)
  wire should_reverse;
  not(should_reverse, is_right);
  bit_reverser_16 pre_rev (prepared_in, a, should_reverse);

  // Barrel Shifter Core (handles 0-15)
  // We pass b[3:0] directly to the core
  barrel_core_16 core (shifter_out_raw, prepared_in, b[3:0], fill_bit);

  // Perform right shift
  // if b > d'15:
  //    shift_amount=16
  // else: shift_amount=b[3:0]
  wire b_gt_15; // Structural OR reduction of b[15:4]
  or g_or_upper (b_gt_15, b[4], b[5], b[6], b[7], b[8], b[9], b[10], b[11], b[12], b[13], b[14], b[15]);

 // Create a vector of all fill bits (e.g., all 0s or all 1s)
  assign all_fill = {16{fill_bit}};
  // If b_gt_15 is true, result is all_fill; else it is the core output
  mux2_1_16bit saturation_mux (shifted_saturated, shifter_out_raw, all_fill, b_gt_15);

  // Post-shift-reverse (handle case when opcode specifies left shift)
  bit_reverser_16 post_rev (out, shifted_raw, should_reverse);

  wire arithmetic_overflow;
  xor(arithmetic_overflow, a[15], out[15]); // Overflow if MSB changes during an arithmetic shift
  and(overflow, is_arith, arithmetic_overflow); // Only consider overflow for arithmetic shifts
endmodule
  

  
  

  

  
  
  
  
