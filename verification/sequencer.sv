`include "uvm_macros.svh"
`include "debug.svh"
package sequencer;
  import uvm_pkg::*;
  class transaction extends uvm_sequence_item;
  
    `uvm_object_utils(transaction)
  
        rand bit   [`_BIT_SIZE_ADDR_  - 1:0] addr_in;
        rand bit   [`_BIT_SIZE_DATA_  - 1:0] data_in;
        rand bit   [`_PORT_NUMBER_    - 1:0] valid_in;
        rand bit   [`_PORT_NUMBER_    - 1:0] data_read;
             logic [`_BIT_SIZE_ADDR_  - 1:0] addr_out;
             logic [`_BIT_SIZE_DATA_  - 1:0] data_out;
             bit   [`_PORT_NUMBER_    - 1:0] rcv_rdy;
             bit   [`_PORT_NUMBER_    - 1:0] data_rdy;
             bit                             reset;

  
    constraint valid_addresses{
            addr_in[3:0]   < `_PORT_NUMBER_;
            addr_in[7:4]   < `_PORT_NUMBER_;
            addr_in[11:8]  < `_PORT_NUMBER_;
            addr_in[15:12] < `_PORT_NUMBER_;
        }
//         constraint valid_addresses{
//     addr_in[7:0]   < `_PORT_NUMBER_;
//     addr_in[15:8]   < `_PORT_NUMBER_;
//     addr_in[23:16]  < `_PORT_NUMBER_;
//     addr_in[31:24] < `_PORT_NUMBER_;
//     }


        constraint data_in_allowed {
            data_in  >= 0;
        }

    function new (string name = "");
      super.new(name);
    endfunction: new

    function string convert2string;
      return $psprintf("\ndata_in  = %4h, data_out  = %4h\naddr_in  = %4h, addr_out  = %4h\nrcv_rdy  = %4b, data_rdy  = %4b\nvalid_in = %4b, data_read = %4b",data_in , data_out ,addr_in, addr_out ,rcv_rdy , data_rdy,valid_in, data_read);
    endfunction: convert2string

  endclass: transaction

  class no_overlapping extends transaction;
          `uvm_object_utils(no_overlapping)

        function new (string name = "");
            super.new(name);
        endfunction: new

      constraint overlapping{
          unique {addr_in[3:0], addr_in[7:4], addr_in[11:8], addr_in[15:12]};

      }        
  endclass:no_overlapping  //overlapping_sequence extends transaction


  class overlapping extends transaction;
          `uvm_object_utils(overlapping)

        function new (string name = "");
            super.new(name);
        endfunction: new

      constraint overlapping_seq{
            addr_in[3:0]   == addr_in[15:12];
            addr_in[7:4]   == addr_in[15:12];
            addr_in[11:8]  == addr_in[15:12];  
            }        
  endclass:overlapping  //overlapping extends transaction



  class all_data_zero extends transaction;
          `uvm_object_utils(all_data_zero)

        function new (string name = "");
            super.new(name);
        endfunction: new

      constraint data_zero{
         data_in == 16'h0000;
      }        
      constraint addr_zero{
         addr_in == 16'h3210;
      }       
      constraint data_read_zero{
         data_read == 4'h0;
      }      
      constraint valid_zero{
         valid_in == 4'hf;
      }       

  endclass:all_data_zero  //all_data_zero extends transaction



  class small_data extends transaction;
          `uvm_object_utils(small_data)

        function new (string name = "");
            super.new(name);
        endfunction: new

      constraint data_small{
         data_in == 16'h0002;
      }        
      constraint addr_zero{
         addr_in == 16'h3210;
      }       
      constraint data_read_zero{
         data_read == 4'h0;
      }      
      constraint valid_zero{
         valid_in == 4'hf;
      }       

  endclass:small_data  //small_data extends transaction



  class all_data_f extends transaction;
          `uvm_object_utils(all_data_f)

        function new (string name = "");
            super.new(name);
        endfunction: new

      constraint data_zero{
         data_in == 16'hffff;
      }        
      constraint addr_zero{
         addr_in == 16'h3210;
      }       
      constraint data_read_zero{
         data_read == 4'h0;
      }      
      constraint valid_zero{
         valid_in == 4'hf;
      }       

  endclass:all_data_f  //all_data_zero extends transaction




  class read_modify_write extends uvm_sequence #(transaction);
  
    `uvm_object_utils(read_modify_write)
    
    function new (string name = "");
      super.new(name);
    endfunction: new

    task body;
      transaction tx;


      tx = transaction::type_id::create("tx");
      start_item(tx);
      assert( tx.randomize() );
      finish_item(tx);
    endtask: body
   
  endclass: read_modify_write


  class seq_of_commands extends uvm_sequence #(transaction);
  
    `uvm_object_utils(seq_of_commands)
    `uvm_declare_p_sequencer(uvm_sequencer#(transaction))
    
    int n;
    
    // constraint how_many { n inside {[2:4]}; }
    
    function new (string name = "");
      super.new(name);
    endfunction: new

    task body;
      repeat(n)
      begin
        read_modify_write seq;
        seq = read_modify_write::type_id::create("seq");
        assert( seq.randomize() );
        seq.start(p_sequencer);
      end
    endtask: body
   
  endclass: seq_of_commands

  
endpackage: sequencer

//for printing in one block 
        //  a = $sformatf("addr_in  : %4h\n, DUT_addr_out: %4h,\n SCB_addr_out: %4h" ,t.addr_in, t.addr_out, SCB_addr ) ;
        //  b = $sformatf("addr_in  : %4h,\n DUT_addr_out: %4h,\n SCB_addr_out: %4h" ,t.addr_in, t.addr_out, SCB_addr ) ;
        //  f ={a,b};
        //   `uvm_error("tesssssssssssst", $psprintf(f));