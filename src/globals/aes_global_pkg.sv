`ifndef AES_GLOBAL_PKG_INCLUDED_
`define AES_GLOBAL_PKG_INCLUDED_

package aes_global_pkg;

  parameter int ADDRESS_WIDTH = 8;
  parameter int DATA_WIDTH = 32;

  typedef enum bit {
    NO_ERROR = 1'b0,
    ERROR = 1'b1
  } slave_error_e;

  typedef enum bit {
    WRITE = 1'b1,
    READ = 1'b0
  } tx_type_e;

  // PPROT: [2] instruction, [1] nonsecure, [0] privileged.
  typedef enum logic [2:0] {
    NORMAL_SECURE_DATA              = 3'b000,
    NORMAL_SECURE_INSTRUCTION       = 3'b100,
    NORMAL_NONSECURE_DATA           = 3'b010,
    NORMAL_NONSECURE_INSTRUCTION    = 3'b110,
    PRIVILEGED_SECURE_DATA          = 3'b001,
    PRIVILEGED_SECURE_INSTRUCTION   = 3'b101,
    PRIVILEGED_NONSECURE_DATA        = 3'b011,
    PRIVILEGED_NONSECURE_INSTRUCTION = 3'b111
  } protection_type_e;

  typedef struct {
    bit pwrite;
    bit pslverr;
    bit [2:0] pprot;
    logic psel;
    logic penable;
    logic pready;
    logic preset_n;
    logic crypto_rstn;
    logic sec_violation;
    logic [DATA_WIDTH-1:0] prdata; //to identify invalid reads
    bit [ADDRESS_WIDTH-1:0] paddr;
    bit [DATA_WIDTH-1:0] pwdata;
  } aes_transfer_char_s;

  parameter int AES_BLOCK_WIDTH = 128;
  parameter int AES_WORD_WIDTH = 32;
  parameter int AES_WORDS_PER_BLOCK = AES_BLOCK_WIDTH / AES_WORD_WIDTH;
  parameter int AES_WORD_BYTES = AES_WORD_WIDTH / 8;

  typedef bit [AES_BLOCK_WIDTH-1:0] aes_block_t;
  typedef enum bit {AES_DECRYPT = 1'b0, AES_ENCRYPT = 1'b1} aes_mode_e;

  parameter bit [7:0] AES_CONTROL_ADDR   = 8'h00;
  parameter bit [7:0] AES_STATUS_ADDR    = 8'h04;
  parameter bit [7:0] AES_KEY0_ADDR      = 8'h08;
  parameter bit [7:0] AES_KEY1_ADDR      = 8'h0c;
  parameter bit [7:0] AES_KEY2_ADDR      = 8'h10;
  parameter bit [7:0] AES_KEY3_ADDR      = 8'h14;
  parameter bit [7:0] AES_DATA0_ADDR     = 8'h18;
  parameter bit [7:0] AES_DATA1_ADDR     = 8'h1c;
  parameter bit [7:0] AES_DATA2_ADDR     = 8'h20;
  parameter bit [7:0] AES_DATA3_ADDR     = 8'h24;
  parameter bit [7:0] AES_DATA_OUT0_ADDR = 8'h28;
  parameter bit [7:0] AES_DATA_OUT1_ADDR = 8'h2c;
  parameter bit [7:0] AES_DATA_OUT2_ADDR = 8'h30;
  parameter bit [7:0] AES_DATA_OUT3_ADDR = 8'h34;

  parameter int AES_CTRL_START_BIT = 0;
  parameter int AES_CTRL_MODE_BIT = 1;
  parameter int AES_CTRL_KEY_LOCK_BIT = 2;
  parameter int AES_CTRL_ZEROIZE_BIT = 3;
  parameter int AES_STATUS_DONE_BIT = 0;
  parameter int AES_STATUS_BUSY_BIT = 1;

endpackage : aes_global_pkg

`endif
