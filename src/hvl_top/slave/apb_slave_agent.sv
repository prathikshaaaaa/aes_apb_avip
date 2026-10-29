`ifndef APB_SLAVE_AGENT_INCLUDED_
`define APB_SLAVE_AGENT_INCLUDED_

class apb_slave_agent extends uvm_agent;
  `uvm_component_utils(apb_slave_agent)

  apb_slave_monitor_proxy apb_slave_mon_proxy_h;
  apb_slave_coverage apb_slave_cov_h;

  function new(string name = "apb_slave_agent", uvm_component parent);
    super.new(name, parent);
  endfunction : new

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    apb_slave_mon_proxy_h = apb_slave_monitor_proxy::type_id::create("apb_slave_mon_proxy_h", this);
    apb_slave_cov_h = apb_slave_coverage::type_id::create("apb_slave_cov_h", this);
  endfunction : build_phase

  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    apb_slave_mon_proxy_h.apb_slave_analysis_port.connect(apb_slave_cov_h.analysis_export);
  endfunction : connect_phase
endclass : apb_slave_agent

`endif
