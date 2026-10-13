class illegal_addr_test extends base_test;
`uvm_component_utils(illegal_addr_test)

function new (string name="illegal_addr_test",uvm_component parent=null);
super.new(name,parent);
endfunction

//reads and writes to unmapped and read only addresses
function void build_phase(uvm_phase phase);
  super.build_phase(phase);
pkt_count=500;
  uvm_config_db#(int)::set(this,"env.m_agent.seqr", "item_count", pkt_count);
uvm_config_db#(uvm_object_wrapper)::set(this,"env.m_agent.seqr.main_phase","default_sequence",illegal_addr_sequence::get_type());
endfunction

endclass
