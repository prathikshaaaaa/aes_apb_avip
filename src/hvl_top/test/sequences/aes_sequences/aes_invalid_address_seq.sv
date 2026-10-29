`ifndef AES_INVALID_ADDRESS_SEQ_INCLUDED_
`define AES_INVALID_ADDRESS_SEQ_INCLUDED_

class aes_invalid_address_seq extends apb_master_base_seq;
  `uvm_object_utils(aes_invalid_address_seq)

  function new(string name = "aes_invalid_address_seq");
    super.new(name);
  endfunction : new

  virtual task body();
    logic [31:0] read_data;
    super.body();
    if(vif == null) begin
      `uvm_fatal("AES_VIF", "Sequence requires the shared APB interface")
    end
    wait(vif.preset_n === 1'b1 && vif.crypto_rstn === 1'b1);

    read_reg(8'hff, read_data, PRIVILEGED_SECURE_DATA);
    write_reg(8'hff, 32'hffffffff, PRIVILEGED_SECURE_DATA);
    read_reg(8'h01, read_data, PRIVILEGED_SECURE_DATA);
    // Invalid addresses must also fail for normal accesses
    read_reg(8'hff, read_data, NORMAL_SECURE_DATA);
    write_reg(8'hff, 32'hffffffff, NORMAL_SECURE_DATA);
    @(posedge vif.pclk);
  endtask : body
endclass : aes_invalid_address_seq

`endif
