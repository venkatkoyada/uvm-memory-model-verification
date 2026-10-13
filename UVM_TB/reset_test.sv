class reset_test extends base_test;
`uvm_component_utils(reset_test)

function new (string name="reset_test",uvm_component parent=null);
super.new(name,parent);
endfunction

//reset in the middle of traffic
function void build_phase(uvm_phase phase);
  super.build_phase(phase);
uvm_config_db#(uvm_object_wrapper)::set(this,"env.m_agent.seqr.main_phase","default_sequence",reset_traffic_sequence::get_type());
endfunction

endclass
