`ifndef APB_SLAVE_AGENT_BFM_INCLUDED_
`define APB_SLAVE_AGENT_BFM_INCLUDED_

module apb_slave_agent_bfm(apb_if intf);
  import uvm_pkg::*;

  apb_slave_monitor_bfm apb_slave_mon_bfm_h (
    .pclk(intf.pclk),
    .preset_n(intf.preset_n),
    .psel(intf.psel),
    .paddr(intf.paddr),
    .pwrite(intf.pwrite),
    .pwdata(intf.pwdata),
    .pslverr(intf.pslverr),
    .pready(intf.pready),
    .prdata(intf.prdata),
    .penable(intf.penable),
    .pprot(intf.pprot),
    .crypto_rstn(intf.crypto_rstn),
    .sec_violation(intf.sec_violation)
  );

  initial begin
    uvm_config_db #(virtual apb_slave_monitor_bfm)::set(null, "*",
      "apb_slave_monitor_bfm", apb_slave_mon_bfm_h);
  end
endmodule : apb_slave_agent_bfm

`endif
