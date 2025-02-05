module csr_controller(

  input  logic        clk_i,
  input  logic        rst_i,
  input  logic        trap_i,

  input  logic [ 2:0] opcode_i,

  input  logic [11:0] addr_i,
  input  logic [31:0] pc_i,
  input  logic [31:0] mcause_i,
  input  logic [31:0] rs1_data_i,
  input  logic [31:0] imm_data_i,
  input  logic        write_enable_i,

  output logic [31:0] read_data_o,
  output logic [31:0] mie_o,
  output logic [31:0] mepc_o,
  output logic [31:0] mtvec_o
);

import csr_pkg::*;
logic [31:0] mux_rd;
logic [4:0] we;

reg [31:0] mie_reg;
reg [31:0] mepc_reg;
reg [31:0] mtvec_reg;
reg [31:0] mcause_reg;
reg [31:0] mscratch_reg;


always_comb
case (opcode_i)
    CSR_RW:  mux_rd = rs1_data_i;
    CSR_RS:  mux_rd = rs1_data_i | read_data_o;
    CSR_RC:  mux_rd = ~rs1_data_i & read_data_o;
    CSR_RWI: mux_rd = imm_data_i;
    CSR_RSI: mux_rd = imm_data_i | read_data_o;
    default:  mux_rd = ~imm_data_i & read_data_o;
endcase

always_comb
case (addr_i)
    MIE_ADDR:      we = {4'b0000, write_enable_i};    
    MTVEC_ADDR:    we = {3'b000, write_enable_i, 1'b0};
    MSCRATCH_ADDR: we = {2'b00, write_enable_i, 2'b00};
    MEPC_ADDR:     we = {1'b0, write_enable_i, 3'b000};
    default:       we = {write_enable_i, 4'b0000};
endcase

always_comb
case (addr_i)
    MIE_ADDR:      read_data_o = mie_reg;
    MTVEC_ADDR:    read_data_o = mtvec_reg;
    MSCRATCH_ADDR: read_data_o = mscratch_reg;
    MEPC_ADDR:     read_data_o = mepc_reg;
    default:       read_data_o = mcause_reg;
endcase

always_ff @(posedge clk_i)
    begin
        if (rst_i) mie_reg <=32'b0;      else if (we[0])             mie_reg <= mux_rd; 
        if (rst_i) mtvec_reg <=32'b0;    else if (we[1])           mtvec_reg <= mux_rd; 
        if (rst_i) mscratch_reg <=32'b0; else if (we[2])        mscratch_reg <= mux_rd; 
        if (rst_i) mepc_reg <=32'b0;     else if (we[3] | trap_i)   mepc_reg <= trap_i? pc_i : mux_rd; 
        if (rst_i) mcause_reg <=32'b0;   else if (we[4] | trap_i) mcause_reg <= trap_i? mcause_i : mux_rd; 
    end

assign mie_o = mie_reg;
assign mepc_o = mepc_reg;
assign mtvec_o = mtvec_reg;

endmodule
