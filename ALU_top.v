`timescale 1ns / 1ps
module ALU_top(
    input  wire [15:0] a,
    input  wire [15:0] b,
    input wire [3:0] ALU_ctrl,
    output wire [15:0] result,
    output wire zero,
    output wire overflow
);
    //temp for tb to work
    reg [15:0] result_reg;
    reg inverted_b;
    assign result = result_reg;
    reg subtract;
    initial subtract=0;
    assign overflow = subtract ? overflow_sub : overflow_sum;

    //===Addition===\\
    wire [15:0] result_sum;
    wire [15:0] overflow_sum;
    addition16 add (
        .sum(result_sum),
        .overflow(overflow_sum),
        .a(a),
        .b(b),
        .cin(0)
    );

    //===Subtraction===\\
    wire [15:0] result_sub;
    wire [15:0] overflow_sub;
    addition16 sub (
        .sum(result_sub),
        .overflow(overflow_sub),
        .a(a),
        .b(inverted_b),
        .cin(1)
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

    always @(*) begin
        // Default values

        case(ALU_ctrl)
            4'h0: begin 
                result_reg = result_sub;    //sub
                subtract=1;
            end
            4'h1: result_reg = result_sum;    //add
            4'h2: result_reg = result_or; // OR
            4'h3: result_reg = result_and;  // AND
            4'h4: result_reg = a ^ b;      // XOR (example)
            4'h5: result_reg = ~a;         // NOT A
            4'h6: result_reg = a << 1;     // Shift left
            4'h7: result_reg = a >> 1;     // Shift right logical
            4'h8: result_reg = $signed(a) >>> 1; // Shift right arithmetic
            4'h9: result_reg = a + 1;      // Increment
            4'hA: result_reg = a - 1;      // Decrement
            4'hB: result_reg = {a[7:0], b[7:0]}; // Example concatenation
            4'hC: result_reg = a & ~b;     // AND-NOT
            4'hD: result_reg = a | ~b;     // OR-NOT
            4'hE: result_reg = ~(a | b);   // NOR
            4'hF: result_reg = ~(a & b);   // NAND
            default: result_reg = 16'h0000;
        endcase
    end
endmodule
