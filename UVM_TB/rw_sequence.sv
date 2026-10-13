class rw_sequence extends base_sequence;

`uvm_object_utils(rw_sequence)

function new (string name="rw_sequence");
	super.new(name);
endfunction

//each item is a write followed by a read to the same address
task body();
bit [31:0] count;

repeat(pkt_count) begin
  `uvm_create(req);
  if(!req.randomize() with {kind==STIMULUS; addr inside {[0:15]}; idle==0;})
    `uvm_error("RW_SEQ","Randomization failed")

  start_item(req);
  finish_item(req);
  get_response(rsp);
  count++;
`uvm_info("RW_SEQ",$sformatf("Transaction %0d Completed with resp=%0s \n ",count,rsp.slv_rsp.name()),UVM_MEDIUM);
end
endtask

endclass
