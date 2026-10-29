`ifndef APB_SLAVE_COVERAGE_INCLUDED_
`define APB_SLAVE_COVERAGE_INCLUDED_

class apb_slave_coverage extends uvm_subscriber #(apb_slave_tx);
  `uvm_component_utils(apb_slave_coverage)

  covergroup apb_transaction_cg with function sample(apb_slave_tx packet);
    // Register addresses.
    PADDR_CP : coverpoint ((packet.paddr <= AES_DATA_OUT3_ADDR &&
                           packet.paddr % AES_WORD_BYTES == 0) ? packet.paddr : 8'hff) {
      bins control = {AES_CONTROL_ADDR};
      bins status = {AES_STATUS_ADDR};
      bins key_words[] = {AES_KEY0_ADDR, AES_KEY1_ADDR, AES_KEY2_ADDR, AES_KEY3_ADDR};
      bins input_words[] = {AES_DATA0_ADDR, AES_DATA1_ADDR, AES_DATA2_ADDR, AES_DATA3_ADDR};
      bins output_words[] = {AES_DATA_OUT0_ADDR, AES_DATA_OUT1_ADDR, AES_DATA_OUT2_ADDR, AES_DATA_OUT3_ADDR};
      bins invalid = {8'hff};
    }
    // Read/write direction, privilege and write-data range.
    PWRITE_CP : coverpoint packet.pwrite {bins read_access = {READ}; bins write_access = {WRITE};}
    PPROT_CP : coverpoint packet.pprot[0] {bins normal_access = {0}; bins privileged_access = {1};}
    PWDATA_CP : coverpoint packet.pwdata iff(packet.pwrite == WRITE) {
      bins low = {[32'h00000000:32'h55555555]};
      bins mid_values = {[32'h55555556:32'haaaaaaaa]};
      bins high = {[32'haaaaaaab:32'hffffffff]};
    }
    // CONTROL command bits.
    CTRL_START_CP : coverpoint packet.pwdata[AES_CTRL_START_BIT]
      iff(packet.pwrite == WRITE && packet.paddr == AES_CONTROL_ADDR &&
          packet.pprot[0] && packet.pslverr == NO_ERROR) {bins low = {0}; bins high = {1};}
    CTRL_MODE_CP : coverpoint packet.pwdata[AES_CTRL_MODE_BIT]
      iff(packet.pwrite == WRITE && packet.paddr == AES_CONTROL_ADDR &&
          packet.pprot[0] && packet.pslverr == NO_ERROR) {bins decrypt = {0}; bins encrypt = {1};}
    CTRL_KEY_LOCK_CP : coverpoint packet.pwdata[AES_CTRL_KEY_LOCK_BIT]
      iff(packet.pwrite == WRITE && packet.paddr == AES_CONTROL_ADDR &&
          packet.pprot[0] && packet.pslverr == NO_ERROR) {bins unlocked = {0}; bins locked = {1};}
    CTRL_ZEROIZE_CP : coverpoint packet.pwdata[AES_CTRL_ZEROIZE_BIT]
      iff(packet.pwrite == WRITE && packet.paddr == AES_CONTROL_ADDR &&
          packet.pprot[0] && packet.pslverr == NO_ERROR) {bins inactive = {0}; bins active = {1};}
    // STATUS readback.
    STATUS_BUSY_CP : coverpoint packet.prdata[AES_STATUS_BUSY_BIT]
      iff(packet.pwrite == READ && packet.paddr == AES_STATUS_ADDR &&
          packet.pslverr == NO_ERROR && !$isunknown(packet.prdata)) {bins idle = {0}; bins busy = {1};}
    STATUS_DONE_CP : coverpoint packet.prdata[AES_STATUS_DONE_BIT]
      iff(packet.pwrite == READ && packet.paddr == AES_STATUS_ADDR &&
          packet.pslverr == NO_ERROR && !$isunknown(packet.prdata)) {bins not_done = {0}; bins done = {1};}
    // Response error and read-data range.
    PSLVERR_CP : coverpoint packet.pslverr {bins successful = {NO_ERROR}; bins rejected = {ERROR};}
    PRDATA_CP : coverpoint packet.prdata iff(packet.pwrite == READ && packet.pslverr == NO_ERROR && !$isunknown(packet.prdata)) {
      bins low = {[32'h00000000:32'h55555555]};
      bins mid_values = {[32'h55555556:32'haaaaaaaa]};
      bins high = {[32'haaaaaaab:32'hffffffff]};
    }
  endgroup : apb_transaction_cg

  covergroup interface_signal_cg with function sample(apb_slave_tx packet);
    // Reset and APB idle/setup/access levels.
    PRESETn_CP : coverpoint packet.preset_n {bins asserted = {0}; bins released = {1};}
    CRYPTO_RSTN_CP : coverpoint packet.crypto_rstn {bins asserted = {0}; bins released = {1};}
    PRESETn_x_crypto_rstn : cross PRESETn_CP, CRYPTO_RSTN_CP;
    PSEL_CP : coverpoint packet.psel iff(packet.preset_n === 1'b1) {
      bins deselected = {0}; bins selected = {1};
    }
    PENABLE_CP : coverpoint packet.penable iff(packet.preset_n === 1'b1) {
      bins setup_or_idle = {0}; bins access = {1};
    }
    // Security and the always-ready response.
    SEC_VIOLATION_FLAG_CP : coverpoint packet.sec_violation iff(packet.preset_n === 1'b1) {
      bins clear = {0}; bins asserted = {1};
    }
    PREADY_CP : coverpoint packet.pready iff(packet.preset_n === 1'b1) {bins ready = {1};}
  endgroup : interface_signal_cg

  function new(string name = "apb_slave_coverage", uvm_component parent = null);
    super.new(name, parent);
    apb_transaction_cg = new();
    interface_signal_cg = new();
  endfunction : new

  virtual function void write(apb_slave_tx t);
    interface_signal_cg.sample(t);
    if(t.preset_n === 1'b1 && t.crypto_rstn === 1'b1 &&
       t.psel === 1'b1 && t.penable === 1'b1 && t.pready === 1'b1) //no rst and completed
      apb_transaction_cg.sample(t);
  endfunction : write

  virtual function void report_phase(uvm_phase phase);
    super.report_phase(phase);
    `uvm_info("AES_COVERAGE",
              $sformatf("APB=%0.2f%% pins/resets=%0.2f%%",
                        apb_transaction_cg.get_inst_coverage(), interface_signal_cg.get_inst_coverage()), UVM_LOW)
  endfunction : report_phase
endclass : apb_slave_coverage

`endif
