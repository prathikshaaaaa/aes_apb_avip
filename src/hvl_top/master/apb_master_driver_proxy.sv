`ifndef APB_MASTER_DRIVER_PROXY_INCLUDED_
`define APB_MASTER_DRIVER_PROXY_INCLUDED_

class apb_master_driver_proxy extends uvm_driver #(apb_master_tx);
  `uvm_component_utils(apb_master_driver_proxy)
  virtual apb_master_driver_bfm apb_master_drv_bfm_h;

  function new(string name = "apb_master_driver_proxy", uvm_component parent);
    super.new(name, parent);
  endfunction

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db #(virtual apb_master_driver_bfm)::get(
          this, "", "apb_master_driver_bfm", apb_master_drv_bfm_h)) begin
      `uvm_fatal("APB_MASTER_DRIVER_BFM", "Cannot get the master driver BFM")
    end
  endfunction

  virtual task run_phase(uvm_phase phase);
    wait (apb_master_drv_bfm_h.preset_n === 1'b1);
    forever begin
      aes_transfer_char_s packet;
      @(posedge apb_master_drv_bfm_h.pclk);
      req = null;
      seq_item_port.try_next_item(req);
      while (req != null) begin
        `uvm_info(get_type_name(), $sformatf("Driving %s at address 0x%0h", req.pwrite.name(), req.paddr), UVM_HIGH)
        apb_master_seq_item_converter::from_class(req, packet);
        apb_master_drv_bfm_h.drive_to_bfm(packet);
        req.prdata = packet.prdata;

        `uvm_info(get_type_name(), $sformatf("Completed %s at address 0x%0h", req.pwrite.name(), req.paddr), UVM_HIGH)
        seq_item_port.item_done();
        req = null;
        seq_item_port.try_next_item(req);
      end
      apb_master_drv_bfm_h.drive_idle_state();
    end
  endtask
endclass : apb_master_driver_proxy

`endif
