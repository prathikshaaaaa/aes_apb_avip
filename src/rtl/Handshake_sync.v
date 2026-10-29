module Handshake_sync(
    input wire clkA, clkB, rstnA, rstnB,
    input wire Din,
    output wire Sync_out, Busy
);

ff2_sync #(.ADDR_WIDTH(1)) U1 (.clk(clkA), .rstn(rstnA), .Din(W6), .Syn_out(W1));
mux2x1 U2(.A(0), .B(W4), .sel(W1), .Y(W2));
mux2x1 U3(.A(1), .B(W2), .sel(Din), .Y(W3));
DFF #(.ADDR_WIDTH(1)) inst1(.clk(clkA), .rstn(rstnA), .Din(W3), .Q(W4));

DFF #(.ADDR_WIDTH(1)) inst2(.clk(clkB), .rstn(rstnB), .Din(W4), .Q(W5));
DFF #(.ADDR_WIDTH(1)) inst3(.clk(clkB), .rstn(rstnB), .Din(W5), .Q(W6));
DFF #(.ADDR_WIDTH(1)) inst4(.clk(clkB), .rstn(rstnB), .Din(W6), .Q(W7));

assign Sync_out = ~W7 & W6;
assign Busy = W4 | W1;

endmodule