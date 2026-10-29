`ifndef AES_UNPRIVILEGED_WRITE_SEQ_INCLUDED_
`define AES_UNPRIVILEGED_WRITE_SEQ_INCLUDED_

class aes_unprivileged_write_seq extends apb_master_base_seq;
  `uvm_object_utils(aes_unprivileged_write_seq)

  function new(string name = "aes_unprivileged_write_seq");
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

    // Establish a valid zero key before attempting to overwrite it without privilege.
    write_reg(AES_KEY0_ADDR, 32'h00000000, PRIVILEGED_SECURE_DATA);
    write_reg(AES_KEY1_ADDR, 32'h00000000, PRIVILEGED_SECURE_DATA);
    write_reg(AES_KEY2_ADDR, 32'h00000000, PRIVILEGED_SECURE_DATA);
    write_reg(AES_KEY3_ADDR, 32'h00000000, PRIVILEGED_SECURE_DATA);
    // Unauthorized writes must report errors and leave protected state unchanged.
    for(int addr = AES_CONTROL_ADDR; addr <= AES_DATA3_ADDR; addr += AES_WORD_BYTES) begin
      if(addr != AES_STATUS_ADDR) begin
        write_reg(addr, 32'hffffffff, NORMAL_SECURE_DATA);
      end
    end
    @(posedge vif.pclk);
    read_reg(AES_CONTROL_ADDR, read_data, PRIVILEGED_SECURE_DATA);
    read_reg(AES_DATA0_ADDR, read_data, PRIVILEGED_SECURE_DATA);
    read_reg(AES_DATA1_ADDR, read_data, PRIVILEGED_SECURE_DATA);
    read_reg(AES_DATA2_ADDR, read_data, PRIVILEGED_SECURE_DATA);
    read_reg(AES_DATA3_ADDR, read_data, PRIVILEGED_SECURE_DATA);
    // Do not reload KEY: result checking must expose an unauthorized key modification.
    // CONTROL: START=0, MODE=1, KEY_LOCK=0, ZEROIZE=0.
    write_reg(AES_CONTROL_ADDR, 32'h00000002, PRIVILEGED_SECURE_DATA);
    // Program DATA0 through DATA3.
    write_reg(AES_DATA0_ADDR, 32'h6bc1bee2, PRIVILEGED_SECURE_DATA);
    write_reg(AES_DATA1_ADDR, 32'h2e409f96, PRIVILEGED_SECURE_DATA);
    write_reg(AES_DATA2_ADDR, 32'he93d7e11, PRIVILEGED_SECURE_DATA);
    write_reg(AES_DATA3_ADDR, 32'h7393172a, PRIVILEGED_SECURE_DATA);
    // CONTROL: START=1, MODE=1, KEY_LOCK=0, ZEROIZE=0.
    write_reg(AES_CONTROL_ADDR, 32'h00000003, PRIVILEGED_SECURE_DATA);
    // Release START before the synchronized operation becomes BUSY.
    write_reg(AES_CONTROL_ADDR, 32'h00000002, PRIVILEGED_SECURE_DATA);
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
endclass : aes_unprivileged_write_seq

`endif
