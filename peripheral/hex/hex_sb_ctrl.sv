module hex_sb_ctrl(
/*
    ×àñòü èíòåðôåéñà ìîäóëÿ, îòâå÷àþùàÿ çà ïîäêëþ÷åíèå ê ñèñòåìíîé øèíå
*/
  input  logic        clk_i,
  input  logic        rst_i,
  input  logic [31:0] addr_i,
  input  logic        req_i,
  input  logic [31:0] write_data_i,
  input  logic        write_enable_i,
  output logic [31:0] read_data_o,
/*
    ×àñòü èíòåðôåéñà ìîäóëÿ, îòâå÷àþùàÿ çà ïîäêëþ÷åíèå ê ìîäóëþ,
    îñóùåñòâëÿþùåìó âûâîä öèôð íà ñåìèñåãìåíòíûå èíäèêàòîðû
*/
  output logic [6:0] hex_led_o,
  output logic [7:0] hex_sel_o
);
 
 logic [7:0] hex_sel;
 
logic write_req;
logic read_req;

assign write_req = write_enable_i & req_i;
assign read_req = ~write_enable_i & req_i;

  logic [3:0] hex0, hex1, hex2, hex3, hex4, hex5, hex6, hex7;
  logic [7:0] bitmask;
  
  logic  en_hex0, en_hex1, en_hex2, en_hex3, en_hex4, en_hex5, en_hex6, en_hex7;
  
  logic addr_hex0, addr_hex1, addr_hex2, addr_hex3, addr_hex4, addr_hex5, addr_hex6, addr_hex7;
  logic addr_bitmask;
  logic addr_reset;
 
assign addr_hex0 = addr_i == 32'h0;  
assign addr_hex1 = addr_i == 32'h4;  
assign addr_hex2 = addr_i == 32'h8;  
assign addr_hex3 = addr_i == 32'h0c;  
assign addr_hex4 = addr_i == 32'h10;  
assign addr_hex5 = addr_i == 32'h14;  
assign addr_hex6 = addr_i == 32'h18;  
assign addr_hex7 = addr_i == 32'h1C;  
assign addr_bitmask = addr_i == 32'h20;
assign addr_reset = addr_i == 32'h24;

logic hex_data_valid;
logic bitmask_valid;
logic rst_valid;

assign hex_data_valid = write_data_i < 32'h10; 
assign bitmask_valid = write_data_i < 32'h100;
assign rst_valid = write_data_i == 32'h1;

logic en_rst;
logic rst; 

assign en_rst = rst_valid & addr_reset & write_req;
assign rst = rst_i | en_rst;

assign en_hex0 = hex_data_valid & addr_hex0 & write_req;
assign en_hex1 = hex_data_valid & addr_hex1 & write_req;
assign en_hex2 = hex_data_valid & addr_hex2 & write_req;
assign en_hex3 = hex_data_valid & addr_hex3 & write_req;
assign en_hex4 = hex_data_valid & addr_hex4 & write_req;
assign en_hex5 = hex_data_valid & addr_hex5 & write_req;
assign en_hex6 = hex_data_valid & addr_hex6 & write_req;
assign en_hex7 = hex_data_valid & addr_hex7 & write_req;

assign en_bitmask = bitmask_valid & addr_bitmask & write_req;

always_ff @(posedge clk_i)
begin
    if (rst) hex0 <= 4'b0; else if (en_hex0) hex0 <= write_data_i[3:0];
    if (rst) hex1 <= 4'b0; else if (en_hex1) hex1 <= write_data_i[3:0];
    if (rst) hex2 <= 4'b0; else if (en_hex2) hex2 <= write_data_i[3:0];
    if (rst) hex3 <= 4'b0; else if (en_hex3) hex3 <= write_data_i[3:0];
    if (rst) hex4 <= 4'b0; else if (en_hex4) hex4 <= write_data_i[3:0];
    if (rst) hex5 <= 4'b0; else if (en_hex5) hex5 <= write_data_i[3:0];
    if (rst) hex6 <= 4'b0; else if (en_hex6) hex6 <= write_data_i[3:0];
    if (rst) hex7 <= 4'b0; else if (en_hex7) hex7 <= write_data_i[3:0]; 
    if (rst) bitmask <= 8'b0; else if (en_bitmask)   bitmask <= write_data_i[7:0];
end

logic rd;
logic [7:0] data_addr;
assign data_addr = {addr_hex0, addr_hex1, addr_hex2, addr_hex3, addr_hex4, addr_hex5, addr_hex6, addr_hex7};

always_comb begin
case (data_addr)
8'b10000000: rd = {28'b0, hex0};
8'b01000000: rd = {28'b0, hex1};
8'b00100000: rd = {28'b0, hex2};
8'b00010000: rd = {28'b0, hex3};
8'b00001000: rd = {28'b0, hex4};
8'b00000100: rd = {28'b0, hex5};
8'b00000010: rd = {28'b0, hex6};
8'b00000001: rd = {28'b0, hex7};  
default: rd = {24'b0, bitmask};         
endcase
end 

logic rd_en;
assign rd_en = (addr_hex0 | addr_hex1 | addr_hex2 | addr_hex3 | addr_hex4 | addr_hex5 | addr_hex6 | addr_hex7 | addr_bitmask) & read_req;

always_ff @(posedge clk_i)
if (rd_en)
    read_data_o <= rd & ~rst;
        
hex_digits hex_module(
.clk_i(clk_i),    
.rst_i(rst_i),    
.hex0_i(hex0),   
.hex1_i(hex1),   
.hex2_i(hex2),   
.hex3_i(hex3),   
.hex4_i(hex4),   
.hex5_i(hex5),   
.hex6_i(hex6),   
.hex7_i(hex7),   
.bitmask_i(bitmask),
.hex_led_o(hex_led_o),
.hex_sel_o(hex_sel)
);

assign hex_sel_o = ~hex_sel;

endmodule
