class oMonitor extends uvm_monitor;
`uvm_component_utils(oMonitor)

virtual memory_if.tb_mon_out vif;
// This TLM port is used to connect the monitor to the scoreboard
uvm_analysis_port #(packet) analysis_port;

// Current monitored transaction
packet pkt;

function new (string name="oMonitor",uvm_component parent);
	super.new(name,parent);
endfunction

extern virtual task run_phase(uvm_phase phase);
extern virtual function void build_phase(uvm_phase phase);
extern virtual function void connect_phase(uvm_phase phase);
endclass

function void oMonitor::build_phase(uvm_phase phase) ;
	super.build_phase(phase);
//create TLM port
    analysis_port=new("analysis_port",this);
endfunction

function void oMonitor::connect_phase(uvm_phase phase);
    super.connect_phase(phase);
	if (!uvm_config_db#(virtual memory_if.tb_mon_out)::get(this, "", "oMon_if", vif)) begin
          `uvm_fatal(get_type_name(), "oMonitor Virtual Interface is not set");
         end
endfunction

//DUT gives the result one clock after the request:
//read at edge N  -> rdata is sampled at edge N+1
//write at edge N -> response is sampled at edge N+1
//So remember last cycle's rd/wr/addr and send the result in the next cycle.
task oMonitor::run_phase(uvm_phase phase);
 bit prev_rd, prev_wr;
 logic [7:0] prev_addr;
 int cycle;

 forever begin
    @(vif.cb_mon_out);
    cycle++;

    if(vif.cb_mon_out.reset === 1'b1) begin
        prev_rd = 0;
        prev_wr = 0;
        continue;
    end

    if(prev_rd) begin
        pkt = packet::type_id::create("pkt",this);
        pkt.kind  = READ;
        pkt.addr  = prev_addr;
        pkt.data  = vif.cb_mon_out.rdata;//read data, can be Z
        pkt.cycle = cycle;
        `uvm_info(get_type_name(),pkt.convert2string(),UVM_HIGH);
        analysis_port.write(pkt);
    end

    if(prev_wr) begin
        pkt = packet::type_id::create("pkt",this);
        pkt.kind    = WRITE;
        pkt.addr    = prev_addr;
        pkt.slv_rsp = (vif.cb_mon_out.slv_rsp === 1'b1) ? OK : ERROR;
        pkt.cycle   = cycle;
        `uvm_info(get_type_name(),$sformatf("WRITE addr=%0h resp=%0s",pkt.addr,pkt.slv_rsp.name()),UVM_HIGH);
        analysis_port.write(pkt);
    end

    prev_rd   = (vif.cb_mon_out.rd === 1'b1);
    prev_wr   = (vif.cb_mon_out.wr === 1'b1);
    prev_addr = vif.cb_mon_out.addr;
 end

endtask
