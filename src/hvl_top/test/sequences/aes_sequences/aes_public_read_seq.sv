`ifndef AES_PUBLIC_READ_SEQ_INCLUDED_
`define AES_PUBLIC_READ_SEQ_INCLUDED_

class aes_public_read_seq extends apb_master_base_seq;
  `uvm_object_utils(aes_public_read_seq)

  function new(string name = "aes_public_read_seq");
    super.new(name);
  endfunction : new

  virtual task body();
    logic [31:0] read_data;
    super.body();
    if(vif == null) begin
      `uvm_fatal("AES_VIF", "Sequence requires the shared APB interface")
    end
    wait(vif.preset_n === 1'b1 && vif.crypto_rstn === 1'b1);

    read_reg(AES_STATUS_ADDR, read_data, NORMAL_SECURE_DATA);
    read_reg(AES_DATA_OUT0_ADDR, read_data, NORMAL_SECURE_DATA);
    read_reg(AES_DATA_OUT1_ADDR, read_data, NORMAL_SECURE_DATA);
    read_reg(AES_DATA_OUT2_ADDR, read_data, NORMAL_SECURE_DATA);
    read_reg(AES_DATA_OUT3_ADDR, read_data, NORMAL_SECURE_DATA);
  endtask : body
endclass : aes_public_read_seq

`endif
