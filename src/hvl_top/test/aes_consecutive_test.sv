`ifndef AES_CONSECUTIVE_TEST_INCLUDED_
`define AES_CONSECUTIVE_TEST_INCLUDED_

class aes_consecutive_test extends apb_base_test;
  `uvm_component_utils(aes_consecutive_test)
  aes_consecutive_seq seq;
  virtual apb_if vif;

  function new(string name = "aes_consecutive_test",
               uvm_component parent = null);
    super.new(name, parent);
  endfunction : new

  virtual task run_phase(uvm_phase phase);
    phase.raise_objection(this);
    if(!uvm_config_db #(virtual apb_if)::get(this, "", "apb_vif", vif)) begin
      `uvm_fatal("AES_VIF", "Could not get the shared APB interface")
    end
    seq = aes_consecutive_seq::type_id::create("seq");
    seq.vif = vif;
    seq.start(apb_env_h.apb_master_agent_h.apb_master_seqr_h);
    phase.drop_objection(this);
  endtask : run_phase
endclass : aes_consecutive_test

`endif
