module memory_rtl (clk,reset,wr,rd,addr,wdata,rdata,response);

//Synchronous write read memory
parameter reg [15:0] ADDR_WIDTH=8;
parameter reg [15:0] DATA_WIDTH=32;
parameter reg [15:0] MEM_SIZE=16;

input   clk,reset;
input   wr;// for write wr=1;
input   rd;// for read  rd=1;
input   [ADDR_WIDTH-1:0] addr;
input   [DATA_WIDTH-1:0] wdata;
output  [DATA_WIDTH-1:0] rdata;
output response;

wire    [DATA_WIDTH-1:0] rdata;
reg     [DATA_WIDTH-1:0] mem [MEM_SIZE];
reg     [DATA_WIDTH-1:0] data_out;

reg     [(DATA_WIDTH/2) -1:0] wr_count;
reg     [(DATA_WIDTH/2) -1:0] rd_count;


//csr1_wr_count is a read only(status) register. This register cannot be written through input ports.
//csr1_wr_count[15:0]  maintaines status on total writes to memory model
//csr1_wr_count[31:16] maintaines status on total reads to memory model
reg [DATA_WIDTH-1:0] csr1_wr_count;//addr 'h18 = 'd24

//csr2_CHIP_EN controls the device actual read/write operations.
//Write value 1 from Testbench to make the memory model ON.
reg [7:0]  csr2_CHIP_EN;//addr 'h20 = 'd32

//Reserved for future.
reg [31:0] csr3;//addr 'h24 = 'd36  //Reseved for future

//csr4_dropped is status register maintaines count of dropped write/operations .
//csr4_dropped is a read only register. This register cannot be written through input ports.
reg [31:0] csr4_dropped;//addr 'h26 = 'd38

reg response ;//Provides response to master on successful write
reg out_enable;//controls when to pass read data on rdata pin

//if wr=1 rdata should be in high impedance state
//if wr=0 rdata should be content of memory with given address
assign rdata = (out_enable & csr2_CHIP_EN[0])  ? data_out : 'bz;

//Bug fixes found by the testbench are inside `ifndef ORIGINAL_RTL.
//Compile with +define+ORIGINAL_RTL to get back the original design.

//asynchronous reset and synchronous write
always @(posedge clk or posedge reset)
begin
    if (reset) begin
        for(int i=0;i<MEM_SIZE;i++)
            mem[i] <= 'b0;

	    csr1_wr_count <='b0;
	    csr2_CHIP_EN <='b0;
	    csr3 <='b0;
	    csr4_dropped <= 'b0;
      wr_count<='b0;
      rd_count <= 'b0;
`ifndef ORIGINAL_RTL
      response <= 1'b0;
`endif
	end
    else if(wr ) begin
`ifndef ORIGINAL_RTL
      //fix: clear response first, only a good memory write sets it to 1.
      //Before this, response stayed 1 for a dropped/CSR write that came
      //right after a good write.
      response <= 1'b0;
`endif
	 casex (addr)
		16'h0020 : csr2_CHIP_EN <= wdata;
		16'h0024 : csr3  <= wdata;
		default  : begin
		       if(csr2_CHIP_EN[0] && (addr inside {[0:15]}) ) begin
                 mem[addr[3:0]] <= wdata ;
                    wr_count++;

			   		response <=1'b1;
		       end else
			   		csr4_dropped++;
		   end//end_of_default
	  endcase //end_of_case
        end
    else response <=1'b0;
end//end_of_write


//Synchronous Read
always @(posedge clk )
begin
  if(rd==1) begin
	   	casex(addr)
        16'h0018 : begin
                         csr1_wr_count={rd_count,wr_count};
                         data_out <=csr1_wr_count;
                    end
        16'h0020 : data_out <= {24'h0,csr2_CHIP_EN};
		16'h0024 : data_out <= csr3;
		16'h0026 : data_out <= csr4_dropped;
		 default  : begin
		     if(csr2_CHIP_EN[0] && (addr inside {[0:15]}) ) begin
				  data_out <= mem[addr[3:0]] ;
				  rd_count++;
                 end
`ifndef ORIGINAL_RTL
             //fix: unmapped address returns 0. Before this the old
             //data_out (last read value or X) was put on rdata.
             else
                  data_out <= 'b0;
`endif
			    end

	     endcase //end_of_case
	    out_enable <= 1'b1;
	end
	else out_enable <=1'b0;

end//end_of_read

endmodule
