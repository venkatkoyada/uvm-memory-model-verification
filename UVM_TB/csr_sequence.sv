class csr_sequence extends base_sequence;
`uvm_object_utils(csr_sequence)

function new (string name="csr_sequence");
	super.new(name);
endfunction

//Checks all 4 CSRs. Scoreboard compares every read with its model.
task body();
  logic [31:0] rdata;
  bit [31:0] patterns[4] = '{32'h0000_0000, 32'hFFFF_FFFF, 32'hA5A5_A5A5, 32'h5A5A_5A5A};

  //values right after reset (chip is already enabled by config_sequence)
  do_csr_read('h18, rdata);
  do_csr_read('h20, rdata);
  `uvm_info("CSR_SEQ",$sformatf("chip enable reg = %0h",rdata),UVM_MEDIUM)
  do_csr_read('h24, rdata);
  do_csr_read('h26, rdata);

  //csr3 is a normal read/write register
  foreach(patterns[i]) begin
    do_write('h24, patterns[i]);
    do_read('h24);
  end
  repeat(5) begin
    do_write('h24, $urandom);
    do_read('h24);
  end

  //0x18 and 0x26 are read only, writes there should be dropped
  do_write('h18, 32'hFFFF_FFFF);
  do_write('h26, 32'h1234_5678);
  do_read('h18);
  do_read('h26);

  //memory traffic and then check the write/read counters
  for(int i=0; i<16; i++) do_write(i, $urandom);
  for(int i=0; i<16; i++) do_read(i);
  do_read('h18);

  //chip enable is 8 bits, only bit 0 turns the chip on
  do_write('h20, 32'h0000_01FF);
  do_read('h20);
  do_write('h20, 32'h0000_0081);
  do_read('h20);

  //chip disabled: every read gives Z, even CSR reads
  do_write('h20, 32'h0);
  do_read('h18);
  do_read('h20);
  do_read('h24);
  do_read('h26);
  do_write('h24, 32'hDEAD_BEEF);//csr3 still takes writes
  do_write('h18, 32'h1);
  do_write('h26, 32'h1);

  //turn it back on and check what happened while it was off
  do_write('h20, 32'h1);
  do_read('h24);
  do_read('h26);
  do_read('h18);
endtask

endclass
