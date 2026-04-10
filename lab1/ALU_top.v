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
    // always @(*) begin
    //     // Default values

    //     case(ALU_ctrl)
    //         4'h0: begin 
    //             result_reg = result_sub;    //sub
    //             overflow_reg = overflow_sub;
    //         end
    //         4'h1: begin
    //             result_reg = result_sum;    //add
    //             overflow_reg = overflow_sum;
    //         end
    //         4'h2: begin
    //             result_reg = result_or; // OR
    //             overflow_reg = 1'b0;
    //         end
    //         4'h3: begin
    //             result_reg = result_and;  // AND
    //             overflow_reg = 1'b0;
    //         end
    //         4'h4: begin
    //             result_reg = result_dec;      // decrement
    //             overflow_reg = overflow_dec;
    //         end
    //         4'h5: begin
    //             result_reg = result_inc;         // increment
    //             overflow_reg = overflow_inc;
    //         end
    //         4'h6: begin
    //             result_reg = result_inv;     // invert
    //             overflow_reg = overflow_inv; 
    //         end
    //         4'h7: result_reg = a << 1; // Shift left logical
    //         4'h8: result_reg = $signed(a) >>> 1; // Shift right arithmetic
    //         4'h9: result_reg = a + 1;      // Increment
    //         4'hA: result_reg = a - 1;      // Decrement
    //         4'hB: result_reg = {a[7:0], b[7:0]}; // Example concatenation
    //         4'hC: result_reg = a & ~b;     // AND-NOT
    //         4'hD: result_reg = a | ~b;     // OR-NOT
    //         4'hE: result_reg = ~(a | b);   // NOR
    //         4'hF: result_reg = ~(a & b);   // NAND
    //         default: result_reg = 16'h0000;
    //     endcase
    // end
endmodule
