module uart_tx_sb_ctrl(
/*
    Часть интерфейса модуля, отвечающая за подключение к системной шине
*/
  input  logic          clk_i,
  input  logic          rst_i,
  input  logic [31:0]   addr_i,
  input  logic          req_i,
  input  logic [31:0]   write_data_i,
  input  logic          write_enable_i,
  output logic [31:0]   read_data_o,

/*
    Часть интерфейса модуля, отвечающая за подключение передающему,
    выходные данные по UART
*/
  output logic          tx_o
);

  logic busy;
  logic busy_o;
  logic [16:0] baudrate;
  logic parity_en;
  logic [1:0] stopbit;
  logic [7:0]  data; 
  logic tx_valid;

  logic is_rst_addr;
  logic is_baudrate_addr;
  logic is_busy_addr;
  logic is_pe_addr;
  logic is_stopbit_addr;
  logic is_data_addr;
  logic val_addr;
  logic val_baudrate;
  logic val_pe;
  logic val_stopbit;  
  logic val_data;
  
  assign  val_addr = is_baudrate_addr | is_busy_addr | is_pe_addr |is_data_addr | is_stopbit_addr;
  assign  val_baudrate = write_data_i < 32'd131072;
  assign  val_pe = write_data_i < 32'b10;
  assign  val_data = write_data_i < 32'd256;
  assign  val_stopbit = (write_data_i < 32'b11) & (|write_data_i[1:0]);
  
  logic [31:0] read_data;
  logic rst;
  logic we;
  
  assign we = ~busy & req_i & write_enable_i;
  assign rst = (req_i & write_enable_i & is_rst_addr & (write_data_i == 32'h1))|rst_i;
  
  assign is_rst_addr      = addr_i == 32'h24;     
  assign is_baudrate_addr = addr_i == 32'h0C;
  assign is_busy_addr     = addr_i == 32'h08;    
  assign is_pe_addr       = addr_i == 32'h10;      
  assign is_stopbit_addr  = addr_i == 32'h14; 
  assign is_data_addr     = addr_i == 32'h0;    
  
  always_ff @(posedge clk_i)
  begin
  if (rst) busy <=1'b0;
  else  busy <= busy_o;
  end  
  
  always_ff @(posedge clk_i)
  begin
  if (rst)                                       baudrate <= 17'd9600;
  else if (we & is_baudrate_addr & val_baudrate) baudrate <= write_data_i[16:0];
  else                                           baudrate <= baudrate;
  end 
  
  always_ff @(posedge clk_i)
  begin
  if (rst)                           parity_en <= 1'b0; 
  else if (we & is_pe_addr & val_pe) parity_en <= write_data_i[0];
  else                               parity_en <= parity_en; 
  end
        
  always_ff @(posedge clk_i)
  begin
  if (rst)                                     stopbit <= 2'b1; 
  else if (we & is_stopbit_addr & val_stopbit) stopbit <= write_data_i[1:0];
  else                                         stopbit <= stopbit;
  end      
         
  always_ff @(posedge clk_i)
  begin
  if (rst)                               begin tx_valid <= 1'b0; data <= 8'b0;  end
  else if (we & is_data_addr)            begin tx_valid <= 1'b1; data <= write_data_i[7:0]; end
  else                                   begin tx_valid <= 1'b0; data <= data; end 
  end    
  
  always_comb
  case (addr_i)
  32'h0:   read_data = {24'b0, data};
  32'h08:  read_data = {31'b0, busy}; 
  32'h0C:  read_data = {15'b0, baudrate};
  32'h10:  read_data = {31'b0, parity_en};
  default: read_data = {31'b0, stopbit};
  endcase
  
  always_ff @(posedge clk_i)
  begin
  if (rst)                                      read_data_o <= 32'b0;
  else if (req_i & ~write_enable_i & val_addr)  read_data_o <= read_data;
  else read_data_o <= read_data_o;
  end     
         
                     
uart_tx uart_tx ( .clk_i(clk_i),      
                  .rst_i(rst),      
                  .tx_o(tx_o),       
                  .busy_o(busy_o),     
                  .baudrate_i(baudrate), 
                  .parity_en_i(parity_en),
                  .stopbit_i(stopbit),  
                  .tx_data_i(data),  
                  .tx_valid_i(tx_valid));
endmodule