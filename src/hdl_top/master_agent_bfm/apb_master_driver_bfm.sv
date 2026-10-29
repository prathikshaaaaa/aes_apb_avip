`ifndef APB_MASTER_DRIVER_BFM_INCLUDED_
`define APB_MASTER_DRIVER_BFM_INCLUDED_

import aes_global_pkg::*;

interface apb_master_driver_bfm (
  input bit pclk,
  input logic preset_n,
  input logic [DATA_WIDTH-1:0] prdata,
  output logic [2:0] pprot,
  output logic penable,
  output logic pwrite,
  output logic [ADDRESS_WIDTH-1:0] paddr,
  output logic psel,
  output logic [DATA_WIDTH-1:0] pwdata
);
  initial begin
    psel = 1'b0;
    penable = 1'b0;
    paddr = '0;
    pwrite = READ;
    pwdata = '0;
    pprot = NORMAL_SECURE_DATA;
  end

  task automatic drive_idle_state();
    psel    <= 1'b0;
    penable <= 1'b0;
    paddr   <= '0;
    pwrite  <= READ;
    pwdata  <= '0;
    pprot   <= NORMAL_SECURE_DATA;
  endtask

  task automatic drive_to_bfm(inout aes_transfer_char_s data_packet);
    // The proxy calls at a PCLK edge, including a previous transfer's completion.
    psel    <= data_packet.psel;
    penable <= 1'b0;
    paddr   <= data_packet.paddr;
    pwrite  <= data_packet.pwrite;
    pwdata  <= (data_packet.pwrite == WRITE) ? data_packet.pwdata : '0;
    pprot   <= data_packet.pprot;
    // Setup
    @(posedge pclk);
    penable <= 1'b1;
    //Access
    @(posedge pclk); // No wait states
    if (data_packet.pwrite == READ) begin
      data_packet.prdata = prdata;
    end
    penable <= 1'b0; // To support back-to-back transfers, PSEL is kept high.If not back-to-back, the proxy calls drive_idle_state().
  endtask

endinterface : apb_master_driver_bfm

`endif
