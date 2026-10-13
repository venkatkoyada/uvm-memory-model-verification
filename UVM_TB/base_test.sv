class base_test extends uvm_test;
`uvm_component_utils(base_test)

environment env;
virtual memory_if mvif;
bit [31:0] pkt_count;

	function new (string name="base_test",uvm_component parent=null);
		super.new(name,parent);
	endfunction

	extern virtual function void build_phase(uvm_phase phase);
	extern virtual function void start_of_simulation_phase(uvm_phase phase);
    extern virtual task main_phase (uvm_phase phase);
    extern virtual task shutdown_phase (uvm_phase phase);
    extern virtual function void report_phase(uvm_phase phase);
endclass

function void base_test::build_phase(uvm_phase phase);
	super.build_phase(phase);
	pkt_count=200;
  env=environment::type_id::create("env",this);

	if(!uvm_config_db#(virtual memory_if)::get(this,"","master_if",mvif))
	  `uvm_fatal("VIF_ERR","master_if is not set in config_db")

	//virtual interface without modport can be given to a modport handle directly
	uvm_config_db#(virtual memory_if.tb)::set(this,"env.m_agent.drvr","drvr_if",mvif);
	uvm_config_db#(virtual memory_if.tb_mon_in)::set(this,"env.m_agent.iMon","iMon_if",mvif);
	uvm_config_db#(virtual memory_if.tb_mon_out)::set(this,"env.s_agent.oMon","oMon_if",mvif);

    uvm_config_db#(int)::set(this,"env.m_agent.seqr", "item_count", pkt_count);
	uvm_config_db#(bit)::set(this,"env","enable_coverage",1'b1);
    uvm_config_db#(bit)::set(this,"env.m_agent.drvr", "set_resp_for_drvr", 1'b1);

uvm_config_db#(uvm_object_wrapper)::set(this,"env.m_agent.seqr.reset_phase","default_sequence",reset_sequence::get_type());
uvm_config_db#(uvm_object_wrapper)::set(this,"env.m_agent.seqr.configure_phase","default_sequence",config_sequence::get_type());
//main_phase sequence is set in each test
uvm_config_db#(uvm_object_wrapper)::set(this,"env.m_agent.seqr.shutdown_phase","default_sequence",shutdown_sequence::get_type());

endfunction

function void base_test::start_of_simulation_phase(uvm_phase phase);
	super.start_of_simulation_phase(phase);
  uvm_root::get().print_topology();
endfunction

task base_test::main_phase (uvm_phase phase);
uvm_objection objection;
super.main_phase(phase);
objection=phase.get_objection();
//The drain time is the amount of time to wait once all objections have been dropped
objection.set_drain_time(this,100ns);
endtask

//give the monitors time to see the last read data before the test ends
task base_test::shutdown_phase (uvm_phase phase);
uvm_objection objection;
super.shutdown_phase(phase);
objection=phase.get_objection();
objection.set_drain_time(this,100ns);
endtask

function void base_test::report_phase(uvm_phase phase);
uvm_report_server svr;
super.report_phase(phase);
svr = uvm_report_server::get_server();

if(svr.get_severity_count(UVM_FATAL) + svr.get_severity_count(UVM_ERROR) > 0) begin
  `uvm_info("FAIL","******************************************",UVM_NONE);
  `uvm_info("FAIL",$sformatf("*********  %0s : TEST FAILED  *********",get_type_name()),UVM_NONE);
  `uvm_info("FAIL","******************************************",UVM_NONE);
end
else begin
  `uvm_info("PASS","******************************************",UVM_NONE);
  `uvm_info("PASS",$sformatf("*********  %0s : TEST PASSED  *********",get_type_name()),UVM_NONE);
  `uvm_info("PASS","******************************************",UVM_NONE);
end
endfunction
