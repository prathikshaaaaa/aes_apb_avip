`ifndef APB_TEST_PKG_INCLUDED_
`define APB_TEST_PKG_INCLUDED_

package apb_test_pkg;

  `include "uvm_macros.svh"
  import uvm_pkg::*;
  import aes_global_pkg::*;
  import apb_master_pkg::*;
  import apb_slave_pkg::*;
  import apb_env_pkg::*;
  import apb_master_seq_pkg::*;
  import aes_seq_pkg::*;
  
  `include "apb_base_test.sv"
  `include "aes_reset_test.sv"
  `include "aes_encrypt_test.sv"
  `include "aes_decrypt_test.sv"
  `include "aes_multiblock_encrypt_test.sv"
  `include "aes_multiblock_decrypt_test.sv"
  `include "aes_key_read_test.sv"
  `include "aes_read_only_test.sv"
  `include "aes_key_lock_test.sv"
  `include "aes_zeroize_test.sv"
  `include "aes_locked_zeroize_test.sv"
  `include "aes_unprivileged_write_test.sv"
  `include "aes_public_read_test.sv"
  `include "aes_security_sticky_test.sv"
  `include "aes_invalid_address_test.sv"
  `include "aes_status_test.sv"
  `include "aes_output_spacing_test.sv"
  `include "aes_uninitialized_test.sv"
  `include "aes_capacity_test.sv"
  `include "aes_consecutive_test.sv"
  `include "aes_reset_during_operation_test.sv"
  `include "aes_apb_reset_test.sv"
  `include "aes_crypto_reset_test.sv"

endpackage : apb_test_pkg

`endif

