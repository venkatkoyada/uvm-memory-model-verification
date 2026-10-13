class environment extends uvm_env;
`uvm_component_utils(environment)

	bit cov_enable;

	master_agent  m_agent;
	slave_agent   s_agent;
	scoreboard    scb;
	coverage      cov_comp;

	function new (string name="environment",uvm_component parent=null);
		super.new(name,parent);
	endfunction

	extern virtual function void build_phase(uvm_phase phase);
	extern virtual function void connect_phase(uvm_phase phase);
endclass

function void environment::build_phase(uvm_phase phase);
	super.build_phase(phase);

  m_agent=master_agent::type_id::create("m_agent",this);
	s_agent=slave_agent::type_id::create("s_agent",this);
    scb=scoreboard::type_id::create("scb",this);
  	void'(uvm_config_db#(bit)::get(this,"","enable_coverage",cov_enable));
	if(cov_enable)
	    cov_comp=coverage::type_id::create("cov_comp",this);
endfunction

function void environment::connect_phase(uvm_phase phase);
   super.connect_phase(phase);
   m_agent.ap.connect(scb.mon_inp);
   s_agent.ap.connect(scb.mon_outp);
   if(cov_enable)
      m_agent.ap.connect(cov_comp.analysis_export);
endfunction
