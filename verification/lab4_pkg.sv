`include "uvm_macros.svh"
`include "debug.svh"

package lab4_pkg;
  import uvm_pkg::*;
  import sequencer::*;

  typedef sequencer::transaction transaction;

  typedef uvm_sequencer #(transaction) my_sequencer;

  class my_dut_config extends uvm_object;
     `uvm_object_utils(my_dut_config)

    function new(string name = "");
      super.new(name);
    endfunction
      
     virtual intf dut_vi;     
  endclass: my_dut_config
   
  class driver extends uvm_driver #(transaction);
  
    `uvm_component_utils(driver)

     my_dut_config dut_config_0;
     virtual intf.DRIV dut_vi;

    function new(string name, uvm_component parent);
      super.new(name, parent);
    endfunction: new
    
    function void build_phase(uvm_phase phase);
       assert( uvm_config_db #(my_dut_config)::get(this, "", "dut_config", 
						   dut_config_0) );
       dut_vi = dut_config_0.dut_vi;
       // other config settings from dut_config_0 object as needed
    endfunction : build_phase
   

    task run_phase(uvm_phase phase);
      forever
      begin
        transaction tx;
        
        seq_item_port.get(tx);
        @ dut_vi.cb_out
          dut_vi.cb_out.data_in   <= tx.data_in;
          dut_vi.cb_out.addr_in   <= tx.addr_in;
          dut_vi.cb_out.valid_in  <= tx.valid_in;
          dut_vi.cb_out.data_read <= tx.data_read;


          if (`_DEBUG_DRIV_)
           `uvm_info("Driver", $psprintf("driver received tx %s", tx.convert2string()), UVM_NONE);
          if(`_ADVANCED_DEBUG_)
            `uvm_info("Driver", $psprintf("driver received tx %s", tx.convert2string()), UVM_NONE);


      end
    endtask: run_phase
  endclass: driver

  class monitor extends uvm_monitor;
  
    `uvm_component_utils(monitor)

     uvm_analysis_port #(transaction) aport;
    
     my_dut_config dut_config_0;
     virtual intf.MON dut_vi;

    function new(string name, uvm_component parent);
      super.new(name, parent);
    endfunction: new
    
    function void build_phase(uvm_phase phase);
       dut_config_0 = my_dut_config::type_id::create("config");
       aport = new("aport", this);
       assert( uvm_config_db #(my_dut_config)::get(this, "", "dut_config", dut_config_0) );
       dut_vi = dut_config_0.dut_vi;
    endfunction : build_phase
   
    task run_phase(uvm_phase phase);
      
      forever
      begin
        transaction tx1;
        tx1 = transaction::type_id::create("tx1");
        tx1.data_in    = dut_vi.cb_in.data_in  ;
        tx1.addr_in    = dut_vi.cb_in.addr_in  ;
        tx1.valid_in   = dut_vi.cb_in.valid_in ;
        tx1.data_read  = dut_vi.cb_in.data_read;
        tx1.reset = dut_vi.reset;

        @( dut_vi.cb_in);
        tx1.addr_out   = dut_vi.cb_in.addr_out ;
        tx1.data_out   = dut_vi.cb_in.data_out ;
        tx1.rcv_rdy    = dut_vi.cb_in.rcv_rdy  ;
        tx1.data_rdy   = dut_vi.cb_in.data_rdy ;
        
        aport.write(tx1);


        if (`_DEBUG_MON_)begin
          `uvm_info("Moniter", $psprintf("Moniter tx1 %s", tx1.convert2string()), UVM_NONE);
        end
        if(`_ADVANCED_DEBUG_)begin
          `uvm_info("Moniter", $psprintf("Moniter tx1 %s", tx1.convert2string()), UVM_NONE);
        end

      end
    endtask: run_phase
  endclass: monitor

  class agent extends uvm_agent;

    `uvm_component_utils(agent)
    
    uvm_analysis_port #(transaction) aport;
    
    my_sequencer sequencer_h;
    driver    driver_h;
    monitor   monitor_h;
    
    function new(string name, uvm_component parent);
      super.new(name, parent);
    endfunction: new
    
    function void build_phase(uvm_phase phase);
       aport = new("aport", this);
       sequencer_h = my_sequencer::type_id::create("sequencer_h", this);
       driver_h    = driver   ::type_id::create("driver_h"   , this);
       monitor_h   = monitor  ::type_id::create("monitor_h"  , this);
    endfunction: build_phase
    
    function void connect_phase(uvm_phase phase);
      driver_h.seq_item_port.connect( sequencer_h.seq_item_export );
      monitor_h.       aport.connect( aport );
    endfunction: connect_phase
  endclass: agent
  
  class scoreboard extends uvm_subscriber #(transaction);
  
    `uvm_component_utils(scoreboard)

    // count the number of transaction
    int no_transactions = -1;
    // test cases count 
    int addr_pass_counter ,addr_err_counter, data_pass_counter ,data_err_counter,data_rdy_pass_counter ,data_rdy_err_counter,rcv_rdy_pass_counter, rcv_rdy_err_counter; 
    // creat mailbox handle 
    mailbox mon2scb;
    // needed connections 
    logic [`_BIT_SIZE_ADDR_ - 1:0] SCB_addr;
    logic [`_BIT_SIZE_DATA_ - 1:0] SCB_data_out;
    // logic [15:0] ;
    bit [`_PORT_NUMBER_ - 1:0] SCB_data_rdy, prev_data_read, prev_data_rdy  ;
    bit [`_PORT_NUMBER_ - 1:0] SCB_rcv_rdy ;

    int i ,j ,k ,h ,flag_a = 0;

    
    function new(string name, uvm_component parent);
      super.new(name, parent);
    endfunction: new

    function void write(transaction t);
      // `uvm_info("mg", $psprintf("scoreboard received tx %s", t.convert2string()), UVM_NONE);
      
      begin
        begin 
        if (!t.reset)begin
            begin
                for ( i=0 ; i < `_FOR_LOOP_ ; i++)begin
                    for ( j=0 ; j < `_FOR_LOOP_ ; j++)begin
                        if ((t.valid_in[j] == 1)&&(t.addr_in[`_FOR_LOOP_*j +:`_PORT_SIZE_] == i)) begin
                            SCB_data_rdy [i] = 1;   
                            if ((prev_data_rdy[i] && t.data_read[i] )|| ((!prev_data_rdy[i] )))begin
                                SCB_addr[`_FOR_LOOP_*i +:`_PORT_SIZE_] = j;
                                SCB_data_out [`_FOR_LOOP_*i +:`_PORT_SIZE_] = t.data_in[`_FOR_LOOP_*j +:`_PORT_SIZE_];
                            end
                        break;
                        end
                    end
                    begin
                    if ( j == `_FOR_LOOP_ )    
                        if (t.data_read[i]) SCB_data_rdy [i] = 0;  
                        else SCB_data_rdy [i] = SCB_data_rdy [i];   
                    end
                end
            end
            begin
                for( h = 0; h < `_FOR_LOOP_; h++ )begin
                    flag_a = 0;  
                    for(k = 0; k < `_FOR_LOOP_; k ++) begin
                        if ((t.valid_in[k] == 1) && (t.addr_in[k*`_FOR_LOOP_ +: `_PORT_SIZE_] == h)) begin
                            if (((prev_data_rdy[h] && t.data_read[h] )|| ((!prev_data_rdy[h] )))&&(!flag_a))begin
                                SCB_rcv_rdy[k] = 1;
                                flag_a = 1;
                            end
                            else SCB_rcv_rdy[k] = 0;
                        end 
                    end
                    if (k == `_FOR_LOOP_) SCB_rcv_rdy[k] = SCB_rcv_rdy[k];
                end
            end
        end
        else 
        begin
            SCB_rcv_rdy = 4'b1111;
            SCB_data_rdy = 4'b0000;
            SCB_addr = 16'hzzzz;
            SCB_data_out = 16'hzzzz;
        end
        end
    
        if (SCB_addr === t.addr_out) addr_pass_counter ++;
        else begin
          begin if (`_SHOW_ALL_ERR_ || `_ADDR_OUT_ERR_)begin
          if(SCB_addr[`_FOR_LOOP_*0 +:`_PORT_SIZE_] !== t.addr_out[`_FOR_LOOP_*0 +:`_PORT_SIZE_]) 
            `uvm_error("addr_out err port 0", $psprintf("\n[addr_out ]:\nexpected from port 0 --> %1h; result from port 0 --> %1h", SCB_addr[`_FOR_LOOP_*0 +:`_PORT_SIZE_], t.addr_out[`_FOR_LOOP_*0 +:`_PORT_SIZE_]));
          if(SCB_addr[`_FOR_LOOP_*1 +:`_PORT_SIZE_] !== t.addr_out[`_FOR_LOOP_*1 +:`_PORT_SIZE_])  
            `uvm_error("addr_out err port 1", $psprintf("\n[addr_out]:\nexpected from port 1 --> %1h; result from port 1 --> %1h", SCB_addr[`_FOR_LOOP_*1 +:`_PORT_SIZE_], t.addr_out[`_FOR_LOOP_*1 +:`_PORT_SIZE_]));
          if(SCB_addr[`_FOR_LOOP_*2 +:`_PORT_SIZE_] !== t.addr_out[`_FOR_LOOP_*2 +:`_PORT_SIZE_])  
            `uvm_error("addr_out err port 2", $psprintf("\n[addr_out]:\nexpected from port 2 --> %1h; result from port 2 --> %1h", SCB_addr[`_FOR_LOOP_*2 +:`_PORT_SIZE_], t.addr_out[`_FOR_LOOP_*2 +:`_PORT_SIZE_]));
          if(SCB_addr[`_FOR_LOOP_*3 +:`_PORT_SIZE_] !== t.addr_out[`_FOR_LOOP_*3 +:`_PORT_SIZE_])  
            `uvm_error("addr_out err port 3", $psprintf("\n[addr_out]:\nexpected from port 3 --> %1h; result from port 3 --> %1h", SCB_addr[`_FOR_LOOP_*3 +:`_PORT_SIZE_], t.addr_out[`_FOR_LOOP_*3 +:`_PORT_SIZE_]));
          end
          addr_err_counter++;
          end end
        if (SCB_data_out === t.data_out) data_pass_counter ++;
        else begin
          begin if (`_SHOW_ALL_ERR_ || `_DATA_OUT_ERR_)begin
          if(SCB_data_out[`_FOR_LOOP_*0 +:`_PORT_SIZE_] !== t.data_out[`_FOR_LOOP_*0 +:`_PORT_SIZE_]) 
            `uvm_error("data_out err port 0", $psprintf("\n[data_out ]:\nexpected from port 0 --> %1h; result from port 0 --> %1h", SCB_data_out[`_FOR_LOOP_*0 +:`_PORT_SIZE_], t.data_out[`_FOR_LOOP_*0 +:`_PORT_SIZE_]));
          if(SCB_data_out[`_FOR_LOOP_*1 +:`_PORT_SIZE_] !== t.data_out[`_FOR_LOOP_*1 +:`_PORT_SIZE_])  
            `uvm_error("data_out err port 1", $psprintf("\n[data_out]:\nexpected from port 1 --> %1h; result from port 1 --> %1h", SCB_data_out[`_FOR_LOOP_*1 +:`_PORT_SIZE_], t.data_out[`_FOR_LOOP_*1 +:`_PORT_SIZE_]));
          if(SCB_data_out[`_FOR_LOOP_*2 +:`_PORT_SIZE_] !== t.data_out[`_FOR_LOOP_*2 +:`_PORT_SIZE_])  
            `uvm_error("data_out err port 2", $psprintf("\n[data_out]:\nexpected from port 2 --> %1h; result from port 2 --> %1h", SCB_data_out[`_FOR_LOOP_*2 +:`_PORT_SIZE_], t.data_out[`_FOR_LOOP_*2 +:`_PORT_SIZE_]));
          if(SCB_data_out[`_FOR_LOOP_*3 +:`_PORT_SIZE_] !== t.data_out[`_FOR_LOOP_*3 +:`_PORT_SIZE_])  
            `uvm_error("data_out err port 3", $psprintf("\n[data_out]:\nexpected from port 3 --> %1h; result from port 3 --> %1h", SCB_data_out[`_FOR_LOOP_*3 +:`_PORT_SIZE_], t.data_out[`_FOR_LOOP_*3 +:`_PORT_SIZE_]));
          end end
        data_err_counter++;
        end
        if (SCB_data_rdy === t.data_rdy) data_rdy_pass_counter ++;
        else begin
          begin if (`_SHOW_ALL_ERR_ || `_DATA_RDY_ERR_)begin
          if(SCB_data_rdy[0] !== t.data_rdy[0]) 
            `uvm_error("data_rdy err port 0", $psprintf("\n[data_rdy ]:\nexpected from port 0 --> %1h; result from port 0 --> %1h", SCB_data_rdy[0], t.data_rdy[0]));
          if(SCB_data_rdy[1] !== t.data_rdy[1])  
            `uvm_error("data_rdy err port 1", $psprintf("\n[data_rdy]:\nexpected from port 1 --> %1h; result from port 1 --> %1h", SCB_data_rdy[1], t.data_rdy[1]));
          if(SCB_data_rdy[2] !== t.data_rdy[2])  
            `uvm_error("data_rdy err port 2", $psprintf("\n[data_rdy]:\nexpected from port 2 --> %1h; result from port 2 --> %1h", SCB_data_rdy[2], t.data_rdy[2]));
          if(SCB_data_rdy[3] !== t.data_rdy[3])  
            `uvm_error("data_rdy err port 3", $psprintf("\n[data_rdy]:\nexpected from port 3 --> %1h; result from port 3 --> %1h", SCB_data_rdy[3], t.data_rdy[3]));
          end end
        data_rdy_err_counter++;
        end
        if (SCB_rcv_rdy === t.rcv_rdy) rcv_rdy_pass_counter ++;
        else  begin
          begin if (`_SHOW_ALL_ERR_ || `_RCV_RDY_ERR_)begin
          if(SCB_rcv_rdy[0] !== t.rcv_rdy[0]) 
            `uvm_error("rcv_rdy err port 0", $psprintf("\n[rcv_rdy ]:\nexpected from port 0 --> %1h; result from port 0 --> %1h", SCB_rcv_rdy[0], t.rcv_rdy[0]));
          if(SCB_rcv_rdy[1] !== t.rcv_rdy[1])  
            `uvm_error("rcv_rdy err port 1", $psprintf("\n[rcv_rdy]:\nexpected from port 1 --> %1h; result from port 1 --> %1h", SCB_rcv_rdy[1], t.rcv_rdy[1]));
          if(SCB_rcv_rdy[2] !== t.rcv_rdy[2])  
            `uvm_error("rcv_rdy err port 2", $psprintf("\n[rcv_rdy]:\nexpected from port 2 --> %1h; result from port 2 --> %1h", SCB_rcv_rdy[2], t.rcv_rdy[2]));
          if(SCB_rcv_rdy[3] !== t.rcv_rdy[3])  
            `uvm_error("rcv_rdy err port 3", $psprintf("\n[rcv_rdy]:\nexpected from port 3 --> %1h; result from port 3 --> %1h", SCB_rcv_rdy[3], t.rcv_rdy[3]));
          end end
        rcv_rdy_err_counter++;
        end
        begin
        if (`_DEBUG_SCB_) 


         `uvm_info("Scoreboard",$psprintf("\n[Scoreboard]:\n+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++\n| addr_in  : %4h, DUT_addr_out: %4h, SCB_addr_out: %4h |\n| data_in  : %4h, DUT_data_out: %4h, SCB_data_out: %4h |\n| valid_in : %4b, DUT_data_rdy: %4b, SCB_data_rdy: %4b |\n| data_read: %4b, DUT_rcv_rdy : %4b, SCB_rcv_rdy : %4b |\n+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++\n",t.addr_in, t.addr_out, SCB_addr,t.data_in, t.data_out, SCB_data_out,t.valid_in,t.data_rdy, SCB_data_rdy,t.data_read,t.rcv_rdy, SCB_rcv_rdy), UVM_NONE);
        if (`_ADVANCED_DEBUG_)  
         `uvm_info("Scoreboard",$psprintf("\n[Scoreboard]:\n+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++\n| addr_in  : %4h, DUT_addr_out: %4h, SCB_addr_out: %4h |\n| data_in  : %4h, DUT_data_out: %4h, SCB_data_out: %4h |\n| valid_in : %4b, DUT_data_rdy: %4b, SCB_data_rdy: %4b |\n| data_read: %4b, DUT_rcv_rdy : %4b, SCB_rcv_rdy : %4b |\n+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++\n",t.addr_in, t.addr_out, SCB_addr,t.data_in, t.data_out, SCB_data_out,t.valid_in,t.data_rdy, SCB_data_rdy,t.data_read,t.rcv_rdy, SCB_rcv_rdy), UVM_NONE);
        end 
   
        prev_data_rdy = SCB_data_rdy;
        prev_data_read= t.data_read;

        no_transactions++;
    end 
    endfunction: write

    function string display_result;
     return $psprintf("\n[Score]:\n-----***************************************-----\naddr out pass    = %0d, addr out fail   = %0d\ndata out pass    = %0d, data out fail   = %0d\ndata rdy pass    = %0d, data rdy fail   = %0d\nrcv  rdy pass    = %0d, rcv  rdy fail   = %0d\n-----***************************************-----\n", addr_pass_counter, addr_err_counter,data_pass_counter, data_err_counter,data_rdy_pass_counter, data_rdy_err_counter,rcv_rdy_pass_counter,rcv_rdy_err_counter);
    endfunction: display_result
  endclass: scoreboard
  
  class environment extends uvm_env;

    `uvm_component_utils(environment)
    
    UVM_FILE file_h;
    agent      agent_h;
    scoreboard scoreboard_h;
    
    function new(string name, uvm_component parent);
      super.new(name, parent);
    endfunction: new
    
    function void build_phase(uvm_phase phase);
      agent_h      = agent     ::type_id::create("agent_h", this);
      scoreboard_h = scoreboard::type_id::create("scoreboard_h", this);

    endfunction: build_phase
    
    function void connect_phase(uvm_phase phase);
      agent_h.aport.connect( scoreboard_h.analysis_export );
    endfunction: connect_phase
    
    function void start_of_simulation_phase(uvm_phase phase);
    
      //uvm_top.set_report_verbosity_level_hier(UVM_NONE);
      uvm_top.set_report_verbosity_level_hier(UVM_HIGH);
      uvm_top.set_report_severity_action_hier(UVM_INFO, UVM_NO_ACTION);
      //uvm_top.set_report_id_action_hier("ja", UVM_NO_ACTION);
      
      file_h = $fopen("uvm_basics_complete.log", "w");
      uvm_top.set_report_default_file_hier(file_h);
      uvm_top.set_report_severity_action_hier(UVM_INFO, UVM_DISPLAY + UVM_LOG);

    endfunction: start_of_simulation_phase

    function void  final_phase(uvm_phase phase);
      `uvm_info("TEST_RESULT", $psprintf(" %s", scoreboard_h.display_result()), UVM_NONE);
    endfunction
  endclass: environment

  class test extends uvm_test;

    `uvm_component_utils(test)

    my_dut_config dut_config_0;

    environment environment_h;   

    function new(string name, uvm_component parent);
      super.new(name, parent);
    endfunction: new

    function void build_phase(uvm_phase phase);
      dut_config_0 = new();

      if(!uvm_config_db #(virtual intf)::get( this, "", "dut_vi", dut_config_0.dut_vi))
        `uvm_fatal("NOVIF", "No virtual interface set")
      // other DUT configuration settings
      uvm_config_db #(my_dut_config)::set(this, "*", "dut_config", dut_config_0);
      environment_h = environment::type_id::create("environment_h", this);
    endfunction: build_phase
  endclass :test

  class sanity_check extends test;
    `uvm_component_utils(sanity_check)

    function new(string name, uvm_component parent);
      super.new(name, parent);
    endfunction: new

    task run_phase(uvm_phase phase);
      seq_of_commands seq;
      seq = seq_of_commands::type_id::create("seq");

      seq.n = 10;

      phase.raise_objection(this);
      seq.start(environment_h.agent_h.sequencer_h);
      phase.drop_objection(this);
    endtask // run_phase
  endclass: sanity_check

  class no_overlapping_check extends test;
    `uvm_component_utils(no_overlapping_check)

    function new(string name, uvm_component parent);
      super.new(name, parent);
    endfunction: new

    function void build_phase(uvm_phase phase);
      super.build_phase(phase);
      transaction::type_id::set_type_override(no_overlapping::get_type());
    endfunction: build_phase

    task run_phase(uvm_phase phase);
      seq_of_commands seq;
      seq = seq_of_commands::type_id::create("seq");

      seq.n =100;

      phase.raise_objection(this);
      seq.start(environment_h.agent_h.sequencer_h);
      phase.drop_objection(this);
    endtask // run_phase
  endclass: no_overlapping_check

  class random extends test;
    `uvm_component_utils(random)

    function new(string name, uvm_component parent);
      super.new(name, parent);
    endfunction: new

    task run_phase(uvm_phase phase);
      seq_of_commands seq;
      seq = seq_of_commands::type_id::create("seq");

      seq.n = 900;

      phase.raise_objection(this);
      seq.start(environment_h.agent_h.sequencer_h);
      phase.drop_objection(this);
    endtask // run_phase
  endclass: random

  class overlapping_check extends test;
    `uvm_component_utils(overlapping_check)

    function new(string name, uvm_component parent);
      super.new(name, parent);
    endfunction: new

    function void build_phase(uvm_phase phase);
      super.build_phase(phase);
      transaction::type_id::set_type_override(overlapping::get_type());
    endfunction: build_phase

    task run_phase(uvm_phase phase);
      seq_of_commands seq;
      seq = seq_of_commands::type_id::create("seq");

      seq.n =100;

      phase.raise_objection(this);
      seq.start(environment_h.agent_h.sequencer_h);
      phase.drop_objection(this);
    endtask // run_phase
  endclass: overlapping_check

  class all_input_zero extends test;
    `uvm_component_utils(all_input_zero)

    function new(string name, uvm_component parent);
      super.new(name, parent);
    endfunction: new

    function void build_phase(uvm_phase phase);
      super.build_phase(phase);
      transaction::type_id::set_type_override(all_data_zero::get_type());
    endfunction: build_phase

    task run_phase(uvm_phase phase);
      seq_of_commands seq;
      seq = seq_of_commands::type_id::create("seq");

      seq.n =10;

      phase.raise_objection(this);
      seq.start(environment_h.agent_h.sequencer_h);
      phase.drop_objection(this);
    endtask // run_phase
  endclass: all_input_zero

  class all_input_f extends test;
    `uvm_component_utils(all_input_f)

    function new(string name, uvm_component parent);
      super.new(name, parent);
    endfunction: new

    function void build_phase(uvm_phase phase);
      super.build_phase(phase);
      transaction::type_id::set_type_override(all_data_f::get_type());
    endfunction: build_phase

    task run_phase(uvm_phase phase);
      seq_of_commands seq;
      seq = seq_of_commands::type_id::create("seq");

      seq.n =10;

      phase.raise_objection(this);
      seq.start(environment_h.agent_h.sequencer_h);
      phase.drop_objection(this);
    endtask // run_phase
  endclass: all_input_f

  class small_data_in extends test;
    `uvm_component_utils(small_data_in)

    function new(string name, uvm_component parent);
      super.new(name, parent);
    endfunction: new

    function void build_phase(uvm_phase phase);
      super.build_phase(phase);
      transaction::type_id::set_type_override(small_data::get_type());
    endfunction: build_phase

    task run_phase(uvm_phase phase);
      seq_of_commands seq;
      seq = seq_of_commands::type_id::create("seq");

      seq.n =10;

      phase.raise_objection(this);
      seq.start(environment_h.agent_h.sequencer_h);
      phase.drop_objection(this);
    endtask // run_phase
  endclass: small_data_in

endpackage: lab4_pkg
