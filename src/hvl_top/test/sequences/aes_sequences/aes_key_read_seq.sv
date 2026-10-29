`ifndef AES_KEY_READ_SEQ_INCLUDED_
`define AES_KEY_READ_SEQ_INCLUDED_

class aes_key_read_seq extends apb_master_base_seq;
  `uvm_object_utils(aes_key_read_seq)

  function new(string name = "aes_key_read_seq");
    super.new(name);
  endfunction : new

  virtual task body();
    logic [31:0] read_data;
    super.body();
    if(vif == null) begin
      `uvm_fatal("AES_VIF", "Sequence requires the shared APB interface")
    end
    wait(vif.preset_n === 1'b1 && vif.crypto_rstn === 1'b1);

    // Program KEY0 through KEY3, most significant word first.
    write_reg(AES_KEY0_ADDR, 32'h2b7e1516, PRIVILEGED_SECURE_DATA);
    write_reg(AES_KEY1_ADDR, 32'h28aed2a6, PRIVILEGED_SECURE_DATA);
    write_reg(AES_KEY2_ADDR, 32'habf71588, PRIVILEGED_SECURE_DATA);
    write_reg(AES_KEY3_ADDR, 32'h09cf4f3c, PRIVILEGED_SECURE_DATA);
    // CONTROL: START=0, MODE=1, KEY_LOCK=0, ZEROIZE=0.
    write_reg(AES_CONTROL_ADDR, 32'h00000002, PRIVILEGED_SECURE_DATA);
    read_reg(AES_KEY0_ADDR, read_data, PRIVILEGED_SECURE_DATA);
    read_reg(AES_KEY0_ADDR, read_data, NORMAL_SECURE_DATA);
    read_reg(AES_KEY1_ADDR, read_data, PRIVILEGED_SECURE_DATA);
    read_reg(AES_KEY1_ADDR, read_data, NORMAL_SECURE_DATA);
    read_reg(AES_KEY2_ADDR, read_data, PRIVILEGED_SECURE_DATA);
    read_reg(AES_KEY2_ADDR, read_data, NORMAL_SECURE_DATA);
    read_reg(AES_KEY3_ADDR, read_data, PRIVILEGED_SECURE_DATA);
    read_reg(AES_KEY3_ADDR, read_data, NORMAL_SECURE_DATA);
  endtask : body
endclass : aes_key_read_seq

`endif
