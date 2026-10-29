`ifndef AES_UNINITIALIZED_SEQ_INCLUDED_
`define AES_UNINITIALIZED_SEQ_INCLUDED_

class aes_uninitialized_seq extends apb_master_base_seq;
  `uvm_object_utils(aes_uninitialized_seq)

  function new(string name = "aes_uninitialized_seq");
    super.new(name);
  endfunction : new

  virtual task body();
    logic [31:0] read_data;
    logic [31:0] status;
    bit done;
    bit busy_seen;
    super.body();
    if(vif == null) begin
      `uvm_fatal("AES_VIF", "Sequence requires the shared APB interface")
    end
    wait(vif.preset_n === 1'b1 && vif.crypto_rstn === 1'b1);

    // Leave key, input and mode at their reset defaults.
    // CONTROL: START=1, MODE=0, KEY_LOCK=0, ZEROIZE=0.
    write_reg(AES_CONTROL_ADDR, 32'h00000001, PRIVILEGED_SECURE_DATA);
    // Release START after the accepted request.
    write_reg(AES_CONTROL_ADDR, 32'h00000000, PRIVILEGED_SECURE_DATA);
    // Observe BUSY after START, then wait for DONE=1 and BUSY=0.
    done = 0;
    busy_seen = 0;
    for(int poll_index = 0; poll_index < 24; poll_index++) begin
      read_reg(AES_STATUS_ADDR, status, NORMAL_SECURE_DATA);
      if($isunknown(status)) begin
        `uvm_fatal("AES_STATUS_X", "STATUS contains unknown bits")
      end
      busy_seen |= status[AES_STATUS_BUSY_BIT];
      if(busy_seen && status[AES_STATUS_DONE_BIT] &&
         !status[AES_STATUS_BUSY_BIT]) begin
        done = 1;
        break;
      end
    end
    if(!done) begin
      `uvm_fatal("AES_DONE_TIMEOUT", "AES did not complete before the STATUS polling limit")
    end
    // Read the four output words; the independent scoreboard checks the AES result.
    read_reg(AES_DATA_OUT0_ADDR, read_data, NORMAL_SECURE_DATA);
    read_reg(AES_DATA_OUT1_ADDR, read_data, NORMAL_SECURE_DATA);
    read_reg(AES_DATA_OUT2_ADDR, read_data, NORMAL_SECURE_DATA);
    read_reg(AES_DATA_OUT3_ADDR, read_data, NORMAL_SECURE_DATA);
  endtask : body
endclass : aes_uninitialized_seq

`endif

