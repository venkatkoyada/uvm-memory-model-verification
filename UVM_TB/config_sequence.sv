class config_sequence extends base_sequence;
`uvm_object_utils(config_sequence)

function new (string name="config_sequence");
	super.new(name);
endfunction

task body();
      `uvm_create(req);
      req.addr='h20;//csr2_CHIP_EN
      req.data='h1;
      req.kind=CSR_WRITE;
      start_item(req);
      finish_item(req);
  `uvm_info("CONFIG_SEQ","Config CSR_WRITE sequence Transaction Completed \n",UVM_MEDIUM);
endtask

endclass

