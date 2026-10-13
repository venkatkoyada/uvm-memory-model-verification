class b2b_test extends base_test;
`uvm_component_utils(b2b_test)

function new (string name="b2b_test",uvm_component parent=null);
super.new(name,parent);
endfunction

//random back to back reads and writes
function void build_phase(uvm_phase phase);
  super.build_phase(phase);
pkt_count=1000;
  uvm_config_db#(int)::set(this,"env.m_agent.seqr", "item_count", pkt_count);
uvm_config_db#(uvm_object_wrapper)::set(this,"env.m_agent.seqr.main_phase","default_sequence",b2b_sequence::get_type());
endfunction

endclass
