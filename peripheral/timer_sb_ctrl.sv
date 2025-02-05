module timer_sb_ctrl(
/*
    ×àñòü èíòåðôåéñà ìîäóëÿ, îòâå÷àþùàÿ çà ïîäêëþ÷åíèå ê ñèñòåìíîé øèíå
*/
  input  logic        clk_i,
  input  logic        rst_i,
  input  logic        req_i,
  input  logic        write_enable_i,
  input  logic [31:0] addr_i,
  input  logic [31:0] write_data_i,
  output logic [31:0] read_data_o,
  output logic        ready_o,
/*
    ×àñòü èíòåðôåéñà ìîäóëÿ, îòâå÷àþùàÿ çà îòïðàâêó çàïðîñîâ íà ïðåðûâàíèå
    ïðîöåññîðíîãî ÿäðà
*/
  output logic        interrupt_request_o
);

logic [63:0] system_counter;
logic [63:0] delay;
enum logic [1:0] {OFF, NTIMES, FOREVR} mode, next_mode;
logic [31:0] repeat_counter;
logic [63:0] system_counter_at_start;

logic we;
logic re;

assign we = req_i & write_enable_i;
assign re = req_i & ~write_enable_i;

logic rst;
assign rst = (addr_i==32'h24 & write_data_i==32'h1 & we) | rst_i;

logic is_MSb_timer_addr;
logic is_LSb_timer_addr;
logic is_MSb_delay_addr;
logic is_LSb_delay_addr;
logic is_mode_addr;
logic is_repeat_addr;

assign is_MSb_timer_addr = addr_i == 32'h4;  
assign is_LSb_timer_addr = addr_i == 32'h0;  
assign is_MSb_delay_addr = addr_i == 32'hC;  
assign is_LSb_delay_addr = addr_i == 32'h8;  
assign is_mode_addr      = addr_i == 32'h10;       
assign is_repeat_addr    = addr_i == 32'h14;    

always @(posedge clk_i)
begin
if (rst_i) system_counter <= 64'b0;
else system_counter <= system_counter + 32'b1; 
end

always @(posedge clk_i)
begin
if (rst_i) delay <= 64'b0;
else if (we & (is_LSb_delay_addr | is_MSb_delay_addr)) 
        delay <= is_LSb_delay_addr? {delay[63:32], write_data_i} : {write_data_i, delay [31:0]};                           
     else delay <= delay; 
end

always @(posedge clk_i)
begin
if (rst_i) mode <= OFF;
else mode <= next_mode; 
end

always_comb
begin
if (we & is_mode_addr)
    case(write_data_i)
    32'b0: next_mode = OFF;
    32'b1: next_mode = NTIMES;
  default: next_mode = FOREVR;
    endcase
 else if ((repeat_counter == 32'b0) & (mode == NTIMES)) next_mode = OFF;
      else                         next_mode = mode;
end

always @(posedge clk_i)
begin
if (rst_i) repeat_counter <= 32'b0;
else if (interrupt_request_o & (repeat_counter!=0) & (mode == NTIMES)) 
           repeat_counter <= repeat_counter - 32'b1; 
else if (we & is_repeat_addr) repeat_counter <= write_data_i;
     else  repeat_counter <= repeat_counter;
end 

always @(posedge clk_i)
begin
if (rst_i) system_counter_at_start <= 64'b0;
else if ((interrupt_request_o & (repeat_counter > 32'b1) & (mode == NTIMES)) | 
(interrupt_request_o  & (mode == FOREVR))|
(we & is_mode_addr & ((write_data_i == 32'b01)|(write_data_i == 32'b10)))) 
system_counter_at_start <= system_counter; 
else system_counter_at_start <= system_counter_at_start; 
end

logic [31:0] read_data;

always_comb
case (addr_i)
32'h0:  read_data = system_counter[31:0];
32'h4:  read_data = system_counter[63:32];
32'h8:  read_data = delay[31:0];
32'hC:  read_data = delay[63:32];
32'h10: read_data = {30'b0, mode};
default: read_data = repeat_counter;
endcase

always @(posedge clk_i)
begin
if (rst_i) read_data_o <= 32'b0;
else if (re) read_data_o <= read_data; 
else read_data_o <= read_data_o; 
end

assign interrupt_request_o = (mode != OFF) & ((system_counter_at_start + delay) == system_counter);

endmodule
