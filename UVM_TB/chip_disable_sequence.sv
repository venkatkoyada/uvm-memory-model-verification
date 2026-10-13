class chip_disable_sequence extends base_sequence;
`uvm_object_utils(chip_disable_sequence)

function new (string name="chip_disable_sequence");
	super.new(name);
endfunction

task body();
  logic [31:0] dropped;

  //turn the chip off, all memory writes must be dropped and reads give Z
  do_write('h20, 32'h0);
  for(int i=0; i<16; i++) do_write(i, $urandom);
  for(int i=0; i<16; i++) do_read(i);
  do_write('h40, 32'h55);
  do_read('h40);

  //turn it on again, memory should still have the reset value 0
  do_write('h20, 32'h1);
  for(int i=0; i<16; i++) do_read(i);
  do_csr_read('h26, dropped);
  `uvm_info("CHIP_SEQ",$sformatf("dropped count after chip off = %0d",dropped),UVM_LOW)

  //normal traffic works after enabling
  for(int i=0; i<16; i++) begin
    do_write(i, $urandom);
    do_read(i);
  end

  //turn off and on a few times with random traffic in between
  repeat(4) begin
    do_write('h20, 32'h0);
    repeat(8) begin
      do_write($urandom_range(15), $urandom);
      do_read($urandom_range(15));
    end
    do_write('h20, 32'h1);
    repeat(8) begin
      do_write($urandom_range(15), $urandom);
      do_read($urandom_range(15));
    end
  end
endtask

endclass
