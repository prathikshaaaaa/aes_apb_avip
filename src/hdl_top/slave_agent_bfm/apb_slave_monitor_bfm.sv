`ifndef APB_SLAVE_MONITOR_BFM_INCLUDED_
`define APB_SLAVE_MONITOR_BFM_INCLUDED_

import aes_global_pkg::*;

interface apb_slave_monitor_bfm (
  input bit pclk,
  input logic preset_n,
  input logic psel,
  input bit [2:0] pprot,
  input bit pslverr,
  input logic pready,
  input logic penable,
  input logic pwrite,
  input logic [ADDRESS_WIDTH-1:0] paddr,
  input logic [DATA_WIDTH-1:0] pwdata,
  input logic [DATA_WIDTH-1:0] prdata,
  input logic crypto_rstn,
  input logic sec_violation
);
  task automatic sample_data(output aes_transfer_char_s packet);
    @(posedge pclk);
    packet.psel = psel;
    packet.penable = penable;
    packet.pready = pready;
    packet.pslverr = pslverr;
    packet.pprot = pprot;
    packet.pwrite = pwrite;
    packet.paddr = paddr;
    packet.pwdata = pwdata;
    packet.prdata = prdata;
    packet.preset_n = preset_n;
    packet.crypto_rstn = crypto_rstn;
    packet.sec_violation = sec_violation;
  endtask : sample_data

endinterface : apb_slave_monitor_bfm

`endif
