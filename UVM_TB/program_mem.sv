`include "mem_env_pkg.sv"
program mem_program(memory_if pif);

import uvm_pkg::*;
import mem_env_pkg::*;

`include "base_test.sv"
`include "new_test.sv"
`include "csr_test.sv"
`include "chip_disable_test.sv"
`include "b2b_test.sv"
`include "illegal_addr_test.sv"
`include "reset_test.sv"

initial begin
  $timeformat(-9, 1, "ns", 10);

  uvm_config_db#(virtual memory_if)::set(null,"uvm_test_top","master_if",pif);
 run_test();

end

endprogram
