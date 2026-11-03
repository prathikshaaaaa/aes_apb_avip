`ifndef APB_SCOREBOARD_INCLUDED_
`define APB_SCOREBOARD_INCLUDED_

class apb_scoreboard extends uvm_scoreboard;
  `uvm_component_utils(apb_scoreboard)

  localparam int MAX_BLOCKS = 1024;

  uvm_analysis_imp #(apb_slave_tx, apb_scoreboard) apb_analysis_imp;
  aes_ref_model model;

  protected aes_block_t key;             // Current 128-bit AES key.
  protected aes_block_t input_block;     // Current DATA register contents.
  protected aes_mode_e mode;             // Current encrypt/decrypt selection.
  protected bit key_locked;              // Prevents further key/mode changes.
  protected bit control_start;           // START bit.
  protected bit control_zeroize;         // ZEROIZE bit.
  protected aes_block_t stored_inputs[$];// Complete input blocks waiting for START.
  protected aes_block_t expected_outputs[$]; // Predicted blocks waiting for readout.
  protected bit [3:0] input_words_seen;  // DATA words written for current block.
  protected bit [3:0] output_words_seen; // Output words read for current block.
  protected logic [AES_BLOCK_WIDTH-1:0] actual_output; // Preserve X/Z from DUT reads.
  protected aes_block_t last_output;     // Most recently completed output block for read without new write.
  protected bit operation_pending;       // START issued; awaiting BUSY followed by DONE.
  protected bit operation_busy_seen;     // BUSY observed for the current START.
  protected bit expected_done;           // DONE status.
  protected bit expected_sec;            // SEC must stay high after an error.
  int matched_count;
  int mismatched_count;

  extern function new(string name = "apb_scoreboard", uvm_component parent = null);
  extern virtual function void build_phase(uvm_phase phase);
  extern virtual function void write(apb_slave_tx tx);

  extern protected virtual function void reset_operation_state();
  extern protected virtual function void reset_model_state();
  extern protected virtual function void check_status_register(apb_slave_tx tx); // Check BUSY and DONE.

  extern protected virtual function void handle_write(apb_slave_tx tx); // Update model from a write.
  extern protected virtual function void queue_input_block(); // Save one completed input block.
  extern protected virtual function void start_operation(); // Begin prediction after START.

  extern protected virtual function void handle_read(apb_slave_tx tx); // Check register read.
  extern protected virtual function void check_output_word(apb_slave_tx tx); // Check one output word.
  extern protected virtual function void compare_completed_output(); // Compare one complete output block.

  extern virtual function void check_phase(uvm_phase phase);
  extern virtual function void report_phase(uvm_phase phase);
endclass : apb_scoreboard

function apb_scoreboard::new(string name = "apb_scoreboard", uvm_component parent = null);
  super.new(name, parent);
  apb_analysis_imp = new("apb_analysis_imp", this);
endfunction : new

function void apb_scoreboard::build_phase(uvm_phase phase);
  super.build_phase(phase);
  model = aes_ref_model::type_id::create("model");
  reset_model_state();
endfunction : build_phase

function void apb_scoreboard::reset_operation_state();
  stored_inputs.delete();
  expected_outputs.delete();
  input_words_seen = '0;
  output_words_seen = '0;
  actual_output = '0;
  last_output = '0;
  operation_pending = 0;
  operation_busy_seen = 0;
  expected_done = 0;
endfunction : reset_operation_state

function void apb_scoreboard::reset_model_state();
  key = '0;
  input_block = '0;
  mode = AES_DECRYPT;
  key_locked = 0;
  control_start = 0;
  control_zeroize = 0;
  expected_sec = 0;
  reset_operation_state();
endfunction : reset_model_state

function void apb_scoreboard::check_status_register(apb_slave_tx tx);
  logic busy;
  logic done;

  busy = tx.prdata[AES_STATUS_BUSY_BIT];
  done = tx.prdata[AES_STATUS_DONE_BIT];

  if($isunknown(tx.prdata) || tx.prdata[31:2] !== '0 || (busy && done)) begin
    `uvm_error("AES_STATUS", $sformatf("Invalid STATUS readback: %08h", tx.prdata))
    return;
  end

  if(!operation_pending) begin
    if(busy || done != expected_done) begin
      `uvm_error("AES_STATUS", $sformatf(
        "expected DONE=%0b BUSY=0, actual=%08h", expected_done, tx.prdata))
    end
    return;
  end

  // Allow START synchronization; an old DONE cannot complete this operation.
  operation_busy_seen |= busy;
  if(done && operation_busy_seen) begin
    operation_pending = 0;
    expected_done = 1;
  end
  else if(operation_busy_seen && !busy) begin
    `uvm_error("AES_STATUS", "Pending START reported neither BUSY nor DONE")
  end
endfunction : check_status_register

