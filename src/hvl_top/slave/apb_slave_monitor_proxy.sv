`ifndef APB_SLAVE_MONITOR_PROXY_INCLUDED_
`define APB_SLAVE_MONITOR_PROXY_INCLUDED_

class apb_slave_monitor_proxy extends uvm_monitor;
  `uvm_component_utils(apb_slave_monitor_proxy)

  uvm_analysis_port #(apb_slave_tx) apb_slave_analysis_port;
  virtual apb_slave_monitor_bfm apb_slave_mon_bfm_h;

  extern function new(string name = "apb_slave_monitor_proxy", uvm_component parent = null);
  extern function void end_of_elaboration_phase(uvm_phase phase);
  extern virtual task run_phase(uvm_phase phase);
endclass : apb_slave_monitor_proxy

function apb_slave_monitor_proxy::new(string name = "apb_slave_monitor_proxy", uvm_component parent = null);
  super.new(name, parent);
  apb_slave_analysis_port = new("apb_slave_analysis_port", this);
endfunction : new

function void apb_slave_monitor_proxy::end_of_elaboration_phase(uvm_phase phase);
  super.end_of_elaboration_phase(phase);
  if(!uvm_config_db #(virtual apb_slave_monitor_bfm)::get(this, "",
      "apb_slave_monitor_bfm", apb_slave_mon_bfm_h))
    `uvm_fatal("APB_SLAVE_MONITOR_BFM", "Cannot get the passive slave monitor BFM")
endfunction : end_of_elaboration_phase

task apb_slave_monitor_proxy::run_phase(uvm_phase phase);
  aes_transfer_char_s transfer;
  apb_slave_tx packet;
  forever begin
    apb_slave_mon_bfm_h.sample_data(transfer);
    apb_slave_seq_item_converter::to_class(transfer, packet);
    apb_slave_analysis_port.write(packet);
  end
endtask : run_phase

`endif
