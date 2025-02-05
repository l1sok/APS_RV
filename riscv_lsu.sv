module riscv_lsu(
  input logic clk_i,
  input logic rst_i,


  input  logic        core_req_i,
  input  logic        core_we_i,
  input  logic [ 2:0] core_size_i,
  input  logic [31:0] core_addr_i,
  input  logic [31:0] core_wd_i,
  output logic [31:0] core_rd_o,
  output logic        core_stall_o,


  output logic        mem_req_o,
  output logic        mem_we_o,
  output logic [ 3:0] mem_be_o,
  output logic [31:0] mem_addr_o,
  output logic [31:0] mem_wd_o,
  input  logic [31:0] mem_rd_i,
  input  logic        mem_ready_i
);

import decoder_pkg::*;

reg stall_reg; 

assign mem_addr_o = core_addr_i;
assign mem_we_o   = core_we_i;
assign mem_req_o  = core_req_i;

assign core_stall_o = ~(mem_ready_i&stall_reg)&core_req_i;

always_ff @(posedge clk_i)
    stall_reg <= ~rst_i & core_stall_o;

always_comb
    case (core_size_i)
        LDST_B:  mem_be_o = 4'b0001<<core_addr_i[1:0];
        LDST_H:  mem_be_o = core_addr_i[1]? 4'b1100: 4'b0011;
        default: mem_be_o = 4'b1111;
    endcase
 
 always_comb
    case (core_size_i)
        LDST_B:  mem_wd_o = {{4{core_wd_i[7:0]}}};
        LDST_H:  mem_wd_o = {{2{core_wd_i[15:0]}}};
        default: mem_wd_o = core_wd_i;
   endcase
   
always_comb
    case (core_size_i)
        LDST_B:
               case (core_addr_i[1:0])
                   2'b00:    core_rd_o = {{24{mem_rd_i[7]}}, mem_rd_i[7:0]};
                   2'b01:    core_rd_o = {{24{mem_rd_i[15]}}, mem_rd_i[15:8]};
                   2'b10:    core_rd_o = {{24{mem_rd_i[23]}}, mem_rd_i[23:16]};
                   default:  core_rd_o = {{24{mem_rd_i[31]}}, mem_rd_i[31:24]};
               endcase
        LDST_BU:
               case (core_addr_i[1:0])
                   2'b00:    core_rd_o = {24'b0, mem_rd_i[7:0]};
                   2'b01:    core_rd_o = {24'b0, mem_rd_i[15:8]};
                   2'b10:    core_rd_o = {24'b0, mem_rd_i[23:16]};
                   default:  core_rd_o = {24'b0, mem_rd_i[31:24]};
               endcase
        LDST_H:  core_rd_o = (core_addr_i[1])? {{16{mem_rd_i[31]}}, mem_rd_i[31:16]} : { {16{mem_rd_i[15]}}, mem_rd_i[15:0]};
        LDST_HU:  core_rd_o = (core_addr_i[1])? {16'b0, mem_rd_i[31:16]} : {16'b0, mem_rd_i[15:0]};
        default: core_rd_o = mem_rd_i;
    endcase
endmodule
