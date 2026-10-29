`ifndef APB_MASTER_TX_INCLUDED_
`define APB_MASTER_TX_INCLUDED_

class apb_master_tx extends uvm_sequence_item;
  `uvm_object_utils(apb_master_tx)

  bit [ADDRESS_WIDTH-1:0] paddr;
  protection_type_e pprot;
  bit psel;
  tx_type_e pwrite;
  bit [DATA_WIDTH-1:0] pwdata;
  logic [DATA_WIDTH-1:0] prdata; // read data returned by the driver to check status in sequence 

  function new(string name = "apb_master_tx");
    super.new(name);
  endfunction

  virtual function void do_print(uvm_printer printer);
    super.do_print(printer);
    printer.print_field("psel", psel, $bits(psel), UVM_BIN);
    printer.print_field("paddr", paddr, $bits(paddr), UVM_HEX);
    printer.print_string("pwrite", pwrite.name());
    printer.print_field("pwdata", pwdata, $bits(pwdata), UVM_HEX);
    printer.print_string("pprot", pprot.name());
  endfunction
endclass : apb_master_tx

`endif
