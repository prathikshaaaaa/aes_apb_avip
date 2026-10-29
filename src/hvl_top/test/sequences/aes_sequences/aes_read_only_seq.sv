`ifndef AES_READ_ONLY_SEQ_INCLUDED_
`define AES_READ_ONLY_SEQ_INCLUDED_

class aes_read_only_seq extends apb_master_base_seq;
  `uvm_object_utils(aes_read_only_seq)

  function new(string name = "aes_read_only_seq");
    super.new(name);
  endfunction : new

  virtual task body();
    logic [31:0] read_data;
    logic [31:0] before_data;
    bit [ADDRESS_WIDTH-1:0] address;
    super.body();
    if(vif == null) begin
      `uvm_fatal("AES_VIF", "Sequence requires the shared APB interface")
    end
    wait(vif.preset_n === 1'b1 && vif.crypto_rstn === 1'b1);

    // Exercise ignored writes to STATUS and all output registers in both privilege modes.
    for(int privilege = 0; privilege < 2; privilege++) begin
      for(int register_index = 0; register_index < 5; register_index++) begin
        address = register_index == 0 ? AES_STATUS_ADDR :
                  AES_DATA_OUT0_ADDR+(register_index-1)*AES_WORD_BYTES; //reg index 0 - status, 1-4 - data out
        read_reg(address, before_data, protection_type_e'(privilege));
        write_reg(address, 32'hffffffff, protection_type_e'(privilege));
        read_reg(address, read_data, protection_type_e'(privilege));
      end
    end
  endtask : body
endclass : aes_read_only_seq

`endif
