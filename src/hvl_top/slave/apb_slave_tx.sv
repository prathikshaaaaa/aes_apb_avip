`ifndef APB_SLAVE_TX_INCLUDED_
`define APB_SLAVE_TX_INCLUDED_

class apb_slave_tx extends uvm_sequence_item;
  `uvm_object_utils(apb_slave_tx)

  logic psel, penable, pready;
  bit [ADDRESS_WIDTH-1:0] paddr;
  tx_type_e pwrite;
  bit [DATA_WIDTH-1:0] pwdata;
  slave_error_e pslverr;
  logic [DATA_WIDTH-1:0] prdata;
  protection_type_e pprot;
  logic preset_n, crypto_rstn, sec_violation;

  function new(string name = "apb_slave_tx");
    super.new(name);
  endfunction : new

endclass : apb_slave_tx

`endif
