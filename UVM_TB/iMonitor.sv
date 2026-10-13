class iMonitor extends uvm_monitor;
`uvm_component_utils(iMonitor)

virtual memory_if.tb_mon_in vif;
// This TLM port is used to connect the monitor to the scoreboard
uvm_analysis_port #(packet) analysis_port;

// Current monitored transaction
packet pkt;

function new (string name="iMonitor",uvm_component parent);
	super.new(name,parent);
endfunction

extern virtual task run_phase(uvm_phase phase);
extern virtual function void build_phase(uvm_phase phase);
extern virtual function void connect_phase(uvm_phase phase);
endclass

function void iMonitor::build_phase(uvm_phase phase) ;
	super.build_phase(phase);
    analysis_port=new("analysis_port",this);
endfunction

function void iMonitor::connect_phase(uvm_phase phase);
    super.connect_phase(phase);
	if (!uvm_config_db#(virtual memory_if.tb_mon_in)::get(this, "", "iMon_if", vif)) begin
          `uvm_fatal("iMon", "iMonitor Virtual Interface is not set");
    end
endfunction

//Looks at the DUT inputs on every clock edge.
//Sends one packet for every reset cycle, read and write.
task iMonitor::run_phase(uvm_phase phase);
    int cycle;

    forever begin
        @(vif.cb_mon_in);
        cycle++;

        if(vif.cb_mon_in.reset === 1'b1) begin
            pkt = packet::type_id::create("pkt",this);
            pkt.kind  = RESET;
            pkt.cycle = cycle;
            analysis_port.write(pkt);
            continue;
        end

        if(vif.cb_mon_in.rd === 1'b1) begin
            pkt = packet::type_id::create("pkt",this);
            pkt.kind  = READ;
            pkt.addr  = vif.cb_mon_in.addr;
            pkt.cycle = cycle;
            `uvm_info(get_type_name(),$sformatf("READ addr=%0h",pkt.addr),UVM_HIGH);
            analysis_port.write(pkt);
        end

        if(vif.cb_mon_in.wr === 1'b1) begin
            pkt = packet::type_id::create("pkt",this);
            pkt.kind  = WRITE;
            pkt.addr  = vif.cb_mon_in.addr;
            pkt.data  = vif.cb_mon_in.wdata;//write data
            pkt.cycle = cycle;
            `uvm_info(get_type_name(),pkt.convert2string(),UVM_HIGH);
            analysis_port.write(pkt);
        end
     end

endtask
