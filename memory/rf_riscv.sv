module rf_riscv(
  input  logic        clk_i,
  input  logic        write_enable_i,

  input  logic [4:0] write_addr_i,
  input  logic [4:0] read_addr1_i,
  input  logic [4:0] read_addr2_i,

  input  logic [31:0] write_data_i,
  output logic [31:0] read_data1_o,
  output logic [31:0] read_data2_o
);

logic [31:0] rf_mem [0:31];
assign rf_mem[0][31:0] = 32'b0;

logic wa;
assign wa = |write_addr_i;
 
always_ff @(posedge clk_i) begin
rf_mem [write_addr_i] <= (write_enable_i & wa)? write_data_i : rf_mem[write_addr_i];
end

assign read_data1_o = rf_mem[read_addr1_i];
assign read_data2_o = rf_mem[read_addr2_i];

endmodule
