`ifndef HDL_TOP_INCLUDED
`define HDL_TOP_INCLUDED

module hdl_top;
  timeunit 1ps;
  timeprecision 1ps;

  import uvm_pkg::*;
  `include "uvm_macros.svh"
  import aes_global_pkg::*;

  parameter time PCLK_PERIOD = 10ns;
  parameter time CRYPTO_CLK_PERIOD = 5ns;
  parameter int RESET_CYCLES = 4;

  bit pclk;
  bit crypto_clk;
  bit preset_n;
  bit crypto_rstn;

  initial begin
    pclk = 0;
    forever #(PCLK_PERIOD / 2.0) pclk = !pclk;
  end

  initial begin
    crypto_clk = 0;
    forever #(CRYPTO_CLK_PERIOD / 2.0) crypto_clk = !crypto_clk;
  end

  initial begin
    preset_n = 0;
    crypto_rstn = 0;
    fork
      begin
        repeat(RESET_CYCLES) @(posedge pclk);
        preset_n <= 1;
      end
      begin
        repeat(RESET_CYCLES) @(posedge crypto_clk);
        crypto_rstn <= 1;
      end
    join
  end

  apb_if intf(pclk, preset_n);
  assign intf.crypto_rstn = crypto_rstn;

  initial begin
    uvm_config_db #(virtual apb_if)::set(null, "*", "apb_vif", intf);
  end

  apb_master_agent_bfm apb_master_agent_bfm_h(intf);
  apb_slave_agent_bfm apb_slave_agent_bfm_h(intf);

  top1 aes_dut (
    .PCLK(pclk),
    .PRESETn(preset_n),
    .crypto_clk(crypto_clk),
    .crypto_rstn(crypto_rstn),
    .PADDR(intf.paddr),
    .PSEL(intf.psel),
    .PENABLE(intf.penable),
    .PWRITE(intf.pwrite),
    .PWDATA(intf.pwdata),
    .PPROT(intf.pprot),
    .PRDATA(intf.prdata),
    .PREADY(intf.pready),
    .PSLVERR(intf.pslverr),
    .SEC_VIOLATION(intf.sec_violation)
  );

  initial begin
    if ($test$plusargs("VCD_DUMP")) begin
      $dumpfile("waveform.vcd");
      $dumpvars(0, hdl_top);
    end
  end
endmodule : hdl_top

`endif
