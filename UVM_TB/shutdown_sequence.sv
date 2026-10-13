class shutdown_sequence extends base_sequence;
  `uvm_object_utils(shutdown_sequence)

  bit [31:0] csr_dropped;
  bit [31:0] csr_count;

function new (string name="shutdown_sequence");
	super.new(name);
endfunction

extern virtual task body();
endclass

//read the status registers at the end of the test.
//scoreboard checks the values, here we only print them.
task shutdown_sequence::body();
      `uvm_create(req);
      req.addr='h26;//addr of csr4_dropped register in DUT
      req.kind=CSR_READ;
      start_item(req);
      finish_item(req);
      csr_dropped=req.data;

      `uvm_create(req);
      req.addr='h18;//addr of csr1_wr_count register in DUT
      req.kind=CSR_READ;
      start_item(req);
      finish_item(req);
      csr_count=req.data;

  `uvm_info("SHUTDOWN_SEQ",$sformatf("csr_dropped_count=%0d",csr_dropped),UVM_LOW);
  `uvm_info("SHUTDOWN_SEQ",$sformatf("total writes=%0d total reads=%0d",csr_count[15:0],csr_count[31:16]),UVM_LOW);
  `uvm_info("SHUTDOWN_SEQ","Shutdown Sequence CSR_READ Completed ",UVM_MEDIUM);
endtask
