`include "uvm_macros.svh"

module tbench_top();
    import uvm_pkg::*;
    import lab4_pkg::*;

    bit clk = 0;
    bit reset = 1;


intf dut_if1 (
    .clk(clk),
    .reset(reset)
);
  
dut_top dut_core(
    .intf_inst(dut_if1)
);
  // Clock and reset generator
  initial
  begin
    clk = 0;
    forever #5 clk = ~clk;
  end

  initial
  begin
    #5 if (reset == 1)begin
        reset = 0; 
  end
  end

  initial
  begin: blk
     uvm_config_db #(virtual intf)::set(null, "uvm_test_top","dut_vi", dut_if1);
     uvm_top.finish_on_completion  = 1;
     run_test();
  end
endmodule: tbench_top
