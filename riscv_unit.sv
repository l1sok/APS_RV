module riscv_unit( 
  input  logic        clk_i,
  input  logic        resetn_i,
                   
                   // Входы и выходы периферии
  input  logic [15:0] sw_i,       // Переключатели

  output logic [15:0] led_o,      // Светодиоды

  input  logic        kclk_i,     // Тактирующий сигнал клавиатуры
  input  logic        kdata_i,    // Сигнал данных клавиатуры

  output logic [ 6:0] hex_led_o,  // Вывод семисегментных индикаторов
  output logic [ 7:0] hex_sel_o,  // Селектор семисегментных индикаторов

  input  logic        rx_i,       // Линия приема по UART
  output logic        tx_o,       // Линия передачи по UART
  
  input  logic        sim_rx_i,       // Линия приема по UART
  output logic        sim_tx_o,       // Линия передачи по UART

  output logic [3:0]  vga_r_o,    // Красный канал vga
  output logic [3:0]  vga_g_o,    // Зеленый канал vga
  output logic [3:0]  vga_b_o,    // Синий канал vga
  output logic        vga_hs_o,   // Линия горизонтальной синхронизации vga
  output logic        vga_vs_o    // Линия вертикальной синхронизации vga
  );
      
logic sysclk, rst, core_rst;

sys_clk_rst_gen divider(.ex_clk_i(clk_i),
                        .ex_areset_n_i(resetn_i),
                        .div_i(5),
                        .sys_clk_o(sysclk), 
                        .sys_reset_o(rst));          
                   
 logic        stall_i;
 logic [31:0] instr_i;
 logic [31:0] mem_rd_i;
 logic [31:0] core_rd_o;
 logic [31:0] instr_addr_o;
 logic [31:0] mem_addr_o;
 logic [31:0] lsu_mem_addr_o; 
 logic [ 2:0] mem_size_o;
 logic        mem_req_o;
 logic        lsu_mem_req_o;
 logic        mem_we_o;
 logic        lsu_mem_we_o;
 logic [31:0] mem_wd_o ; 
 logic [31:0] lsu_mem_wd_o ; 
 logic [3:0]  byte_en;
 logic        mem_ready;
 logic [15:0] irq_req;
 logic [15:0] irq_ret;
 
 assign irq_req[15:3] = 13'b0;
 
logic [31:0] rw_instr_addr;
logic [31:0] rw_instr_data;
logic        rw_instr_we;
logic [31:0] rw_data_addr;
logic [31:0] rw_data_data;
logic        rw_data_we;
               
logic [ 8:0] req_out;
logic [31:0] mem_rd_main_data_o;
logic [31:0] mem_rd_sw_o;
logic [31:0] mem_rd_led_o;
logic [31:0] mem_rd_hex_o;
logic [31:0] mem_rd_rx;
logic [31:0] mem_rd_tx;
logic [31:0] mem_rd_timer;
logic [31:0] addr_periph;

logic periph_tx;
logic bluster_tx;

//assign tx_o = core_rst? bluster_tx : periph_tx;
 
logic        req;
logic        periph_we;
logic [3:0]  mem_be;
logic [31:0] periph_wd;
logic [31:0] periph_addr;

assign req         = core_rst? rw_data_we : lsu_mem_req_o; 
assign periph_we   = core_rst? rw_data_we : lsu_mem_we_o;
assign mem_be      = core_rst? 4'hF : byte_en;
assign periph_wd   = core_rst? rw_data_data : lsu_mem_wd_o;
assign periph_addr = core_rst? rw_data_addr : lsu_mem_addr_o;