function void apb_scoreboard::write(apb_slave_tx tx);
  bit valid_address;
  bit sensitive_address;
  slave_error_e expected_error;

  if(tx.preset_n !== 1'b1) begin
    expected_sec = 0;
    return;
  end
  if(tx.crypto_rstn !== 1'b1) return;

  // Check the previous cycle's security result before handling this transfer.
  if(tx.sec_violation !== expected_sec) begin
    `uvm_error("AES_SECURITY", $sformatf(
      "SEC_VIOLATION expected=%0b actual=%0b", expected_sec, tx.sec_violation))
  end
  if(!(tx.psel === 1'b1 && tx.penable === 1'b1 && tx.pready === 1'b1)) return;

  valid_address = (tx.paddr <= AES_DATA_OUT3_ADDR) &&
                  (tx.paddr % AES_WORD_BYTES == 0);
  sensitive_address = valid_address && tx.paddr != AES_STATUS_ADDR &&
                      tx.paddr < AES_DATA_OUT0_ADDR;
  expected_error = (!valid_address ||
                    (sensitive_address && !tx.pprot[0])) ? ERROR : NO_ERROR;

  if(tx.pslverr != expected_error) begin //PSLVERR Check
    `uvm_error("AES_APB_ERROR", $sformatf(
      "addr=%02h expected PSLVERR=%0b actual=%0b",
      tx.paddr, expected_error, tx.pslverr))
  end

  if(expected_error == ERROR || tx.pslverr == ERROR) begin
    if(tx.pwrite == READ && tx.paddr >= AES_KEY0_ADDR &&
       tx.paddr <= AES_KEY3_ADDR && tx.prdata !== 32'b0) begin
      `uvm_error("AES_KEY_READ", "A rejected key read exposed nonzero/unknown data")
    end
    expected_sec = 1;
    return;
  end

  if(tx.pwrite == WRITE) handle_write(tx);
  else handle_read(tx);
endfunction : write

function void apb_scoreboard::handle_write(apb_slave_tx tx);
  int word_index;

  // ZEROIZE has priority over all other control actions.
  if(tx.paddr == AES_CONTROL_ADDR && tx.pwdata[AES_CTRL_ZEROIZE_BIT]) begin
    reset_operation_state();
    input_block = '0;
    control_start = 0;
    control_zeroize = 1;
    if(!key_locked) begin
      key = '0;
      mode = AES_DECRYPT;
    end
    return;
  end

  // The DUT ignores normal writes until the current operation is complete.
  if(operation_pending) begin
    return;
  end

  if(tx.paddr >= AES_KEY0_ADDR && tx.paddr <= AES_KEY3_ADDR) begin //load key
    if(!key_locked) begin
      word_index = (tx.paddr - AES_KEY0_ADDR) / AES_WORD_BYTES;
      key[AES_BLOCK_WIDTH-1-word_index*AES_WORD_WIDTH -: AES_WORD_WIDTH] = tx.pwdata;
    end
  end
  else if(tx.paddr >= AES_DATA0_ADDR && tx.paddr <= AES_DATA3_ADDR) begin //load data_in
    word_index = (tx.paddr - AES_DATA0_ADDR) / AES_WORD_BYTES;
    input_block[AES_BLOCK_WIDTH-1-word_index*AES_WORD_WIDTH -: AES_WORD_WIDTH] = tx.pwdata;
    input_words_seen[word_index] = 1;
    if(&input_words_seen) queue_input_block(); //when all 4 blocks are complete then store the blocks
  end
  else if(tx.paddr == AES_CONTROL_ADDR) begin
    if(!key_locked) mode = aes_mode_e'(tx.pwdata[AES_CTRL_MODE_BIT]);
    key_locked |= tx.pwdata[AES_CTRL_KEY_LOCK_BIT];
    control_start = tx.pwdata[AES_CTRL_START_BIT];
    control_zeroize = 0;
    if(control_start) start_operation();
  end
endfunction : handle_write

function void apb_scoreboard::queue_input_block();
  if(stored_inputs.size() == MAX_BLOCKS) begin
    `uvm_error("AES_CAPACITY", "More than 1024 input blocks were programmed before START")
  end
  else stored_inputs.push_back(input_block);
  input_words_seen = '0;
endfunction : queue_input_block

function void apb_scoreboard::start_operation();
  aes_block_t block_data;
  aes_block_t prediction;

  if(operation_pending) begin
    `uvm_error("AES_START", "Another START arrived before the previous transaction completed")
    return;
  end

  if(input_words_seen != '0 || stored_inputs.size() == 0)
    queue_input_block(); // have a default input block loaded if START arrives before all 4 words are written

  expected_done = 0;
  operation_pending = 1;
  operation_busy_seen = 0;
  while(stored_inputs.size() != 0) begin
    block_data = stored_inputs.pop_front();
    if(expected_outputs.size() == MAX_BLOCKS) begin
      `uvm_error("AES_CAPACITY",
        "Unread results plus the new transaction exceed 1024 blocks")
      continue;
    end

    prediction = (mode == AES_ENCRYPT) ? model.encrypt(block_data, key) :
                                         model.decrypt(block_data, key);
    expected_outputs.push_back(prediction);
  end
endfunction : start_operation

function void apb_scoreboard::handle_read(apb_slave_tx tx);
  int word_index;
  logic [31:0] expected_word;

  expected_word = '0;
  if(tx.paddr == AES_CONTROL_ADDR) begin
    expected_word[AES_CTRL_START_BIT] = control_start;
    expected_word[AES_CTRL_MODE_BIT] = mode;
    expected_word[AES_CTRL_KEY_LOCK_BIT] = key_locked;
    expected_word[AES_CTRL_ZEROIZE_BIT] = control_zeroize;
  end
  else if(tx.paddr == AES_STATUS_ADDR) begin
    check_status_register(tx);
    return;
  end
  else if(tx.paddr >= AES_DATA0_ADDR && tx.paddr <= AES_DATA3_ADDR) begin
    word_index = (tx.paddr - AES_DATA0_ADDR) / AES_WORD_BYTES;
    expected_word = input_block[AES_BLOCK_WIDTH-1-word_index*AES_WORD_WIDTH -: AES_WORD_WIDTH];
  end
  else if(tx.paddr >= AES_DATA_OUT0_ADDR && tx.paddr <= AES_DATA_OUT3_ADDR) begin
    check_output_word(tx);
    return;
  end

  if(tx.prdata !== expected_word) begin
    `uvm_error("AES_READBACK", $sformatf(
      "addr=%02h expected=%08h actual=%08h", tx.paddr, expected_word, tx.prdata))
  end
endfunction : handle_read

function void apb_scoreboard::check_output_word(apb_slave_tx tx);
  int word_index;
  aes_block_t expected_block;

  word_index = (tx.paddr - AES_DATA_OUT0_ADDR) / AES_WORD_BYTES;
  if(expected_outputs.size() == 0) begin
    // If no expected outputs are available, check against the last output
    if(tx.prdata !== last_output[AES_BLOCK_WIDTH-1-word_index*AES_WORD_WIDTH -: AES_WORD_WIDTH]) begin
      `uvm_error("AES_READBACK", $sformatf(
        "addr=%02h expected=%08h actual=%08h",
        tx.paddr,
        last_output[AES_BLOCK_WIDTH-1-word_index*AES_WORD_WIDTH -: AES_WORD_WIDTH],
        tx.prdata))
    end
    return;
  end

  if(operation_pending) begin
    `uvm_error("AES_EARLY_READ",
      "Output read before a successful STATUS read reported DONE")
    return;
  end

  expected_block = expected_outputs[0];
  if(tx.prdata !== expected_block[AES_BLOCK_WIDTH-1-word_index*AES_WORD_WIDTH -: AES_WORD_WIDTH]) begin
    `uvm_error("AES_READBACK", $sformatf(
      "addr=%02h expected=%08h actual=%08h",
      tx.paddr,
      expected_block[AES_BLOCK_WIDTH-1-word_index*AES_WORD_WIDTH -: AES_WORD_WIDTH],
      tx.prdata))
  end

  actual_output[AES_BLOCK_WIDTH-1-word_index*AES_WORD_WIDTH -: AES_WORD_WIDTH] = tx.prdata;
  output_words_seen[word_index] = 1;
  if(&output_words_seen) compare_completed_output();
endfunction : check_output_word

function void apb_scoreboard::compare_completed_output();
  aes_block_t expected_block;

  expected_block = expected_outputs.pop_front();
  if(actual_output === expected_block) begin
    matched_count++;
  end
  else begin
    mismatched_count++;
    `uvm_error("AES_MISMATCH", $sformatf(
      "block=%0d expected=%032h actual=%032h",
      matched_count + mismatched_count, expected_block, actual_output))
  end

  last_output = expected_block;
  output_words_seen = '0;
  actual_output = '0;
endfunction : compare_completed_output

function void apb_scoreboard::check_phase(uvm_phase phase);
  super.check_phase(phase);
  if(operation_pending || expected_outputs.size() != 0) begin
    `uvm_error("AES_INCOMPLETE", $sformatf(
      "End of test: pending=%0b unread blocks=%0d partial output mask=%h",
      operation_pending, expected_outputs.size(), output_words_seen))
  end
endfunction : check_phase

function void apb_scoreboard::report_phase(uvm_phase phase);
  super.report_phase(phase);
  `uvm_info("AES_SCOREBOARD",
    $sformatf("matched=%0d mismatched=%0d", matched_count, mismatched_count), UVM_LOW)
endfunction : report_phase

`endif