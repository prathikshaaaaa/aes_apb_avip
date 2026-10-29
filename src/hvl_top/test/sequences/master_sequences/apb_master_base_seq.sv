`ifndef APB_MASTER_BASE_SEQ_INCLUDED_
`define APB_MASTER_BASE_SEQ_INCLUDED_

class apb_master_base_seq extends uvm_sequence #(apb_master_tx);
  `uvm_object_utils(apb_master_base_seq)
  virtual apb_if vif;

  function new(string name = "apb_master_base_seq");
    super.new(name);
  endfunction

  virtual task body();
    if (m_sequencer == null) begin
      `uvm_fatal(get_full_name(), "Start this sequence on the APB master sequencer")
    end
  endtask

  // Create and send one APB register access.
  protected virtual task access_reg(
    input tx_type_e operation,
    input bit [ADDRESS_WIDTH-1:0] addr,
    input bit [DATA_WIDTH-1:0] write_data,
    input protection_type_e protection,
    output apb_master_tx item);
    item = apb_master_tx::type_id::create("reg_item");
    start_item(item);
    item.psel = 1'b1;
    item.paddr = addr;
    item.pwrite = operation;
    item.pwdata = write_data;
    item.pprot = protection;
    finish_item(item);
  endtask

  virtual task write_reg(
    input bit [ADDRESS_WIDTH-1:0] addr,
    input bit [DATA_WIDTH-1:0] data,
    input protection_type_e protection = PRIVILEGED_SECURE_DATA);
    apb_master_tx item;
    access_reg(WRITE, addr, data, protection, item);
  endtask

  virtual task read_reg(
    input bit [ADDRESS_WIDTH-1:0] addr,
    output logic [DATA_WIDTH-1:0] data,
    input protection_type_e protection = PRIVILEGED_SECURE_DATA);
    apb_master_tx item;
    access_reg(READ, addr, '0, protection, item);
    data = item.prdata;
  endtask
endclass : apb_master_base_seq

`endif
