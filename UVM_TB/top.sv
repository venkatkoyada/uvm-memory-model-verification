//memory_rtl.sv is in ../rtl and is compiled before this file (see Makefile)
`include "if_memory.sv"
`include "mem_sva.sv"
`include "program_mem.sv"
module top;


parameter reg [15:0] ADDR_WIDTH=8;
parameter reg [15:0] DATA_WIDTH=32;
parameter reg [15:0] MEM_SIZE=16;

bit clk;

always #10 clk=!clk;


memory_if   #(ADDR_WIDTH,DATA_WIDTH,MEM_SIZE) mem_if (clk);
memory_rtl  #(ADDR_WIDTH,DATA_WIDTH,MEM_SIZE) dut_inst
 (
  .clk(clk),
  .reset(mem_if.reset),
  .wr(mem_if.wr),
  .rd(mem_if.rd),
  .addr(mem_if.addr),
  .wdata(mem_if.wdata),
  .rdata(mem_if.rdata),
  .response(mem_if.slv_rsp)
 );
mem_program ptest (mem_if);

// Dumping Waveform (turn off with +NO_DUMP, the regression uses it)
initial begin
  if(!$test$plusargs("NO_DUMP")) begin
    $dumpfile("dump.vcd");
    $dumpvars(0,top.dut_inst);
  end
end
endmodule
