class new_test extends base_test;
`uvm_component_utils(new_test)

function new (string name="new_test",uvm_component parent=null);
super.new(name,parent);
endfunction

//write then read to random addresses
function void build_phase(uvm_phase phase);
  super.build_phase(phase);
pkt_count=50;  
  uvm_config_db#(int)::set(this,"env.m_agent.seqr", "item_count", pkt_count);
  
uvm_config_db#(uvm_object_wrapper)::set(this,"env.m_agent.seqr.main_phase","default_sequence",rw_sequence::get_type());
  
endfunction

endclass
