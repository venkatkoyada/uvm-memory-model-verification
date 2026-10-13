class b2b_sequence extends base_sequence;
`uvm_object_utils(b2b_sequence)

function new (string name="b2b_sequence");
	super.new(name);
endfunction

//random reads and writes, mostly back to back (idle=0)
task body();
  repeat(pkt_count) begin
    req=packet::type_id::create("req");
    start_item(req);
    if(!req.randomize() with { kind dist {WRITE:=1, READ:=1};
                               addr inside {[0:15]};
                               idle dist {0:=8, [1:3]:=2}; })
      `uvm_error("B2B_SEQ","Randomization failed")
    finish_item(req);
  end

  //same address write then read, back to back
  repeat(pkt_count/4) begin
    bit [7:0]  a = $urandom_range(15);
    do_write(a, $urandom);
    do_read(a);
  end
endtask

endclass
