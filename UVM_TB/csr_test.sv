class csr_test extends base_test;
`uvm_component_utils(csr_test)

function new (string name="csr_test",uvm_component parent=null);
super.new(name,parent);
endfunction

//reads and writes all the CSRs, with chip on and off
function void build_phase(uvm_phase phase);
  super.build_phase(phase);
uvm_config_db#(uvm_object_wrapper)::set(this,"env.m_agent.seqr.main_phase","default_sequence",csr_sequence::get_type());
endfunction

endclass
