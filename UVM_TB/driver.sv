class driver extends uvm_driver#(packet);
`uvm_component_utils(driver)

bit [31:0] pkt_id;
virtual memory_if.tb vif;
bit send_resp;
realtime last_clk = -1;//time of the last clock edge the driver waited for

function new (string name="driver",uvm_component parent);
	super.new(name,parent);
endfunction

extern virtual task run_phase(uvm_phase phase);
extern virtual function void connect_phase(uvm_phase phase);
extern virtual task wait_clk();
extern virtual task write(input packet pkt);
extern virtual task read(input packet pkt);
extern virtual task drive_reset();
extern virtual task drive(packet pkt);
extern virtual task config_reg_read(packet pkt);
extern virtual task drive_stimulus(packet pkt);
endclass

//Every task below starts right after a clock edge and ends right after a clock edge.
//So each item takes whole clock cycles and items can go back to back.
task driver::run_phase(uvm_phase phase);
vif.cb.wr <= 1'b0;
vif.cb.rd <= 1'b0;
wait_clk();

forever begin
 seq_item_port.get_next_item(req);

 //sequence was not ready at the last edge, line up with the clock again
 if($realtime != last_clk) wait_clk();
 repeat(req.idle) wait_clk();

 drive(req);

 //go back to idle. If the next item comes in this same time step it
 //overwrites these values, so back to back items still work.
 vif.cb.wr <= 1'b0;
 vif.cb.rd <= 1'b0;
 seq_item_port.item_done();

 if(req.kind==STIMULUS) pkt_id++;
 `uvm_info("driver",$sformatf("Driver %0s Transaction %0d Completed",req.kind.name(),pkt_id),UVM_HIGH);
end

endtask

task driver::wait_clk();
@(vif.cb);
last_clk = $realtime;
endtask

task driver::drive(packet pkt);
    case (pkt.kind)
    RESET            : drive_reset();
    WRITE, CSR_WRITE : write(pkt);
    READ             : read(pkt);
    CSR_READ         : config_reg_read(pkt);
	STIMULUS         : drive_stimulus(pkt);
    default          : begin `uvm_warning("drvr","Unknown Packet received in Driver"); end
endcase
endtask

//write followed by read to the same address
task driver::drive_stimulus(packet pkt);
if(pkt.wr) write(pkt);
if(pkt.rd) read(pkt);
//response of the write is sampled at the same edge where the read is taken
if(send_resp) begin
    rsp=packet::type_id::create("rsp",this);
    rsp.slv_rsp = vif.cb.slv_rsp === 1'b1 ? OK : ERROR ;
    rsp.set_id_info(pkt);
    seq_item_port.put_response(rsp);
 end
endtask


function void driver::connect_phase(uvm_phase phase);
    super.connect_phase(phase);
	void'(uvm_config_db#(bit)::get(this,"", "set_resp_for_drvr",send_resp ));

  if(!uvm_config_db#(virtual memory_if.tb)::get(this,"","drvr_if",vif)) begin
    `uvm_fatal("VIF_ERR","Virtual interface in driver is NULL ");
    end

endfunction

task driver::write(input packet pkt);
  `uvm_info("DRV_WS"," Write transaction started...",UVM_FULL);
vif.cb.wr      <= 1'b1;
vif.cb.rd      <= 1'b0;
vif.cb.addr    <= pkt.addr;
vif.cb.wdata   <= pkt.data;
wait_clk();
  `uvm_info("DRV_WE",$sformatf("Write transaction ended with addr=%0h data=%0h",pkt.addr,pkt.data),UVM_HIGH);
endtask

task driver::read(input packet pkt);
  `uvm_info("RD_S"," Read transaction started...",UVM_FULL);
vif.cb.rd      <= 1'b1;
vif.cb.wr      <= 1'b0;
vif.cb.addr    <= pkt.addr;
wait_clk();
  `uvm_info("RD_E",$sformatf("Read transaction ended with addr=%0h ",pkt.addr) ,UVM_HIGH);
endtask

//idle one cycle first so the read data of the last item is seen before reset
task driver::drive_reset();
  `uvm_info("RST","Reset transaction started...",UVM_FULL);
vif.cb.wr      <= 1'b0;
vif.cb.rd      <= 1'b0;
wait_clk();
vif.cb.reset   <= 1'b1;
repeat (2) wait_clk();
vif.cb.reset   <= 1'b0;
  `uvm_info("RST","Reset transaction ended ",UVM_HIGH);
endtask

//DUT takes the read at the first edge, data is on rdata at the next edge
task driver::config_reg_read(packet pkt);
  `uvm_info("CSR_RD","Configuration READ transaction started...",UVM_FULL);
read(pkt);
vif.cb.rd <= 1'b0;
wait_clk();
  pkt.data=vif.cb.rdata;
  `uvm_info("CSR_RD",$sformatf("Configration READ transaction ended addr=%0h data=%0h",pkt.addr,pkt.data),UVM_HIGH);
endtask
