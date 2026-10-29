`ifndef APB_MASTER_MONITOR_PROXY_INCLUDED_
`define APB_MASTER_MONITOR_PROXY_INCLUDED_

class apb_master_monitor_proxy extends uvm_monitor;
  `uvm_component_utils(apb_master_monitor_proxy)
  virtual apb_master_monitor_bfm apb_master_mon_bfm_h;

  function new(string name = "apb_master_monitor_proxy", uvm_component parent);
    super.new(name, parent);
  endfunction

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db #(virtual apb_master_monitor_bfm)::get(
          this, "", "apb_master_monitor_bfm", apb_master_mon_bfm_h)) begin
      `uvm_fatal("APB_MASTER_MONITOR_BFM", "Cannot get the master monitor BFM")
    end
  endfunction

  virtual task run_phase(uvm_phase phase);
    wait (apb_master_mon_bfm_h.preset_n === 1'b1);
    forever begin
      aes_transfer_char_s observed;
      apb_master_tx packet;
      apb_master_mon_bfm_h.sample_data(observed);
      packet = apb_master_tx::type_id::create("master_packet");
      apb_master_seq_item_converter::to_class(observed, packet);
      `uvm_info(get_type_name(), $sformatf("Observed completed APB request\n%s", packet.sprint()), UVM_HIGH)
    end
  endtask
endclass : apb_master_monitor_proxy

`endif
