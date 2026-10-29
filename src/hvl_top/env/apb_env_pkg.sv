`ifndef APB_ENV_PKG_INCLUDED_
`define APB_ENV_PKG_INCLUDED_

package apb_env_pkg;

  `include "uvm_macros.svh"
  import uvm_pkg::*;

  import aes_global_pkg::*;
  import apb_master_pkg::*;
  import apb_slave_pkg::*;

  `include "aes_ref_model.sv"
  `include "apb_scoreboard.sv"
  `include "apb_env.sv"

endpackage : apb_env_pkg

`endif

