`ifndef HVL_TOP_INCLUDED_
`define HVL_TOP_INCLUDED_

module hvl_top;
  import uvm_pkg::*;
  import apb_test_pkg::*;

  initial begin
    run_test("aes_encrypt_test");
  end

endmodule : hvl_top

`endif

