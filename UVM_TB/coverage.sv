class coverage extends uvm_subscriber#(packet);
`uvm_component_utils(coverage)

    real coverage_score;

    //state the coverage needs to know, updated from the packets it sees
    bit        chip_on;
    int        last_cycle = -10;
    pkt_type_e last_kind  = READ;

   covergroup cov_mem with function sample(packet pkt, bit chip, bit b2b, pkt_type_e prev_kind);
     option.per_instance = 1;//show this instance in the coverage report
     option.comment = "memory model functional coverage";

     cp_kind : coverpoint pkt.kind {
       bins read  = {READ};
       bins write = {WRITE};
     }

     cp_addr : coverpoint pkt.addr {
       bins mem[]    = {[0:15]};
       bins status   = {'h18};
       bins chip_en  = {'h20};
       bins csr3     = {'h24};
       bins dropped  = {'h26};
       bins unmapped = {[16:'h17], ['h19:'h1F], ['h21:'h23], 'h25, ['h27:'hFF]};
     }

     cp_region : coverpoint pkt.addr {
       bins mem      = {[0:15]};
       bins csr      = {'h18, 'h20, 'h24, 'h26};
       bins unmapped = {[16:'h17], ['h19:'h1F], ['h21:'h23], 'h25, ['h27:'hFF]};
     }

     cp_csr : coverpoint pkt.addr {
       bins status  = {'h18};
       bins chip_en = {'h20};
       bins csr3    = {'h24};
       bins dropped = {'h26};
     }

     cp_chip : coverpoint chip {
       bins off = {0};
       bins on  = {1};
     }

     cp_wdata : coverpoint pkt.data iff (pkt.kind == WRITE) {
       bins zero   = {0};
       bins ones   = {32'hFFFF_FFFF};
       bins others = {[1:32'hFFFF_FFFE]};
     }

     //operation in the cycle before, only when there was no idle cycle
     cp_last : coverpoint prev_kind iff (b2b) {
       bins read  = {READ};
       bins write = {WRITE};
     }

     kind_region_chip : cross cp_kind, cp_region, cp_chip;
     kind_csr         : cross cp_kind, cp_csr;
     back_to_back     : cross cp_last, cp_kind iff (b2b);
   endgroup

function new (string name="coverage",uvm_component parent);
super.new(name,parent);
cov_mem=new;
endfunction

virtual function void write( T t);
bit b2b;

if (t == null) begin
    `uvm_fatal("COV","Transaction object supplied is NULL in coverage component");
end

if(t.kind == RESET) begin
  chip_on    = 0;
  last_cycle = -10;
  return;
end

b2b = (t.cycle == last_cycle + 1);
cov_mem.sample(t, chip_on, b2b, last_kind);
coverage_score=cov_mem.get_coverage();

//update state after sampling
if(t.kind == WRITE && t.addr == 'h20)
  chip_on = t.data[0];
last_cycle = t.cycle;
last_kind  = t.kind;

  `uvm_info("COV",$sformatf("Coverage=%0.2f%%",coverage_score),UVM_HIGH);
endfunction

function void report_phase(uvm_phase phase);
  `uvm_info("COV",$sformatf("Functional coverage for this test = %0.2f%%",coverage_score),UVM_NONE);
endfunction

endclass
