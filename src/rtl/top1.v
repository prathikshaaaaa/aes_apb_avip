module top1(
    input  wire        PCLK,
    input  wire        PRESETn,
    input  wire        crypto_clk, 
    input  wire        crypto_rstn,
    input  wire [7:0]  PADDR,
    input  wire        PSEL,
    input  wire        PENABLE,
    input  wire        PWRITE,
    input  wire [31:0] PWDATA,
    input  wire [2:0]  PPROT,

    output wire          SEC_VIOLATION,
    output wire          PSLVERR,
    output wire [31:0]   PRDATA,
    output wire          PREADY
);

assign PREADY = 1;  // Always ready

reg Rx_empty_delay, Data_Ready;
wire done_flag_sync, busy_flag_sync;
wire Key_Valid, Data_Valid;
wire [127:0] Rx_Data_out, privatekey, plaintxt, Tx_RDATA, privatekey_sync, Core_Data_out;
wire start_sync, mode_sync, zeroize_sync, Tx_rd_en, Tx_full, busy_flag, done_flag, Tx_empty, Rx_empty, Tx_empty_delayed;

Interface1 dut1(
    .PCLK(PCLK),
    .PRESETn(PRESETn),
    .PADDR(PADDR),
    .PSEL(PSEL),
    .PENABLE(PENABLE),
    .PWRITE(PWRITE),
    .PWDATA(PWDATA),
    .PPROT(PPROT),
    .Rx_empty_delay(Rx_empty_delay),
    .Tx_full(Tx_full),
    .Rx_Data_out(Rx_Data_out),
    .done_flag_sync(done_flag_sync),
    .busy_flag_sync(busy_flag_sync),
    .privatekey(privatekey),
    .Key_Valid(Key_Valid),
    .plaintxt(plaintxt),
    .Data_Valid(Data_Valid),
    .mode(mode),
    .ZEROIZE(ZEROIZE),
    .START(START),
    .SEC_VIOLATION(SEC_VIOLATION),
    .PSLVERR(PSLVERR),
    .PRDATA(PRDATA),
    .Rx_rd_en(Rx_rd_en)
);

ff2_sync #(.ADDR_WIDTH(1)) inst4(.clk(crypto_clk), .rstn(crypto_rstn), .Din(START), .Syn_out(start_sync));

ff2_sync #(.ADDR_WIDTH(1)) inst5(.clk(crypto_clk), .rstn(crypto_rstn), .Din(mode), .Syn_out(mode_sync));

ff2_sync #(.ADDR_WIDTH(1)) inst6(.clk(crypto_clk), .rstn(crypto_rstn), .Din(ZEROIZE), .Syn_out(zeroize_sync));

mux_sync key(.clkA(PCLK), .rstnA(PRESETn), .clkB(crypto_clk), .rstnB(crypto_rstn), .Din(privatekey), .ena(Key_Valid), .Dout(privatekey_sync));     // Private Key sync.

async_fifo_top #(.DATA_WIDTH(128), .DEPTH(1024)) TxFIFO(.rclk(crypto_clk), 
                .rd_en(Tx_rd_en),        // Once aes_done rd_en = 1
                .wclk(PCLK), 
                .wr_en(Data_Ready),              
                .rdrstn(crypto_rstn), 
                .wrstn(PRESETn),            
                .Data_in(plaintxt), 
                .full(Tx_full),                    
                .empty(Tx_empty),                   
                .Data_out(Tx_RDATA)
             );

always @ (posedge PCLK or negedge PRESETn) begin
    if(!PRESETn) begin
        Data_Ready <= 'b0;
    end
    else begin
        Data_Ready <= Data_Valid;
    end
end 

// Core Instantiation
Core_top core(
    .crypto_clk(crypto_clk), 
    .crypto_rstn(crypto_rstn),
    .start(start_sync), 
    .mode(mode_sync),
    .zeroize(zeroize_sync), 
    .fifo_empty_flag(Tx_empty_delayed), 
    .private_key(privatekey_sync),
    .Data_in(Tx_RDATA),
    .Data_out(Core_Data_out),
    .busy_flag(busy_flag), 
    .done_flag(done_flag),
    .aes_done(aes_done), 
    .key_store_done(key_store_done)
);

assign Tx_rd_en = aes_done || key_store_done;

DFF #(.ADDR_WIDTH(1)) aes_done_sync (.clk(crypto_clk), .rstn(crypto_rstn), .Din(aes_done), .Q(Rx_wr_en));

//Tx FIFO empty flag delayed for meeting timing
DFF #(.ADDR_WIDTH(1)) tx_fifo_mt (.clk(crypto_clk), .rstn(crypto_rstn), .Din(Tx_empty), .Q(Tx_empty_delayed));


//assign Rx_wr_en = aes_done;
//Rx FIFO
async_fifo_top #(.DATA_WIDTH(128), .DEPTH(1024)) RxFIFO(.rclk(PCLK), 
                .rd_en(Rx_rd_en), 
                .wclk(crypto_clk), 
                .wr_en(Rx_wr_en),           // When aes_done is high Rx_wr_en = 1;       
                .rdrstn(PRESETn), 
                .wrstn(crypto_rstn),            
                .Data_in(Core_Data_out), 
                .full(Rx_full),                    
                .empty(Rx_empty),                   
                .Data_out(Rx_Data_out)
             );

// Rx_Empty delay for capturing Output
always @ (posedge PCLK or negedge PRESETn) begin
    if(!PRESETn) begin
        Rx_empty_delay <= 1'b1;
    end
    else begin
        Rx_empty_delay <= Rx_empty;
    end
end

//reg busy_flag_in;
//always @ (posedge PCLK or negedge PRESETn) begin
//    if(!PRESETn) begin
//        busy_flag_in <= 'b0;
//    end
//    else if (busy_busy) begin
//        busy_flag_in <= busy_flag;
//    end
//end

//Handshake_sync busy(.clkA(crypto_clk), .clkB(PCLK), .rstnA(crypto_rstn), .rstnB(PRESETn), .Din(busy_flag_in), .Sync_out(busy_flag_sync), .Busy(busy_busy));
pulse_stretcher busy(.clkA(crypto_clk), .clkB(PCLK), .rstnA(crypto_rstn), .rstnB(PRESETn), .Din(busy_flag), .Dout(busy_flag_sync));


//reg done_flag_in;
//always @ (posedge PCLK or negedge PRESETn) begin
//    if(!PRESETn) begin
//        done_flag_in <= 'b0;
//    end
//    else if (busy_done) begin
//        done_flag_in <= done_flag;
//    end
//end

//Handshake_sync done(.clkA(crypto_clk), .clkB(PCLK), .rstnA(crypto_rstn), .rstnB(PRESETn), .Din(done_flag_in), .Sync_out(done_flag_sync), .Busy(busy_done));

pulse_stretcher done(.clkA(crypto_clk), .clkB(PCLK), .rstnA(crypto_rstn), .rstnB(PRESETn), .Din(done_flag), .Dout(done_flag_sync));



endmodule