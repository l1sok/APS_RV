module led_sb_ctrl(

  input  logic        clk_i,
  input  logic        rst_i,
  input  logic        req_i,
  input  logic        write_enable_i,
  input  logic [31:0] addr_i,
  input  logic [31:0] write_data_i,
  output logic [31:0] read_data_o,

  output logic [15:0]  led_o
);

logic is_val_addr;
logic is_mode_addr;
logic is_rst_addr;

assign is_val_addr  = addr_i == 32'h0;
assign is_mode_addr = addr_i == 32'h4;
assign is_rst_addr  = addr_i == 32'h24;

logic write_req;
logic read_req;

assign write_req = req_i & write_enable_i;
assign read_req = req_i & ~write_enable_i;

logic val_valid;
logic mode_valid;
logic rst_valid;

assign val_valid  = write_data_i < 32'h10000;
assign mode_valid = write_data_i < 32'b10;
assign rst_valid  = write_data_i == 1'b1;

logic val_en;
logic mode_en; 
logic rst_en;

assign val_en  = val_valid & is_val_addr & write_req;
assign mode_en = mode_valid & is_mode_addr & write_req;
assign rst_en  = rst_valid & is_rst_addr & write_req;

logic rst;
assign rst = rst_i | rst_en;

reg [15:0]  led_val;
reg         led_mode;
reg rd;
logic rd_en;

assign rd_en = (is_val_addr | is_mode_addr) & read_req;

always_ff @(posedge clk_i)
begin
if (rst)
    led_val <= 16'b0;
else if (val_en)
    led_val <= write_data_i[15:0];
end

always_ff @(posedge clk_i)
begin
if (rst)
    led_mode <= 1'b0;
else if (mode_en)
    led_mode <=  write_data_i[0];
end

always_ff @(posedge clk_i)
begin
    if (rst) 
    rd <= 32'b0; 
    else if (rd_en) rd <= (is_val_addr? {16'b0, led_val} : {31'b0, led_mode});
end

assign read_data_o = rd;

reg cntr_mode;
logic rst_cntr;

assign rst_cntr = rst | ~led_mode | cntr_mode > 32'd20000000;

always_ff @(posedge clk_i)
if (rst_cntr)
    cntr_mode <= 32'b0; 
else if (led_mode)
    cntr_mode <= cntr_mode + 32'b1;
    
assign led_o = (cntr_mode < 32'd10000000)? led_val : 16'b0;

endmodule