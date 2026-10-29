`ifndef APB_MASTER_SEQ_ITEM_CONVERTER_INCLUDED_
`define APB_MASTER_SEQ_ITEM_CONVERTER_INCLUDED_

class apb_master_seq_item_converter;
  static function void from_class(input apb_master_tx item,
                                  output aes_transfer_char_s packet);
    packet.pprot = item.pprot;
    packet.psel = item.psel;
    packet.pwrite = item.pwrite;
    packet.paddr = item.paddr;
    packet.pwdata = item.pwdata;
    packet.prdata = item.prdata;
  endfunction

  static function void to_class(input aes_transfer_char_s packet,
                                ref apb_master_tx item);
    item.pprot = protection_type_e'(packet.pprot);
    item.psel = packet.psel;
    item.pwrite = tx_type_e'(packet.pwrite);
    item.paddr = packet.paddr;
    item.pwdata = packet.pwdata;
  endfunction
endclass : apb_master_seq_item_converter

`endif
