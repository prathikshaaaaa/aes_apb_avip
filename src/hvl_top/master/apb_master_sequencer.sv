`ifndef APB_MASTER_SEQUENCER_INCLUDED_
`define APB_MASTER_SEQUENCER_INCLUDED_

class apb_master_sequencer extends uvm_sequencer #(apb_master_tx);
  `uvm_component_utils(apb_master_sequencer)

  function new(string name = "apb_master_sequencer", uvm_component parent);
    super.new(name, parent);
  endfunction
endclass : apb_master_sequencer

`endif
