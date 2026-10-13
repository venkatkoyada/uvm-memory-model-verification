class illegal_addr_sequence extends base_sequence;
`uvm_object_utils(illegal_addr_sequence)

function new (string name="illegal_addr_sequence");
	super.new(name);
endfunction

task body();
  //read an unmapped address before any memory read
  do_read('h30);
  do_read('hFF);

  //good write followed right away by a write that gets dropped
  do_write(4, 32'h1111_1111);
  do_write('h40, 32'h2222_2222);
  do_write(5, 32'h3333_3333);
  do_write('h26, 32'h4444_4444);
  do_write(6, 32'h5555_5555);
  do_write('h20, 32'h0000_0001);

  //memory read followed by an unmapped read
  do_read(4);
  do_read('h30);
  do_read(5);
  do_read('h99);

  //random mix over the full address range.
  //don't write 0x20/0x24 here so the chip stays enabled.
  repeat(pkt_count) begin
    req=packet::type_id::create("req");
    start_item(req);
    if(!req.randomize() with { kind dist {WRITE:=1, READ:=1};
                               addr dist {[0:15]:/60, [16:255]:/40};
                               (kind==WRITE) -> !(addr inside {'h20,'h24});
                               idle dist {0:=8, [1:2]:=2}; })
      `uvm_error("ILLEGAL_SEQ","Randomization failed")
    finish_item(req);
  end

  do_read('h26);
endtask

endclass
