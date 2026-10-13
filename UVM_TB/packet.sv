`define AWIDTH 8
`define DWIDTH 32
class packet extends uvm_sequence_item;

rand logic [`AWIDTH - 1:0] addr;
rand logic [`DWIDTH - 1:0] data;//logic so the monitor can keep Z/X read data

bit wr=1;
bit rd=1;

rand pkt_type_e kind;
slv_response_type_e slv_rsp;

rand bit [3:0] idle;//idle clocks before driving this item, 0 = back to back
int cycle;//clock number when the monitor saw it

//address range and kind are given by each sequence with randomize() with {...}
constraint valid {
data dist { 0 :/ 5, 32'hFFFF_FFFF :/ 5, [1:32'hFFFF_FFFE] :/ 90 };
idle inside {[0:3]};
}

`uvm_object_utils_begin(packet)
`uvm_field_int(addr,UVM_ALL_ON)
`uvm_field_int(data,UVM_ALL_ON)
`uvm_field_enum(pkt_type_e,kind,UVM_ALL_ON)
`uvm_field_enum(slv_response_type_e,slv_rsp,UVM_ALL_ON)
`uvm_field_int(idle,UVM_ALL_ON)
`uvm_object_utils_end

virtual function string convert2string();
return $sformatf("%0s addr=%0h data=%0h ",kind.name(),addr,data);
endfunction


function new(string name="packet");
	super.new(name);
endfunction
endclass
