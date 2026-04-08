module addition16(
    output [15:0] sum,
    output        cout,
    output        overflow,
    input  wire [15:0] a,
    input  wire [15:0] b,
    input  wire       cin
);
    wire [16:0] c;
    assign c[0] = cin;

    genvar i;
    generate
        for (i = 0; i < 16; i = i + 1) begin : ADDSTAGE
            full_adder fa(sum[i], c[i+1], a[i], b[i], c[i]);
        end
    endgenerate

    assign cout = c[16];
    xor (overflow, c[15], c[16]);
endmodule