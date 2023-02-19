///////////////////////////////////////////////////////////////////////////////
// Author: Will Chen
//
// Description:
//    * Driver component of register bus interface agent
///////////////////////////////////////////////////////////////////////////////


class reg_driver extends uvm_driver #(reg_rw_item);
    virtual reg_if reg_vif;  // Virtual interface with DUT

    `uvm_component_utils(reg_driver);  // Register component with factory

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction : new

    function void build_phase(uvm_phase phase);
        if (!uvm_config_db#(virtual reg_if)::get(this, "", "reg_vif", reg_vif)) begin
            `uvm_fatal("DRVCFG", "No virtual interface object passed!");
        end
    endfunction : build_phase

    virtual task run_phase(uvm_phase phase);
        forever begin
            seq_item_port.get_next_item(req);  // Blocking 'get'
            send_item(req);  // Drive transaction into DUT
            seq_item_port.item_done();  // Indicate to sequence that driver has completed processing
        end
    endtask : run_phase

    virtual task send_item(reg_rw_item tr);
        `uvm_info("DRV",
                  $sformatf("Driving register transaction kind %0d, address 0x%0h, data 0x%0h...",
                            tr.kind, tr.addr, tr.data),
                  UVM_MEDIUM);
        @(posedge reg_vif.clk);
        reg_vif.reg_rd_en <= (tr.kind == UVM_READ);
        reg_vif.reg_wr_en <= (tr.kind == UVM_WRITE);
        reg_vif.reg_addr  <= tr.addr;
        if (tr.kind == UVM_WRITE) begin
            reg_vif.reg_wr_data <= tr.data;  // Drive write data
        end
        else if (tr.kind == UVM_READ) begin
            @(posedge reg_vif.clk);
            tr.data = reg_vif.reg_rd_data;  // Sample read data
        end
    endtask : send_item
endclass : reg_driver
