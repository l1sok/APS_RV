module interrupt_controller(
  input  logic        clk_i,
  input  logic        rst_i,
  input  logic        exception_i,
  input  logic [15:0] irq_req_i,
  input  logic [15:0] mie_i,
  input  logic        mret_i,

  output logic [15:0] irq_ret_o,
  output logic [31:0] irq_cause_o,
  output logic        irq_o
);

reg exc_h;
reg irq_h;

logic exc_set;
assign exc_set = exception_i | exc_h;

always_ff @(posedge clk_i)
exc_h <= exc_set & ~mret_i & ~rst_i;

always_ff @(posedge clk_i)
irq_h <= (irq_h | irq_o) & ~(mret_i & ~exc_set) & ~rst_i;

daisy_chain daisy_chain(
.clk_i(clk_i), 
.rst_i(rst_i), 
.ready_i(~(irq_h | exc_set)), 
.irq_ret_i(mret_i & ~exc_set),
.masked_irq_i(irq_req_i & mie_i),
.irq_o(irq_o),
.irq_ret_o(irq_ret_o),
.irq_cause_o(irq_cause_o)   
 );

endmodule

