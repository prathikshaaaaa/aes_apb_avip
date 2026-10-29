`ifndef APB_MASTER_AGENT_INCLUDED_
`define APB_MASTER_AGENT_INCLUDED_

class apb_master_agent extends uvm_agent;
  `uvm_component_utils(apb_master_agent)

  apb_master_sequencer apb_master_seqr_h;
  apb_master_driver_proxy apb_master_drv_proxy_h;
  apb_master_monitor_proxy apb_master_mon_proxy_h;

  function new(string name = "apb_master_agent", uvm_component parent);
    super.new(name, parent);
  endfunction

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    apb_master_drv_proxy_h = apb_master_driver_proxy::type_id::create("apb_master_drv_proxy_h", this);
    apb_master_seqr_h = apb_master_sequencer::type_id::create("apb_master_seqr_h", this);
    apb_master_mon_proxy_h = apb_master_monitor_proxy::type_id::create("apb_master_mon_proxy_h", this);
  endfunction

  virtual function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    apb_master_drv_proxy_h.seq_item_port.connect(apb_master_seqr_h.seq_item_export);
  endfunction
endclass : apb_master_agent

`endif
