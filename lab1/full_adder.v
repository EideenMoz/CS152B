module full_adder (
    output sum,
    output cout,
    input  wire a,
    input  wire b,
    input  wire cin
);
    wire axb, w1, w2;
    xor (axb, a, b);
    xor (sum, axb, cin);
    and (w1, a, b);
    and (w2, axb, cin);
    or  (cout, w1, w2);
endmodule