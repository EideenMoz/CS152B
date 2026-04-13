`timescale 1ns / 1ps
module ALU_top(
    input  wire [15:0] a,
    input  wire [15:0] b,
    input wire [3:0] ALU_ctrl,
    output wire [15:0] result,
    output wire zero,
    output wire overflow
);
    //===Addition===\\
    wire [15:0] result_sum;
    wire [15:0] overflow_sum;

    addition16 add (
        .sum(result_sum),
        .overflow(overflow_sum),
        .a(a),
        .b(b)
    );

    //===Subtraction===\\
    wire [15:0] result_sub;
    wire [15:0] overflow_sub;

    subtract16 sub (
        .out(result_sub),
        .overflow(overflow_sub),
        .a(a),
        .b(b)
    );

    //===Increment===\\
    wire [15:0] result_inc;
    wire [15:0] overflow_inc;

    increment16 inc (
        .out(result_inc),
        .overflow(overflow_inc),
        .in(a)
    );

    //===Decrement===\\
    wire [15:0] result_dec;
    wire [15:0] overflow_dec;

    decrement16 dec (
        .out(result_dec),
        .overflow(overflow_dec),
        .in(a)
    );

    //===Invert===\\
    //Same as multiplying by -1 (not bitwise NOT)
    wire [15:0] result_inv;
    wire [15:0] overflow_inv;

    invert16 inv (
        .a(a),
        .y(result_inv),
        .overflow(overflow_inv)
    );

    //===Bitwise AND===\\
    wire [15:0] result_and;

    and16 bit_and(
        .y(result_and),
        .a(a),
        .b(b)
    );

    //===Bitwise OR===\\
    wire [15:0] result_or;

    or16 bit_or(
        .y(result_or),
        .a(a),
        .b(b)
    );

    //===Zero Flag===\\
    zero_flag zf(
        .result(result),
        .zero(zero)
    );

    //===Shifts===\\
    wore [15:0] result_shift;
    wire overflow_shift;
    alu_shifter_unit shifter (
        .out(result_shift),
        .overflow(overflow_shift),
        .a(a),
        .b(b),
        .opcode(ALU_ctrl) // Use lower 2 bits of ALU_ctrl for shift type
    );

    //===Set less than equal===\\
    wire [15:0] result_sle;
    set_less_than_equal sle (
        .a(a),
        .b(b),
        .out(result_sle)
    );

    //===Result and overflow muxes===\\
    mux16_1_16bit mux (
        .out(result),
        .in0(result_sub),
        .in1(result_sum),
        .in2(result_or),
        .in3(result_and),
        .in4(result_dec),  
        .in5(result_inc),  
        .in6(result_inv),
        .in7(0),      
        .in8(result_shift), 
        .in9(result_sle),       
        .in10(result_shift),      
        .in11(0), 
        .in12(result_shift),   
        .in13(0),  
        .in14(result_shift), 
        .in15(0),  
        .sel(ALU_ctrl)
    );
    mux16_1_16bit overflow_mux (
        .out(overflow),
        .in0(overflow_sub),
        .in1(overflow_sum),
        .in2(0), //no overflow for bitwise OR
        .in3(0), //no overflow for bitwise AND
        .in4(overflow_dec),  
        .in5(overflow_inc),  
        .in6(overflow_inv),
        .in7(0),      
        .in8(0), 
        .in9(0),       
        .in10(0),      
        .in11(0), 
        .in12(0),   
        .in13(0),  
        .in14(0), 
        .in15(0),  
        .sel(ALU_ctrl)
    );
    
endmodule
