`ifndef AES_SECURITY_STICKY_SEQ_INCLUDED_
`define AES_SECURITY_STICKY_SEQ_INCLUDED_

class aes_security_sticky_seq extends apb_master_base_seq;
  `uvm_object_utils(aes_security_sticky_seq)

  function new(string name = "aes_security_sticky_seq");
    super.new(name);
  endfunction : new

  virtual task body();
    logic [31:0] read_data;
    super.body();
    if(vif == null) begin
      `uvm_fatal("AES_VIF", "Sequence requires the shared APB interface")
    end
    wait(vif.preset_n === 1'b1 && vif.crypto_rstn === 1'b1);

    write_reg(AES_KEY0_ADDR, 32'hffffffff, NORMAL_SECURE_DATA);
    @(posedge vif.pclk);
    repeat(3) begin
      read_reg(AES_STATUS_ADDR, read_data, NORMAL_SECURE_DATA);
      @(posedge vif.pclk);
    end
  endtask : body
endclass : aes_security_sticky_seq

`endif
