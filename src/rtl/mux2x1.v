module mux2x1(
    input wire A, B, sel,
    output wire Y
);
assign Y = sel ? A : B;

endmodule