`include "debug.svh"

interface intf(input bit clk, reset);

    logic  [`_BIT_SIZE_ADDR_  - 1:0] addr_in  ;
    logic  [`_BIT_SIZE_DATA_  - 1:0] data_in  ;
    logic  [`_PORT_NUMBER_    - 1:0] valid_in ;
    logic  [`_PORT_NUMBER_    - 1:0] rcv_rdy  ;
    logic  [`_BIT_SIZE_ADDR_  - 1:0] addr_out ;
    logic  [`_BIT_SIZE_DATA_  - 1:0] data_out ;  
    logic  [`_PORT_NUMBER_    - 1:0] data_rdy ;
    logic  [`_PORT_NUMBER_    - 1:0] data_read;

modport DUT(
    input clk,       
    input reset,  
    input addr_in,       
    input data_in,   
    input valid_in,
    input data_read, 
    output addr_out,
    output data_out,  
    output data_rdy,
    output rcv_rdy 
);

clocking cb_in @(posedge  clk);
    input addr_in;      
    input data_in;   
    input valid_in;
    input data_read;
    input addr_out;
    input data_out; 
    input data_rdy;
    input rcv_rdy;
endclocking

clocking cb_out @(posedge  clk);
    input addr_out;
    input data_out; 
    input data_rdy;
    input rcv_rdy;
    output addr_in;      
    output data_in;   
    output valid_in;
    output data_read;
endclocking

modport MON( clocking cb_in , input reset );

modport DRIV( clocking cb_out , input reset );


covergroup cg @ (posedge clk);
    option.at_least = 3;
    // option.max_auto_bins(100);
    coverpoint data_in iff (reset == 0){
        bins di_min = {16'H0};
        bins di_b1  = {[16'H1:16'HF]};
        bins di_b2  = {[16'H10:16'HFF]};
        bins di_b3  = {[16'H100:16'HFFF]};
        bins di_b4  = {[16'H1000:16'HFFFE]};
        bins di_max = {16'HFFFF};
    } 
    coverpoint data_out iff (reset == 0){
        bins dO_min = {16'H0};
        bins dO_b1  = {[16'H1:16'HF]};
        bins dO_b2  = {[16'H10:16'HFF]};
        bins dO_b3  = {[16'H100:16'HFFF]};
        bins dO_b4  = {[16'H1000:16'HFFFE]};
        bins dO_max = {16'HFFFF};


    } 

    coverpoint addr_in[3:0] iff (reset == 0){
        bins ai_b1_min = {4'h0};  
        bins ai_b1 = { 4'h1,4'h2};  
        bins ai_b1_max = {4'h3};  
        illegal_bins ai_i_b1 = {[4'h4:4'hF]};
    } 

    coverpoint addr_in[7:4] iff (reset == 0){

        bins ai_b2_min = {4'h0};  
        bins ai_b2 = { 4'h1,4'h2};  
        bins ai_b2_max = {4'h3};         
        illegal_bins ai_i_b2 = {[4'h4:4'hF]};
    }

    coverpoint addr_in[11:8] iff (reset == 0){

        bins ai_b3_min = {4'h0};  
        bins ai_b3 = { 4'h1,4'h2};  
        bins ai_b3_max = {4'h3};         
        illegal_bins ai_i_b3 = {[4'h4:4'hF]};
    }

    coverpoint addr_in[15:12] iff (reset == 0){    

        bins ai_b4_min = {4'h0};  
        bins ai_b4 = { 4'h1,4'h2};  
        bins ai_b4_max = {4'h3};         
        illegal_bins ai_i_b14 = {[4'h4:4'hF]};
    }   
    

    coverpoint addr_out[3:0] iff (reset == 0){

        bins ao_b1_min = {4'h0};  
        bins ao_b1 = { 4'h1,4'h2};  
        bins ao_b1_max = {4'h3};         
        illegal_bins ao_i_b1 = {[4'h4:4'hF]};
    } 

    coverpoint addr_out[7:4] iff (reset == 0){
        bins ao_b2_min = {4'h0};  
        bins ao_b2 = { 4'h1,4'h2};  
        bins ao_b2_max = {4'h3};              
        illegal_bins ao_i_b2 = {[4'h4:4'hF]};
    }

    coverpoint addr_out[11:8] iff (reset == 0){
        bins ao_b3_min = {4'h0};  
        bins ao_b3 = { 4'h1,4'h2};  
        bins ao_b3_max = {4'h3};              
        illegal_bins ao_i_b3 = {[4'h4:4'hF]};
    }

    coverpoint addr_out[15:12] iff (reset == 0){    
        bins ao_b4_min = {4'h0};  
        bins ao_b4 = { 4'h1,4'h2};  
        bins ao_b4_max = {4'h3};              
        illegal_bins ao_i_b14 = {[4'h4:4'hF]};
    }   

    // cross coverage that cover the combination between the addr_in and data-in  
    // not sure about the other values if I need to cross out too ?? 

    // cross addr_in,data_in{
        // ignore_bins auto =binsof(data_in)intersect {[16'h0:16'hffff]};
        // ignore_bins auto1 =binsof(addr_in)intersect {[16'h0:16'hffff]};

    // }

    // cross addr_out, data_out { 
        // ignore_bins auto2 =binsof(data_out)intersect {[16'h0:16'hffff]};
        // ignore_bins auto3 =binsof(addr_out)intersect {[16'h0:16'hffff]};
    // }

    coverpoint valid_in iff (reset == 0){
        bins valid_in_min = {4'h0};
        bins valid_in_bin = {[4'h1:4'hE]};
        bins valid_in_falling = ([4'h1:4'hF] => 4'h0);
        bins valid_in_rising = (4'h0 => [4'h1:4'hF]);
        bins valid_in_max = {4'hF};
    }
    
    coverpoint rcv_rdy iff (reset == 0){
        bins rcv_rdy_min = {4'h0};
        bins rcv_rdy_bin = {[4'h1:4'hE]};
        bins rcv_rdy_falling = ([4'h1:4'hF] => 4'h0);
        bins rcv_rdy_rising = (4'h0 => [4'h1:4'hF]);
        bins rcv_rdy_max = {4'hF};  
         }

    coverpoint data_rdy iff (reset == 0){
        bins data_rdy_min = {4'h0};
        bins data_rdy_bin = {[4'h1:4'hE]};
        bins data_rdy_falling = ([4'h1:4'hF] => 4'h0);
        bins data_rdy_rising = (4'h0 => [4'h1:4'hF]);
        bins data_rdy_max = {4'hF};     }

    coverpoint data_read iff (reset == 0){
        bins data_read_min = {4'h0};
        bins data_read_bin = {[4'h1:4'hE]};
        bins data_read_falling = ([4'h1:4'hF] => 4'h0);
        bins data_read_rising = (4'h0 => [4'h1:4'hF]);
        bins data_read_max = {4'hF};
    }
endgroup
cg cg_cov = new();


endinterface