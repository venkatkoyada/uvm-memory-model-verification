class reset_traffic_sequence extends base_sequence;
`uvm_object_utils(reset_traffic_sequence)

function new (string name="reset_traffic_sequence");
	super.new(name);
endfunction

task body();
  //fill memory with non zero data so we can see reset clear it
  for(int i=0; i<16; i++) do_write(i, $urandom | 32'h1);
  for(int i=0; i<8; i++)  do_read(i);
  do_write('h24, 32'hCAFE_F00D);

  do_reset();

  //chip enable is 0 after reset, so this write is dropped and reads give Z
  do_read('h20);
  do_read(2);
  do_write(3, 32'hABCD);

  do_write('h20, 32'h1);
  do_read('h18);
  do_read('h20);
  do_read('h24);
  do_read('h26);
  for(int i=0; i<16; i++) do_read(i);

  //random traffic with a reset in between, a few times
  repeat(4) begin
    repeat(20) begin
      do_write($urandom_range(15), $urandom);
      do_read($urandom_range(15));
    end
    do_reset();
    do_write('h20, 32'h1);
    do_read('h26);
  end
endtask

endclass
