module riscv_core (

  input  logic        clk_i,
  input  logic        rst_i,

  input  logic        stall_i,
  input  logic [31:0] instr_i,
  input  logic [31:0] mem_rd_i,
  input  logic [15:0] irq_req_i,

  output logic [31:0] instr_addr_o,
  output logic [31:0] mem_addr_o,
  output logic [ 2:0] mem_size_o,
  output logic        mem_req_o,
  output logic        mem_we_o,
  output logic [31:0] mem_wd_o,
  output logic [15:0] irq_ret_o
);

logic [31:0] imm_I;
logic [31:0] imm_U;
logic [31:0] imm_S;
logic [31:0] imm_B;
logic [31:0] imm_J;
logic [31:0] imm_Z;

assign imm_I ={ {20{instr_i[31]}}, instr_i[31:20]};
assign imm_U = {instr_i[31:12], 12'h000}; 
assign imm_S ={ {20{instr_i[31]}}, instr_i[31:25], instr_i[11:7]};
assign imm_B ={ {20{instr_i[31]}}, instr_i[7], instr_i[30:25], instr_i[11:8], 1'b0};
assign imm_J ={ {12{instr_i[31]}}, instr_i[19:12], instr_i[20], instr_i[30:21], 1'b0};
assign imm_Z = { 27'b0, instr_i[19:15]};

logic [31:0] PC_jr;
reg   [31:0] PC;
logic [31:0] prev_next_PC;
logic [31:0] next_PC;
logic [31:0] PC_j;
logic [31:0] imm_PC_j;
logic [31:0] mepc;
logic [31:0] mtvec;
logic [31:0] PC_mepc;
logic [31:0] PC_mtvec;

logic [1:0] a_sel;
logic [2:0] b_sel; 
logic [1:0] wb_sel; 

logic [31:0] wb_data;
logic [31:0] rd_1;
logic        gpr_we;
logic        we_r;
logic        mem_we;
logic        mem_req;

logic jal;
logic jalr;
logic branch; 

logic alu_flag;            
logic [31:0] a_alu;
logic [31:0] b_alu;
logic [31:0] alu_result;
logic [4:0]  ALU_OP;

logic ill_instr;
logic irq;
logic [31:0] irq_cause;
logic trap;
logic mret;
logic [31:0] mie;
logic [31:0] csr_wd;
logic [2:0] csr_op;
logic csr_we;

assign trap = ill_instr | irq;

logic jump_flag;

assign jump_flag = jal | (alu_flag & branch);



assign we_r = gpr_we & ~(stall_i | trap);

assign PC_j     = branch? imm_B : imm_J;
assign imm_PC_j = jump_flag? PC_j : 32'b100;
assign PC_mtvec  = jalr? {PC_jr[31:1], 1'b0}: prev_next_PC;  
assign PC_mepc = trap? mtvec : PC_mtvec;
assign next_PC = mret? mepc: PC_mepc;
  
assign instr_addr_o = PC;
assign mem_we_o     = mem_we & ~trap; 
assign mem_req_o    = mem_req & ~trap;

always_comb
case (wb_sel)
    2'b00: wb_data   = alu_result;
    2'b01: wb_data   = mem_rd_i;
    default: wb_data = csr_wd;
endcase

always_comb
case (a_sel)
    2'b00: a_alu   = rd_1;
    2'b01: a_alu   = PC;
    default: a_alu = 32'b0;
endcase

always_comb
case (b_sel)
    3'b000: b_alu  = mem_wd_o;
    3'b001: b_alu  = imm_I;
    3'b010: b_alu  = imm_U;
    3'b011: b_alu  = imm_S;
    default: b_alu = 32'b100;
endcase

assign mem_addr_o = alu_result;

always_ff @(posedge clk_i)   
begin       
if (rst_i) PC <= 32'b0; 
else if (~stall_i | trap) begin
    PC <= next_PC;
 end
end

fulladder32 PC_jalr(.a_i(rd_1),
             .b_i(imm_I),
             .carry_i(1'b0),
             .sum_o(PC_jr));
             
fulladder32 PC_jump (.a_i(PC),
                  .b_i(imm_PC_j),
                  .carry_i(1'b0),
                  .sum_o(prev_next_PC));
                  
csr_controller crs_cntrl(

 .clk_i(clk_i),
 .rst_i(rst_i),
 .trap_i(trap),

 .opcode_i(csr_op),

 .addr_i(instr_i[31:20]),
 .pc_i(PC),
 .mcause_i(ill_instr? 32'h0000_0002 : irq_cause),
 .rs1_data_i(rd_1),
 .imm_data_i(imm_Z),
 .write_enable_i(csr_we),

 .read_data_o(csr_wd),
 .mie_o(mie),
 .mepc_o(mepc),
 .mtvec_o(mtvec)
);
                 
interrupt_controller irq_cntr(
                      .clk_i(clk_i),
                      .rst_i(rst_i),
                      .exception_i(ill_instr),
                      .irq_req_i(irq_req_i),
                      .mie_i(mie[15:0]),
                      .mret_i(mret),
                      .irq_ret_o(irq_ret_o),
                      .irq_cause_o(irq_cause),
                      .irq_o(irq)
);    

decoder_riscv decoder (.fetched_instr_i (instr_i),
             .a_sel_o (a_sel),
             .b_sel_o (b_sel),
             .alu_op_o (ALU_OP),
             .csr_op_o (csr_op),
             .csr_we_o (csr_we),
             .mem_req_o (mem_req),
             .mem_we_o (mem_we),
             .mem_size_o (mem_size_o),
             .gpr_we_o (gpr_we),
             .wb_sel_o (wb_sel),
             .illegal_instr_o (ill_instr),
             .branch_o (branch),
             .jal_o (jal),
             .jalr_o (jalr),
             .mret_o (mret));

rf_riscv register_file (.clk_i(clk_i),
                        .write_enable_i(we_r),
                        .write_addr_i(instr_i[11:7]),
                        .read_addr1_i(instr_i[19:15]),
                        .read_addr2_i(instr_i[24:20]),
                        .write_data_i(wb_data),
                        .read_data1_o(rd_1),
                        .read_data2_o(mem_wd_o));
                        
alu_riscv ALU (.a_i(a_alu),
               .b_i(b_alu),
               .alu_op_i(ALU_OP),
               .flag_o(alu_flag),
               .result_o(alu_result));
               
               
endmodule

