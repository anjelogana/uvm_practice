// ================================================
// helloworld.sv -- Minimal UVM Hello World
// ================================================
`include "uvm_macros.svh"
import uvm_pkg::*;

// 1. Define a custom test class
class hello_test extends uvm_test;
    `uvm_component_utils(hello_test)

    function new(string name = "hello_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    task run_phase(uvm_phase phase);
        phase.raise_objection(this);
        `uvm_info("HELLO", "Hello from UVM!", UVM_LOW)
        `uvm_info("HELLO", "UVM phase system is working!", UVM_LOW)
        phase.drop_objection(this);
    endtask
endclass

// 2. Top-level module -- simulation entry point
module top;
    initial begin
        run_test("hello_test");
    end
endmodule