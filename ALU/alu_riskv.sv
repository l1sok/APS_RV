module alu_riscv(
  input  logic [31:0]  a_i,
  input  logic [31:0]  b_i,
  input  logic [4:0]   alu_op_i,
  output  logic          flag_o,
  output logic [31:0]  result_o
);
logic [31:0] B;
assign B = alu_op_i[3]? ~b_i: b_i;
logic [31:0] ADDER;
fulladder32 sub(.a_i(a_i[31:0]), .b_i(B[31:0]), .carry_i(alu_op_i[3]), .sum_o(ADDER[31:0]));
import alu_opcodes_pkg::*;      // èìïîðò ïàðàìåòðîâ, ñîäåðæàùèõ êîäû îïåðàöèé äëÿ ÀËÓ

always_comb
 begin
case (alu_op_i)
ALU_ADD: result_o = ADDER;
ALU_SUB: result_o = ADDER;
ALU_XOR: result_o = a_i ^ b_i;
ALU_OR:  result_o = a_i | b_i;
ALU_AND: result_o = a_i & b_i;
ALU_SLL: result_o = a_i << b_i[4:0];
ALU_SRL: result_o = a_i >> b_i[4:0];
ALU_SRA: result_o = $signed(a_i) >>> b_i[4:0];
ALU_SLTS: result_o = {31'b0, ($signed(a_i)<$signed(b_i))};
ALU_SLTU: result_o = {31'b0, (a_i<b_i)};
default: result_o = 0;
endcase 
end

always_comb 
begin
case (alu_op_i)
ALU_EQ:     flag_o = a_i == b_i;                        
ALU_NE:     flag_o = a_i != b_i;                        
ALU_LTS:    flag_o = $signed(a_i) < $signed(b_i);      
ALU_GES:    flag_o = $signed(a_i) >= $signed(b_i);      
ALU_LTU:    flag_o = a_i < b_i;                         
ALU_GEU:    flag_o = a_i >= b_i;                         
default:    flag_o = 0;
endcase
end

endmodule
