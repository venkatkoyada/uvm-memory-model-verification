//typedef uvm_sequencer #(packet) sequencer;
//OR use like below shown

//seq_item_export;
class sequencer extends uvm_sequencer#(packet);
    `uvm_component_utils(sequencer);
function new (string name="sequencer",uvm_component parent);
	super.new(name,parent);
endfunction
endclass

