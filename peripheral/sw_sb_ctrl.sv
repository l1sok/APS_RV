module sw_sb_ctrl(
  input  logic        clk_i,
  input  logic        rst_i,
  input  logic        req_i,
  input  logic        write_enable_i,
  input  logic [31:0] addr_i,
  input  logic [31:0] write_data_i,  
                                   
  output logic [31:0] read_data_o,

  output logic        interrupt_request_o,
  input  logic        interrupt_return_i,

  input logic [15:0]  sw_i
    );


logic  val_addr;
assign val_addr = addr_i == 32'h0;
   
logic read_enable;
assign read_enable = val_addr & req_i & ~write_enable_i;

logic [31:0] prev_sw;
logic [31:0] sw;
assign sw = {16'b0, sw_i};

always_ff @(posedge clk_i)   
prev_sw <= sw;

always_ff @(posedge clk_i)
if (rst_i | interrupt_return_i) interrupt_request_o <=1'b0;
else if (prev_sw != sw)         interrupt_request_o <= 1'b1;
else                            interrupt_request_o <= interrupt_request_o;

always_ff @(posedge clk_i)   
if (rst_i)             read_data_o <= 32'b0;
else  if (read_enable) read_data_o <= sw;
else                   read_data_o <= read_data_o;

endmodule
