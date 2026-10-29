`ifndef APB_ENV_INCLUDED_
`define APB_ENV_INCLUDED_

class apb_env extends uvm_env;
  `uvm_component_utils(apb_env)

  apb_master_agent apb_master_agent_h;
  apb_slave_agent apb_slave_agent_h;
  apb_scoreboard apb_scoreboard_h;

  function new(string name = "apb_env", uvm_component parent = null);
    super.new(name, parent);
  endfunction : new

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    apb_master_agent_h = apb_master_agent::type_id::create("apb_master_agent", this);
    apb_slave_agent_h = apb_slave_agent::type_id::create("apb_slave_agent", this);
    apb_scoreboard_h = apb_scoreboard::type_id::create("apb_scoreboard_h", this);
  endfunction : build_phase

  virtual function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    apb_slave_agent_h.apb_slave_mon_proxy_h.apb_slave_analysis_port.connect(
      apb_scoreboard_h.apb_analysis_imp);
  endfunction : connect_phase
endclass : apb_env

`endif
