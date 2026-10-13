class reset_sequence extends base_sequence;
`uvm_object_utils(reset_sequence)

function new (string name="reset_sequence");
	super.new(name);
endfunction

task body();
     begin
      `uvm_create(req);
      req.kind=RESET;
      start_item(req);
      finish_item(req);
	`uvm_info("RST_SEQ","Reset Transaction Completed",UVM_MEDIUM);
     end
endtask
endclass

