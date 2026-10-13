class chip_disable_test extends base_test;
`uvm_component_utils(chip_disable_test)

function new (string name="chip_disable_test",uvm_component parent=null);
super.new(name,parent);
endfunction

//memory access while chip enable is 0
function void build_phase(uvm_phase phase);
  super.build_phase(phase);
uvm_config_db#(uvm_object_wrapper)::set(this,"env.m_agent.seqr.main_phase","default_sequence",chip_disable_sequence::get_type());
endfunction

endclass
