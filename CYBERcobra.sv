module CYBERcobra(
    input logic         clk_i,
    input logic         rst_i,
    input logic  [15:0] sw_i,
    output logic [31:0] out_o
    );
logic [31:0] PC;
logic [31:0] next_PC; 
logic [31:0] read_instr;
logic [31:0] mux_PC_add;

logic [4:0] read_addr1;
logic [4:0] read_addr2;
logic [4:0] write_addr;

logic [31:0] read_data1;
logic [31:0] read_data2;
logic [31:0] write_data;
logic [31:0] alu_res;

logic [1:0] WS;

logic      WE;
logic      flag;
logic      jump;

instr_mem imem (.adr_i(PC),
                 .read_data_o(read_instr));
                 
assign read_addr1 = read_instr[22:18];
assign read_addr2 = read_instr[17:13];
assign write_addr = read_instr[4:0];
assign WE = ~(read_instr[31]|read_instr[30]); 
assign WS = read_instr[29:28];

logic carry_in;
assign carry_in = 1'b0;

always @(posedge(clk_i))
case(WS)
2'b00:   write_data = ({{9{read_instr[27]}},read_instr[27:5]});
2'b01:   write_data = alu_res;
2'b10:   write_data = ({{16{sw_i[15]}},sw_i[15:0]});
default: write_data = 32'b0;
endcase      

       
rf_riscv register_file (.clk_i(clk_i),
                        .write_enable_i(WE),
                        .write_addr_i(write_addr),
                        .read_addr1_i(read_addr1),
                        .read_addr2_i(read_addr2),
                        .write_data_i(write_data),
                        .read_data1_o(read_data1),
                        .read_data2_o(read_data2));    

alu_riscv ALU (.a_i(read_data1[31:0]),
               .b_i(read_data2[31:0]),
               .alu_op_i(read_instr[27:23]),
               .flag_o(flag),
               .result_o(alu_res[31:0]));  
               
              

assign jump = read_instr[31] | (read_instr[30]&flag);  
logic [31:0] SE_add_const;
assign SE_add_const = {{22{read_instr[12]}}, read_instr[12:5], 2'b0};            
assign mux_PC_add = jump? SE_add_const :32'd4;
fulladder32 pc_add (.a_i(PC),
                    .b_i(mux_PC_add),
                    .carry_i(carry_in),
                    .sum_o(next_PC));

always @(posedge clk_i)
PC <= (rst_i)? 32'b0 : next_PC;

assign out_o = read_data1;

endmodule
