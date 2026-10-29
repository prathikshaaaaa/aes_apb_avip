`ifndef APB_SLAVE_PKG_INCLUDED_
`define APB_SLAVE_PKG_INCLUDED_

package apb_slave_pkg;
  `include "uvm_macros.svh"
  import uvm_pkg::*;
  import aes_global_pkg::*;
  `include "apb_slave_tx.sv"
  `include "apb_slave_seq_item_converter.sv"
  `include "apb_slave_monitor_proxy.sv"
  `include "apb_slave_coverage.sv"
  `include "apb_slave_agent.sv"
  
endpackage : apb_slave_pkg

`endif

