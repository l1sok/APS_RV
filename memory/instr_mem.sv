///////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 24.07.2024 16:52:05
// Design Name: 
// Module Name: instr_mem
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module instr_mem
import memory_pkg::INSTR_MEM_SIZE_BYTES;
import memory_pkg::INSTR_MEM_SIZE_WORDS;
 ( input logic  [31:0] adr_i,
   output logic [31:0] read_data_o
    );
   
 logic [31:0] ROM [INSTR_MEM_SIZE_WORDS];
 
 initial begin
 $readmemh("program.mem", ROM);
 end
  
  assign read_data_o = ROM[adr_i[$clog2(INSTR_MEM_SIZE_BYTES)-1:2]];
  
endmodule
