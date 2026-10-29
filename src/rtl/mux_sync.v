module mux_sync(
    input wire clkA, rstnA, clkB, rstnB,
    input wire ena,
    input wire [127:0] Din,
    output wire [127:0] Dout
);

wire W1;
reg [127:0] W2;

DFF #(.ADDR_WIDTH(1)) inst2(.clk(clkA), .rstn(rstnA), .Din(ena), .Q(W1)); 

ff2_sync #(.ADDR_WIDTH(1)) U1 (.clk(clkB), .rstn(rstnB), .Din(W1), .Syn_out(ena_sync));

always @ (*) begin
    if(ena_sync)
        W2 = Din;
    else
        W2 = Dout;
end

DFF #(.ADDR_WIDTH(128)) inst3(.clk(clkB), .rstn(rstnB), .Din(W2), .Q(Dout)); 

endmodule

