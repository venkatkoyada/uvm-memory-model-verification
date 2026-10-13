`uvm_analysis_imp_decl(_inp)
`uvm_analysis_imp_decl(_outp)

//Scoreboard with a reference model of the memory and the CSRs.
//iMonitor packets (what goes into the DUT) update the model and give the expected result.
//oMonitor packets (what comes out of the DUT) are compared with the expected result.
class scoreboard extends uvm_scoreboard;
`uvm_component_utils(scoreboard)

uvm_analysis_imp_inp  #(packet,scoreboard) mon_inp;
uvm_analysis_imp_outp #(packet,scoreboard) mon_outp;

//model of the DUT
bit [31:0] mem [16];
bit [7:0]  chip_en;
bit [31:0] csr3;
bit [31:0] dropped_cnt;
bit [15:0] wr_count;
bit [15:0] rd_count;

//expected results waiting for the output monitor
packet exp_rd_q[$];
packet exp_wr_q[$];

int unsigned rd_checked, wr_checked;
int unsigned m_matches, m_mismatches;

function new(string name="scoreboard",uvm_component parent=null);
    super.new(name,parent);
endfunction

virtual function void build_phase(uvm_phase phase);
super.build_phase(phase);
mon_inp=new("mon_inp",this);
mon_outp=new("mon_outp",this);
reset_model();
endfunction

function void reset_model();
foreach(mem[i]) mem[i] = 0;
chip_en  = 0;
csr3     = 0;
dropped_cnt  = 0;
wr_count = 0;
rd_count = 0;
if(exp_rd_q.size() != 0 || exp_wr_q.size() != 0)
  `uvm_info("SCB",$sformatf("Reset with %0d reads and %0d writes still pending, removing them",exp_rd_q.size(),exp_wr_q.size()),UVM_LOW)
exp_rd_q.delete();
exp_wr_q.delete();
endfunction

//------------- input side : update the model -------------
virtual function void write_inp(packet pkt);
case(pkt.kind)
  RESET : reset_model();
  READ  : predict_read(pkt);
  WRITE : predict_write(pkt);
  default : `uvm_warning("SCB",$sformatf("Unexpected packet kind %0s from iMonitor",pkt.kind.name()))
endcase
endfunction

function void predict_read(packet pkt);
packet exp;
exp = packet::type_id::create("exp");
exp.kind = READ;
exp.addr = pkt.addr;

if(!chip_en[0])
  exp.data = 'z;//rdata is not driven when chip is off
else begin
  case(pkt.addr)
    'h18 : exp.data = {rd_count, wr_count};
    'h20 : exp.data = {24'h0, chip_en};
    'h24 : exp.data = csr3;
    'h26 : exp.data = dropped_cnt;
    default : begin
      if(pkt.addr < 16) begin
        exp.data = mem[pkt.addr];
        rd_count++;
      end
      else
        exp.data = 0;//unmapped address
    end
  endcase
end
exp_rd_q.push_back(exp);
endfunction

function void predict_write(packet pkt);
packet exp;
exp = packet::type_id::create("exp");
exp.kind    = WRITE;
exp.addr    = pkt.addr;
exp.slv_rsp = ERROR;

case(pkt.addr)
  'h20 : chip_en = pkt.data[7:0];
  'h24 : csr3    = pkt.data;
  default : begin
    if(chip_en[0] && pkt.addr < 16) begin
      mem[pkt.addr] = pkt.data;
      wr_count++;
      exp.slv_rsp = OK;
    end
    else
      dropped_cnt++;//chip off, unmapped address or read only CSR
  end
endcase
exp_wr_q.push_back(exp);
endfunction

//------------- output side : compare -------------
virtual function void write_outp(packet pkt);
packet exp;

if(pkt.kind == READ) begin
  if(exp_rd_q.size() == 0) begin
    `uvm_error("SCB",$sformatf("Read data seen for addr=%0h but no read was expected",pkt.addr))
    return;
  end
  exp = exp_rd_q.pop_front();
  rd_checked++;
  if(pkt.addr !== exp.addr || pkt.data !== exp.data) begin
    m_mismatches++;
    `uvm_error("SCB",$sformatf("READ mismatch addr=%0h expected data=%0h actual data=%0h",exp.addr,exp.data,pkt.data))
  end
  else begin
    m_matches++;
    `uvm_info("SCB",$sformatf("READ match addr=%0h data=%0h",pkt.addr,pkt.data),UVM_HIGH)
  end
end

else if(pkt.kind == WRITE) begin
  if(exp_wr_q.size() == 0) begin
    `uvm_error("SCB",$sformatf("Write response seen for addr=%0h but no write was expected",pkt.addr))
    return;
  end
  exp = exp_wr_q.pop_front();
  wr_checked++;
  if(pkt.addr !== exp.addr || pkt.slv_rsp != exp.slv_rsp) begin
    m_mismatches++;
    `uvm_error("SCB",$sformatf("WRITE response mismatch addr=%0h expected=%0s actual=%0s",exp.addr,exp.slv_rsp.name(),pkt.slv_rsp.name()))
  end
  else begin
    m_matches++;
    `uvm_info("SCB",$sformatf("WRITE response match addr=%0h resp=%0s",pkt.addr,pkt.slv_rsp.name()),UVM_HIGH)
  end
end
endfunction

virtual function void check_phase(uvm_phase phase);
super.check_phase(phase);
if(exp_rd_q.size() != 0)
  `uvm_error("SCB",$sformatf("%0d reads never got their data",exp_rd_q.size()))
if(exp_wr_q.size() != 0)
  `uvm_error("SCB",$sformatf("%0d writes never got their response",exp_wr_q.size()))
if(rd_checked == 0)
  `uvm_error("SCB","No reads were checked, something is wrong with the testbench")
endfunction

function void report_phase(uvm_phase phase);
    `uvm_info("SCB",$sformatf("Scoreboard completed with matches=%0d mismatches=%0d (reads checked=%0d, write responses checked=%0d)",m_matches,m_mismatches,rd_checked,wr_checked),UVM_NONE);
endfunction

endclass
