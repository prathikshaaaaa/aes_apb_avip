`ifndef APB_MASTER_MONITOR_BFM_INCLUDED_
`define APB_MASTER_MONITOR_BFM_INCLUDED_

import aes_global_pkg::*;

interface apb_master_monitor_bfm (
  input bit pclk,
  input logic preset_n,
  input logic pready,
  input bit [2:0] pprot,
  input logic penable,
  input logic pwrite,
  input logic [ADDRESS_WIDTH-1:0] paddr,
  input logic psel,
  input logic [DATA_WIDTH-1:0] pwdata
);
  task automatic sample_data(output aes_transfer_char_s packet);
    forever begin 
      @(posedge pclk);
      if (psel === 1'b1 && penable === 1'b1 && pready === 1'b1) begin //Check till completion and exit
        packet.pprot = pprot;
        packet.pwrite = pwrite;
        packet.paddr = paddr;
        packet.psel = psel;
        packet.pwdata = pwdata;
        return; 
      end
    end
  endtask
endinterface : apb_master_monitor_bfm

`endif