assign addr_periph = {8'b0, periph_addr[23:0]};

rw_instr_mem instr_mem(.clk_i(sysclk),
                       .read_addr_i(instr_addr_o),   
                       .read_data_o(instr_i),     
                       .write_addr_i(rw_instr_addr),  
                       .write_data_i(rw_instr_data),  
                       .write_enable_i(rw_instr_we) );
                  
bluster bluster_prog(.clk_i(sysclk),
                     .rst_i(rst),
                     .rx_i(rx_i),
                     .tx_o(tx_o),
                     .instr_addr_o(rw_instr_addr),
                     .instr_wdata_o(rw_instr_data),  
                     .instr_we_o(rw_instr_we),                   
                     .data_addr_o(rw_data_addr),    
                     .data_wdata_o(rw_data_data),   
                     .data_we_o(rw_data_we), 
                     .core_reset_o(core_rst)); 
       
riscv_core core (
            .clk_i(sysclk),
            .rst_i(core_rst),
            .stall_i(stall_i),
            .instr_i(instr_i),
            .mem_rd_i(core_rd_o),
            .irq_req_i(irq_req),
            .instr_addr_o(instr_addr_o),
            .mem_addr_o(mem_addr_o),
            .mem_size_o(mem_size_o),
            .mem_req_o(mem_req_o),
            .mem_we_o(mem_we_o),
            .mem_wd_o(mem_wd_o),
            .irq_ret_o(irq_ret));    

riscv_lsu LSU(.clk_i(sysclk),
           .rst_i(rst),
           .core_req_i(mem_req_o),
           .core_we_i(mem_we_o),
           .core_size_i(mem_size_o),
           .core_addr_i(mem_addr_o),
           .core_wd_i(mem_wd_o),
           .core_rd_o(core_rd_o),
           .core_stall_o(stall_i),
           .mem_req_o(lsu_mem_req_o),
           .mem_we_o(lsu_mem_we_o),
           .mem_be_o(byte_en),
           .mem_addr_o(lsu_mem_addr_o),
           .mem_wd_o(lsu_mem_wd_o),
           .mem_rd_i(mem_rd_i),
           .mem_ready_i(mem_ready) );
           
logic [7:0] par;
assign par = periph_addr[31:24];

always_comb begin
case (par)
    8'h00:   req_out = 9'b000000001; 
    8'h01:   req_out = 9'b000000010; 
    8'h02:   req_out = 9'b000000100; 
    8'h04:   req_out = 9'b000010000; 
    8'h05:   req_out = 9'b000100000; 
    8'h06:   req_out = 9'b001000000; 
    default: req_out = 9'b100000000;
endcase
end
 
always_comb begin
case (par)
    8'h00:   mem_rd_i = mem_rd_main_data_o; 
    8'h01:   mem_rd_i = mem_rd_sw_o;        
    8'h02:   mem_rd_i = mem_rd_led_o;       
    8'h04:   mem_rd_i = mem_rd_hex_o;
    8'h05:   mem_rd_i = mem_rd_rx;
    8'h06:   mem_rd_i = mem_rd_tx;     
    default: mem_rd_i = mem_rd_timer;
endcase
end
data_mem main_data(.clk_i(sysclk),
          .mem_req_i(req & req_out[0]),
          .write_enable_i(periph_we),
          .byte_enable_i(mem_be),
          .addr_i(addr_periph),
          .write_data_i(lsu_mem_wd_o),
          .read_data_o(mem_rd_main_data_o),
          .ready_o(mem_ready));
          
hex_sb_ctrl hex_periph (.clk_i(sysclk),          
                        .rst_i(rst),          
                        .addr_i(addr_periph),         
                        .req_i(req & req_out[4]),          
                        .write_data_i(periph_wd),   
                        .write_enable_i(periph_we), 
                        .read_data_o(mem_rd_hex_o),    
                        .hex_led_o(hex_led_o), 
                        .hex_sel_o(hex_sel_o));          
 
 led_sb_ctrl led_periph (.clk_i(sysclk),          
                         .rst_i(rst),          
                         .addr_i(addr_periph),         
                         .req_i(req & req_out[2]),          
                         .write_data_i(periph_wd),   
                         .write_enable_i(periph_we), 
                         .read_data_o(mem_rd_led_o),       
                         .led_o(led_o));    
                                                        
 sw_sb_ctrl sw_periph   (.clk_i(sysclk),          
                         .rst_i(rst),          
                         .addr_i(addr_periph),         
                         .req_i(req & req_out[1]),          
                         .write_data_i(periph_wd),   
                         .write_enable_i(periph_we), 
                         .read_data_o(mem_rd_sw_o),   
                         .interrupt_request_o(irq_req[1]),  
                         .interrupt_return_i(irq_ret[1]),                        
                         .sw_i(sw_i));
                                        
uart_rx_sb_ctrl rx_uart_p (.clk_i(sysclk),           
                         .rst_i(rst),           
                         .addr_i(addr_periph),          
                         .req_i(req & req_out[5]),           
                         .write_data_i(periph_wd),    
                         .write_enable_i(periph_we),  
                         .read_data_o(mem_rd_rx),     
                         .interrupt_request_o(irq_req[0]),  
                         .interrupt_return_i(irq_ret[0]),   
                         .rx_i(sim_rx_i) );
                        
uart_tx_sb_ctrl tx_uart_p(.clk_i(sysclk),           
                         .rst_i(rst),             
                         .addr_i(addr_periph),          
                         .req_i(req & req_out[6]),           
                         .write_data_i(periph_wd),    
                         .write_enable_i(periph_we),  
                         .read_data_o(mem_rd_tx),
                         .tx_o(sim_tx_o) );
                         

timer_sb_ctrl timer_sys (.clk_i(sysclk),           
                         .rst_i(rst),           
                         .addr_i(addr_periph),          
                         .req_i(req & req_out[8]),           
                         .write_data_i(periph_wd),    
                         .write_enable_i(periph_we),  
                         .read_data_o(mem_rd_timer),     
                         .interrupt_request_o(irq_req[2])); 
                                                                  
endmodule
