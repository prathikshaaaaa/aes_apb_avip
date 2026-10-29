`ifndef AES_SEQ_PKG_INCLUDED_
`define AES_SEQ_PKG_INCLUDED_

package aes_seq_pkg;
  timeunit 1ps;
  timeprecision 1ps;
  `include "uvm_macros.svh"
  import uvm_pkg::*;
  import aes_global_pkg::*;
  import apb_master_pkg::*;
  import apb_master_seq_pkg::*;

  `include "aes_reset_seq.sv"
  `include "aes_encrypt_seq.sv"
  `include "aes_decrypt_seq.sv"
  `include "aes_multiblock_encrypt_seq.sv"
  `include "aes_multiblock_decrypt_seq.sv"
  `include "aes_key_read_seq.sv"
  `include "aes_read_only_seq.sv"
  `include "aes_key_lock_seq.sv"
  `include "aes_zeroize_seq.sv"
  `include "aes_locked_zeroize_seq.sv"
  `include "aes_unprivileged_write_seq.sv"
  `include "aes_public_read_seq.sv"
  `include "aes_security_sticky_seq.sv"
  `include "aes_invalid_address_seq.sv"
  `include "aes_status_seq.sv"
  `include "aes_output_spacing_seq.sv"
  `include "aes_uninitialized_seq.sv"
  `include "aes_capacity_seq.sv"
  `include "aes_consecutive_seq.sv"
  `include "aes_reset_during_operation_seq.sv"
  `include "aes_apb_reset_seq.sv"
  `include "aes_crypto_reset_seq.sv"
endpackage : aes_seq_pkg

`endif
