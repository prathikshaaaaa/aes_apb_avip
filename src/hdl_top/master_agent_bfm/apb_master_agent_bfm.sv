`ifndef APB_MASTER_AGENT_BFM_INCLUDED_
`define APB_MASTER_AGENT_BFM_INCLUDED_

module apb_master_agent_bfm(apb_if intf);
  import uvm_pkg::*;

  apb_master_driver_bfm apb_master_drv_bfm_h (
    .pclk(intf.pclk), .preset_n(intf.preset_n),
    .psel(intf.psel), .penable(intf.penable),
    .pprot(intf.pprot), .paddr(intf.paddr), .pwrite(intf.pwrite),
    .pwdata(intf.pwdata),
    .prdata(intf.prdata)
  );

  apb_master_monitor_bfm apb_master_mon_bfm_h (
    .pclk(intf.pclk), .preset_n(intf.preset_n),
    .psel(intf.psel), .penable(intf.penable),
    .pprot(intf.pprot), .paddr(intf.paddr), .pwrite(intf.pwrite),
    .pwdata(intf.pwdata),
    .pready(intf.pready)
  );

  initial begin
    uvm_config_db #(virtual apb_master_driver_bfm)::set(
      null, "*", "apb_master_driver_bfm", apb_master_drv_bfm_h);
    uvm_config_db #(virtual apb_master_monitor_bfm)::set(
      null, "*", "apb_master_monitor_bfm", apb_master_mon_bfm_h);
  end
endmodule : apb_master_agent_bfm

`endif
