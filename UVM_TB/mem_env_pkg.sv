package mem_env_pkg;

typedef enum {STIMULUS,RESET,WRITE,READ,CSR_WRITE,CSR_READ} pkt_type_e;
typedef enum {OK,ERROR} slv_response_type_e;

// UVM class library compiled in a package
import uvm_pkg::*;
`include "uvm_macros.svh"

`include "packet.sv"

`include "base_sequence.sv"
`include "reset_sequence.sv"
`include "config_sequence.sv"
`include "shutdown_sequence.sv"
`include "rw_sequence.sv"
`include "csr_sequence.sv"
`include "chip_disable_sequence.sv"
`include "b2b_sequence.sv"
`include "illegal_addr_sequence.sv"
`include "reset_traffic_sequence.sv"

`include "sequencer.sv"
`include "driver.sv"
`include "iMonitor.sv"

`include "oMonitor.sv"

`include "coverage.sv"

`include "master_agent.sv"

`include "slave_agent.sv"

`include "scoreboard.sv"


`include "environment.sv"

endpackage
