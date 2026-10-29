`ifndef APB_SLAVE_SEQ_ITEM_CONVERTER_INCLUDED_
`define APB_SLAVE_SEQ_ITEM_CONVERTER_INCLUDED_

class apb_slave_seq_item_converter;
  static function void to_class(input aes_transfer_char_s input_conv_h,
                                output apb_slave_tx output_conv_h);
    output_conv_h = apb_slave_tx::type_id::create("apb_sample");
    output_conv_h.paddr = input_conv_h.paddr;
    output_conv_h.pwdata = input_conv_h.pwdata;
    output_conv_h.psel = input_conv_h.psel;
    output_conv_h.penable = input_conv_h.penable;
    output_conv_h.pready = input_conv_h.pready;
    output_conv_h.pprot = protection_type_e'(input_conv_h.pprot);
    output_conv_h.pslverr = slave_error_e'(input_conv_h.pslverr);
    output_conv_h.pwrite = tx_type_e'(input_conv_h.pwrite);
    output_conv_h.prdata = input_conv_h.prdata;
    output_conv_h.preset_n = input_conv_h.preset_n;
    output_conv_h.crypto_rstn = input_conv_h.crypto_rstn;
    output_conv_h.sec_violation = input_conv_h.sec_violation;
  endfunction : to_class
endclass : apb_slave_seq_item_converter

`endif
