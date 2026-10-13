interface memory_if (input clk);

parameter reg [15:0] ADDR_WIDTH=8;
parameter reg [15:0] DATA_WIDTH=32;
parameter reg [15:0] MEM_SIZE=16;

logic  reset;
logic  slv_rsp;
logic  wr;// for write wr=1;
logic  rd;// for read  rd=1;
logic  [ADDR_WIDTH-1:0] addr;
logic  [DATA_WIDTH-1:0] wdata;
logic  [DATA_WIDTH-1:0] rdata;

//Directions are w.r.t to testbench
clocking cb @(posedge clk);
output reset;
output wr,rd;
output wdata;
output addr;
input rdata;
input slv_rsp;
endclocking

//signals going into the DUT
clocking cb_mon_in @(posedge clk);
input reset;
input wr,rd;
input wdata;
input addr;
endclocking

//signals coming out of the DUT
clocking cb_mon_out @(posedge clk);
input reset;
input rdata;
input slv_rsp;
input wr,rd;
input addr;
endclocking

//modport for specifying directions
modport tb      (clocking cb);
modport tb_mon_in  (clocking cb_mon_in);
modport tb_mon_out  (clocking cb_mon_out);

endinterface
