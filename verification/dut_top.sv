module dut_top(intf.DUT intf_inst);
    xswitch xswitch_inst (
        .clk(intf_inst.clk),
        .reset(intf_inst.reset),
        .data_in(intf_inst.data_in),
        .addr_in(intf_inst.addr_in),
        .rcv_rdy(intf_inst.rcv_rdy),
        .valid_in(intf_inst.valid_in),
        .data_out(intf_inst.data_out),
        .addr_out(intf_inst.addr_out),
        .data_read(intf_inst.data_read),
        .data_rdy(intf_inst.data_rdy)
    );
endmodule

