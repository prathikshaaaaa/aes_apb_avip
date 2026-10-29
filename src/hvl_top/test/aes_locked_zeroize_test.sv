`ifndef AES_LOCKED_ZEROIZE_TEST_INCLUDED_
`define AES_LOCKED_ZEROIZE_TEST_INCLUDED_

class aes_locked_zeroize_test extends apb_base_test;
  `uvm_component_utils(aes_locked_zeroize_test)
  aes_locked_zeroize_seq seq;
  virtual apb_if vif;

  function new(string name = "aes_locked_zeroize_test",
               uvm_component parent = null);
    super.new(name, parent);
  endfunction : new

  virtual task run_phase(uvm_phase phase);
    phase.raise_objection(this);
    if(!uvm_config_db #(virtual apb_if)::get(this, "", "apb_vif", vif)) begin
      `uvm_fatal("AES_VIF", "Could not get the shared APB interface")
    end
    seq = aes_locked_zeroize_seq::type_id::create("seq");
    seq.vif = vif;
    seq.start(apb_env_h.apb_master_agent_h.apb_master_seqr_h);
    phase.drop_objection(this);
  endtask : run_phase
endclass : aes_locked_zeroize_test

`endif
