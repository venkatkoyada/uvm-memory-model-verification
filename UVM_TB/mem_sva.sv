// Assertions for memory_rtl. Connected to the DUT with bind (see bottom of file).
// Failures are reported with `uvm_error so they show up in the UVM summary.
// Messages use $sampled() so they print the value the assertion checked at the clock edge.

module mem_sva #(parameter ADDR_WIDTH=8, DATA_WIDTH=32, MEM_SIZE=16)
(
  input clk,
  input reset,
  input wr,
  input rd,
  input [ADDR_WIDTH-1:0] addr,
  input [DATA_WIDTH-1:0] rdata,
  input response,
  input [7:0]  chip_en,
  input [31:0] csr3,
  input [31:0] dropped
);

import uvm_pkg::*;
`include "uvm_macros.svh"

// signals are X before the first reset, so don't check anything until then
bit reset_done;
always @(posedge clk)
  if (reset === 1'b1) reset_done <= 1'b1;

wire good_write = wr && chip_en[0] && (addr < MEM_SIZE);

default clocking @(posedge clk); endclocking
default disable iff (reset || !reset_done);

// testbench must never read and write in the same cycle
WR_RD_TOGETHER: assert property (!(wr && rd))
  else `uvm_error("SVA", "wr and rd are both high in the same cycle")

WR_RD_KNOWN: assert property (!$isunknown({wr, rd}))
  else `uvm_error("SVA", "wr/rd is X or Z")

// chip disabled -> nothing is driven on rdata
RDATA_Z_CHIP_OFF: assert property (!chip_en[0] |-> rdata === 'z)
  else `uvm_error("SVA", $sformatf("rdata=%0h while chip is disabled, expected Z", $sampled(rdata)))

// no read in this cycle -> rdata is Z in the next cycle
RDATA_Z_NO_READ: assert property (!rd |=> rdata === 'z)
  else `uvm_error("SVA", $sformatf("rdata=%0h one cycle after an idle cycle, expected Z", $sampled(rdata)))

// read with chip enabled -> rdata must have a known value in the next cycle
RDATA_KNOWN: assert property (rd && chip_en[0] |=> !$isunknown(rdata))
  else `uvm_error("SVA", $sformatf("rdata=%0h has X/Z after a read", $sampled(rdata)))

// good memory write -> response=1 in the next cycle
RESP_AFTER_WRITE: assert property (good_write |=> response)
  else `uvm_error("SVA", "response not seen after a good write")

// response=1 only right after a good memory write
RESP_ONLY_GOOD_WRITE: assert property (response |-> $past(good_write))
  else `uvm_error("SVA", "response=1 but last cycle was not a good memory write")

// registers come out of reset with 0
RESET_VALUES: assert property ($fell(reset) |-> (chip_en == 0 && csr3 == 0 && dropped == 0))
  else `uvm_error("SVA", "CSRs are not 0 after reset")

// a few covers to see the interesting cases happen
WR_WR_COVER:   cover property (wr ##1 wr);
WR_RD_COVER:   cover property (wr ##1 rd);
RD_RD_COVER:   cover property (rd ##1 rd);
DROP_COVER:    cover property (wr && !good_write);

endmodule

bind memory_rtl mem_sva #(.ADDR_WIDTH(ADDR_WIDTH), .DATA_WIDTH(DATA_WIDTH), .MEM_SIZE(MEM_SIZE))
  sva_inst (
    .clk(clk),
    .reset(reset),
    .wr(wr),
    .rd(rd),
    .addr(addr),
    .rdata(rdata),
    .response(response),
    .chip_en(csr2_CHIP_EN),
    .csr3(csr3),
    .dropped(csr4_dropped)
  );
