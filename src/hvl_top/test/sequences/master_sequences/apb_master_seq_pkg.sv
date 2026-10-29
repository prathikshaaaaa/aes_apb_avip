`ifndef APB_MASTER_SEQ_PKG_INCLUDED_
`define APB_MASTER_SEQ_PKG_INCLUDED_

package apb_master_seq_pkg;
  `include "uvm_macros.svh"
  import uvm_pkg::*;
  import aes_global_pkg::*;
  import apb_master_pkg::*;
  `include "apb_master_base_seq.sv"
endpackage : apb_master_seq_pkg

`endif
