`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 27.07.2024 09:42:16
// Design Name: 
// Module Name: data_mem
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

module data_mem
import memory_pkg::DATA_MEM_SIZE_BYTES;
import memory_pkg::DATA_MEM_SIZE_WORDS;
(
  input  logic        clk_i,
  input  logic        mem_req_i,
  input  logic        write_enable_i,
  input  logic [3:0]  byte_enable_i,
  input  logic [31:0] addr_i,
  input  logic [31:0] write_data_i,
  output logic [31:0] read_data_o,
  output logic        ready_o
);

logic [31:0] last_read_data;
logic [31:0] ram [DATA_MEM_SIZE_WORDS];

logic [$clog2(DATA_MEM_SIZE_BYTES)-3:0] addr;
assign addr = addr_i[$clog2(DATA_MEM_SIZE_BYTES)-1:2];

logic write;
logic read;

assign write = mem_req_i & write_enable_i;
assign read = mem_req_i&(~write_enable_i);

always_ff @(posedge clk_i) begin
  if (read) begin
          last_read_data <= ram[addr];
          end
    end
always_ff @(posedge clk_i) 
begin
    if (write & byte_enable_i[3])  ram[addr][31:24] <= write_data_i[31:24]; 
    if (write & byte_enable_i[2])  ram[addr][23:16] <= write_data_i[23:16]; 
    if (write & byte_enable_i[1])  ram[addr][15:8] <= write_data_i[15:8]; 
    if (write & byte_enable_i[0])  ram[addr][7:0] <= write_data_i[7:0]; 
end
       
assign  read_data_o = last_read_data;
assign ready_o = 1'b1;

endmodule
