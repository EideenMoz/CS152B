module set_less_than_equal (
    input [15:0] a,
    input [15:0] b,
    output [15:0] out
);

// both have same signs
wire compare;
wire same_sign;
xor(compare, a[15], b[15]);
not(same_sign, compare);

//if different signs, a is less than b if a is negative
wire negative_a;
assign negative_a = a[15];

//check subtraction
wire [15:0] difference;
wire zero;
wire negative_difference;
wire zero_or_negative;
assign negative_difference = difference[15];
or(zero_or_negative, zero, negative_difference);


zero_flag zero_diff (
    .result(difference),
    .zero(zero)
);
//no overflow in same sign case
subtract16 sub (
    .out(difference),
    .a(a),
    .b(b)
);

//choose output based on subtraction or different signs
wire one_bit_out;
mux2_1 mux(
    .y(one_bit_out),
    .a(negative_a), //S=0
    .b(zero_or_negative), //S=1
    .s(same_sign)
);

assign out = {15'b000000000000000, one_bit_out};

endmodule 