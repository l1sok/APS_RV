module daisy_chain(
input logic clk_i, 
input logic rst_i, 
input logic ready_i, 
input logic irq_ret_i,
input logic [15:0] masked_irq_i,

output logic  irq_o,
output logic [15:0] irq_ret_o,
output logic [31:0] irq_cause_o   
 );
 
logic [15:0] cause;
logic [15:0] ready;
reg   [15:0] irq_ret;

assign ready[0] = ready_i;

genvar i;
generate
  for(i = 0; i < 16; i++) begin
    assign cause[i] = ready[i] & masked_irq_i[i];
  end
endgenerate

genvar j;
generate
  for(j = 0; j < 15; j++) begin
    assign ready[j+1] = ~cause[j] & ready[j];
  end
endgenerate



assign irq_o = |cause;
assign irq_cause_o = {12'h800, cause, 4'h0};
assign irq_ret_o = irq_ret_i? irq_ret : 16'b0;

always_ff @(posedge clk_i)
if (rst_i)       irq_ret <= 16'b0;
else if (irq_o)  irq_ret <= cause;
else             irq_ret <= irq_ret;

endmodule
