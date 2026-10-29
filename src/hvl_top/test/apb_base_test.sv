`ifndef APB_BASE_TEST_INCLUDED_
`define APB_BASE_TEST_INCLUDED_

class apb_base_test extends uvm_test;
  `uvm_component_utils(apb_base_test)

  apb_env apb_env_h;

  function new(string name = "apb_base_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction : new

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    apb_env_h = apb_env::type_id::create("apb_env", this);
  endfunction : build_phase

  virtual function void end_of_elaboration_phase(uvm_phase phase);
    super.end_of_elaboration_phase(phase);
    uvm_top.print_topology();
    uvm_test_done.set_drain_time(this, 1000ns);
  endfunction : end_of_elaboration_phase
endclass : apb_base_test

`endif
