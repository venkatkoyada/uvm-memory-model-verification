class base_sequence extends uvm_sequence#(packet);
    bit [31:0] pkt_count;

`uvm_object_utils(base_sequence)

function new (string name="base_sequence");
	super.new(name);
	set_automatic_phase_objection(1);//uvm-1.2 only
endfunction

extern virtual task pre_start();
extern virtual task body();

//small helper tasks used by the other sequences
task do_write(bit [7:0] addr, bit [31:0] data, bit [3:0] idle=0);
  packet pkt;
  pkt=packet::type_id::create("pkt");
  start_item(pkt);
  pkt.kind=WRITE;
  pkt.addr=addr;
  pkt.data=data;
  pkt.idle=idle;
  finish_item(pkt);
endtask

task do_read(bit [7:0] addr, bit [3:0] idle=0);
  packet pkt;
  pkt=packet::type_id::create("pkt");
  start_item(pkt);
  pkt.kind=READ;
  pkt.addr=addr;
  pkt.idle=idle;
  finish_item(pkt);
endtask

//read that waits for the data and gives it back
task do_csr_read(bit [7:0] addr, output logic [31:0] data);
  packet pkt;
  pkt=packet::type_id::create("pkt");
  start_item(pkt);
  pkt.kind=CSR_READ;
  pkt.addr=addr;
  pkt.idle=0;
  finish_item(pkt);
  data=pkt.data;
endtask

task do_reset();
  packet pkt;
  pkt=packet::type_id::create("pkt");
  start_item(pkt);
  pkt.kind=RESET;
  pkt.idle=0;
  finish_item(pkt);
endtask

endclass

task base_sequence::pre_start();
//below one is for when setting item_count at agent level in test
//uvm_sequencer_base sqr=get_sequencer();
  //if(!uvm_config_db #(int):: get(sqr.get_parent(),"","item_count",pkt_count))

//below one is for when setting item_count at sequence level in test
//  if(!uvm_config_db #(int):: get(null,this.get_full_name,"item_count",pkt_count))

  //below one is for when setting item_count at sequencer level in test
  if(!uvm_config_db #(int):: get(this.get_sequencer(),"","item_count",pkt_count))
  begin
    `uvm_warning("Base_Seq","Packet count is not set hence generating 10 transactions")
   pkt_count=10;
end
   `uvm_info("PKT_CNT",$sformatf("Packet count in sequence=%0d",pkt_count),UVM_HIGH)

endtask

//child sequences write their own body
task base_sequence::body();
endtask
