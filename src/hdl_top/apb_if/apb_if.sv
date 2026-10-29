`ifndef APB_IF_INCLUDED_
`define APB_IF_INCLUDED_

interface apb_if (input pclk, input preset_n);
  import aes_global_pkg::*;
  
  logic psel;
  logic penable;  
  logic [ADDRESS_WIDTH-1:0]paddr;
  logic pwrite;
  logic [DATA_WIDTH-1:0]pwdata;
  logic pready;
  logic [DATA_WIDTH-1:0]prdata;
  logic pslverr;
  logic [2:0]pprot; 

  // AES signals
  logic crypto_rstn;
  logic sec_violation;

  // All interface assertions use the APB clock and are disabled during reset.
  default clocking apb_assertion_clock @(posedge pclk); endclocking
  default disable iff (preset_n !== 1'b1);

  logic completed, valid_address, key_address, sensitive_address, unauthorized;

  assign completed = psel && penable && pready;
  assign valid_address = (paddr <= AES_DATA_OUT3_ADDR) && (paddr % AES_WORD_BYTES == 0);
  assign key_address = (paddr == AES_KEY0_ADDR) || (paddr == AES_KEY1_ADDR) ||
                     (paddr == AES_KEY2_ADDR) || (paddr == AES_KEY3_ADDR);
  assign sensitive_address = valid_address && (paddr != AES_STATUS_ADDR) &&
                           (paddr < AES_DATA_OUT0_ADDR); // PRIVELEGED ACCESS ADDRESS
  assign unauthorized = completed && sensitive_address && !pprot[0];

  // Unknown values are not allowed on the APB interface outside of reset.
  AST01_X_CHECK: assert property ((preset_n === 1'b1) |->
    !$isunknown({psel, penable, pwrite, paddr, pwdata, pprot,
                 prdata, pready, pslverr, sec_violation}))
    else $error("AST01: APB interface contains an X/Z value outside reset");

  // SETUP --> ACCESS penable, then PENABLE clears after completion.
  AST02_SETUP_TO_ACCESS: assert property ((psel && !penable) |=> (psel && penable)) //1 Cycle
    else $error("AST02: SETUP was not followed by ACCESS");
  AST02_ENABLE_CLEARS: assert property (completed |=> !penable)
    else $error("AST02: PENABLE remained asserted after a completed transfer");

  // the request stays stable between SETUP and ACCESS.
  AST03_SETUP_STABLE: assert property ((psel && !penable) |=>
    $stable({psel, paddr, pwrite, pprot}) && (!pwrite || $stable(pwdata)))
    else $error("AST03: APB request changed between SETUP and ACCESS");

  // this AES slave has no APB wait states.
  AST04_ALWAYS_READY: assert property ((preset_n === 1'b1) |-> (pready === 1'b1))
    else $error("AST04: PREADY is not high");

  // key register reads return zero
  AST05_KEY_READ_ZERO: assert property ((completed && !pwrite && key_address) |-> (prdata === 32'h0))
    else $error("AST05: key-register read did not return zero");

  // privilege access errors
  AST06_PRIVILEGE_ERROR: assert property (unauthorized |-> (pslverr === 1'b1))
    else $error("AST06: unprivileged secure-register access did not assert PSLVERR");
  AST06_PRIVILEGE_SECURITY: assert property (unauthorized |=> (sec_violation === 1'b1))
    else $error("AST06: unprivileged secure-register access did not assert SEC_VIOLATION");

  // only APB reset may clear the sticky security flag.
  AST07_SECURITY_STICKY: assert property ((sec_violation === 1'b1) |=> (sec_violation === 1'b1)) // On Reset this assertion will be disabled
    else $error("AST07: SEC_VIOLATION cleared without APB reset");

  // unmapped and unaligned accesses must report an error and assert SEC.
  AST08_INVALID_ADDRESS_ERROR: assert property ((completed && !valid_address) |-> (pslverr === 1'b1))
    else $error("AST08: invalid register access did not assert PSLVERR");
  AST08_INVALID_ADDRESS_SECURITY: assert property ((completed && !valid_address) |=> (sec_violation === 1'b1))
    else $error("AST08: invalid register access did not assert SEC_VIOLATION");

  // STATUS reads cannot report BUSY and DONE together.
  AST09_BUSY_DONE_EXCLUSIVE: assert property (
    (completed && !pwrite && paddr == AES_STATUS_ADDR && !pslverr) |->
    !(prdata[AES_STATUS_BUSY_BIT] && prdata[AES_STATUS_DONE_BIT]))
    else $error("AST09: STATUS.BUSY and STATUS.DONE are both high");
  
endinterface : apb_if
 
`endif

