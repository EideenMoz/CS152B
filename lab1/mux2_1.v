module mux2_1 (
    output wire y,
    input wire a,
    input wire b,
    input wire s
);
    wire ns, w1, w2;
    not (ns, s);
    and (w1, a, ns);
    and (w2, b, s);
    or  (y, w1, w2);
endmodule