module bluster
(
  input   logic clk_i,
  input   logic rst_i,

  input   logic rx_i,
  output  logic tx_o,

  output logic [ 31:0] instr_addr_o,
  output logic [ 31:0] instr_wdata_o,
  output logic         instr_we_o,

  output logic [ 31:0] data_addr_o,
  output logic [ 31:0] data_wdata_o,
  output logic         data_we_o,

  output logic core_reset_o
);

import memory_pkg::INSTR_MEM_SIZE_BYTES;
import bluster_pkg::INIT_MSG_SIZE;
import bluster_pkg::FLASH_MSG_SIZE;
import bluster_pkg::ACK_MSG_SIZE;

enum logic [2:0] {
  RCV_NEXT_COMMAND,
  INIT_MSG,
  RCV_SIZE,
  SIZE_ACK,
  FLASH,
  FLASH_ACK,
  FINISH}
state, next_state;

logic rx_busy, rx_valid, tx_busy, tx_valid;
logic [7:0] rx_data, tx_data;

logic [5:0] msg_counter;
logic [31:0] size_counter, flash_counter;
logic [3:0] [7:0] flash_size, flash_addr;

logic send_fin, size_fin, flash_fin, next_round;

assign send_fin   = (msg_counter    ==  0)  && !tx_busy;
assign size_fin   = (size_counter   ==  0)  && !rx_busy;
assign flash_fin  = (flash_counter  ==  0)  && !rx_busy;
assign next_round = (flash_addr     != '1)  && !rx_busy;

logic [7:0] [7:0] flash_size_ascii, flash_addr_ascii;

genvar i;
generate
  for(i=0; i < 4; i=i+1) begin
    
    assign flash_size_ascii[i*2]    = flash_size[i][3:0] < 4'ha ? flash_size[i][3:0] + 8'h30 :
                                                                  flash_size[i][3:0] + 8'h57;
    assign flash_size_ascii[i*2+1]  = flash_size[i][7:4] < 4'ha ? flash_size[i][7:4] + 8'h30 :
                                                                  flash_size[i][7:4] + 8'h57;

    assign flash_addr_ascii[i*2]    = flash_addr[i][3:0] < 4'ha ? flash_addr[i][3:0] + 8'h30 :
                                                                  flash_addr[i][3:0] + 8'h57;
    assign flash_addr_ascii[i*2+1]  = flash_addr[i][7:4] < 4'ha ? flash_addr[i][7:4] + 8'h30 :
                                                                  flash_addr[i][7:4] + 8'h57;
  end
endgenerate

logic [INIT_MSG_SIZE-1:0][7:0] init_msg;
// ascii-êîä ñòðîêè "ready for flash starting from 0xflash_addr\n"
assign init_msg = { 8'h72, 8'h65, 8'h61, 8'h64, 8'h79, 8'h20, 8'h66, 8'h6F,
                    8'h72, 8'h20, 8'h66, 8'h6C, 8'h61, 8'h73, 8'h68, 8'h20,
                    8'h73, 8'h74, 8'h61, 8'h72, 8'h74, 8'h69, 8'h6E, 8'h67,
                    8'h20, 8'h66, 8'h72, 8'h6F, 8'h6D, 8'h20, 8'h30, 8'h78,
                    flash_addr_ascii, 8'h0a};

logic [FLASH_MSG_SIZE-1:0][7:0] flash_msg;
//ascii-êîä ñòðîêè: "finished write 0xflash_size bytes starting from 0xflash_addr\n"
assign flash_msg = {8'h66, 8'h69, 8'h6E, 8'h69, 8'h73, 8'h68, 8'h65, 8'h64,
                    8'h20, 8'h77, 8'h72, 8'h69, 8'h74, 8'h65, 8'h20, 8'h30,
                    8'h78,      flash_size_ascii,      8'h20, 8'h62, 8'h79,
                    8'h74, 8'h65, 8'h73, 8'h20, 8'h73, 8'h74, 8'h61, 8'h72,
                    8'h74, 8'h69, 8'h6E, 8'h67, 8'h20, 8'h66, 8'h72, 8'h6F,
                    8'h6D, 8'h20, 8'h30, 8'h78,     flash_addr_ascii,
                    8'h0a};

always_ff @(posedge clk_i)
if (rst_i) state <= RCV_NEXT_COMMAND;
else       state <= next_state;

always_ff @(posedge clk_i) 
begin
if (rst_i)  size_counter <= 32'd4;
else  if (state == RCV_SIZE | state == RCV_NEXT_COMMAND)   
           if (rx_valid) size_counter <= size_counter - 32'b1;
           else          size_counter <= size_counter;
      else  size_counter <= 32'd4;
end

always_ff @(posedge clk_i)
begin
if (rst_i)  flash_counter <= flash_size;
else  if (state == FLASH)   if (rx_valid) flash_counter <= flash_counter - 32'b1;
                            else          flash_counter <= flash_counter;
      else  flash_counter <= flash_size;
end

always_ff @(posedge clk_i)
begin
if (rst_i)  msg_counter <= INIT_MSG_SIZE-1;
else if (state == FLASH)               msg_counter <= FLASH_MSG_SIZE-1;
else if (state == RCV_SIZE)            msg_counter <= ACK_MSG_SIZE-1;
else if (state == RCV_NEXT_COMMAND)    msg_counter <= INIT_MSG_SIZE-1;
else if (state == FLASH_ACK | state == INIT_MSG | state == SIZE_ACK)
     if (tx_valid) msg_counter <= msg_counter - 6'b1;
     else          msg_counter <= msg_counter;
else                                   msg_counter <= msg_counter;
end

always_comb 
begin
case (state)
    RCV_NEXT_COMMAND: 
    begin
        if (size_fin) next_state = next_round? INIT_MSG : FINISH;
        else          next_state = state; 
    end
    INIT_MSG:         next_state = send_fin? RCV_SIZE : state;
    RCV_SIZE:         next_state = size_fin? SIZE_ACK : state;
    SIZE_ACK:         next_state = send_fin? FLASH : state;
    FLASH:            next_state = flash_fin? FLASH_ACK : state;
    FLASH_ACK:        next_state = send_fin? RCV_NEXT_COMMAND : state; 
    default:          next_state = state;
endcase
end

assign tx_valid = (state == FLASH_ACK | state == INIT_MSG | state == SIZE_ACK) & ~tx_busy;

always_comb 
begin
case (state)
    INIT_MSG:  tx_data = init_msg[msg_counter];
    SIZE_ACK:  tx_data = flash_size[msg_counter];
    FLASH_ACK: tx_data = flash_msg[msg_counter];
    default:   tx_data = 8'b0;
endcase
end

always_ff @(posedge clk_i)
begin
if (rst_i) begin instr_addr_o <= 32'b0; instr_wdata_o <= 32'b0; instr_we_o = 1'b0;  end
else if ((state == FLASH) & (flash_addr < INSTR_MEM_SIZE_BYTES) & rx_valid)
        begin 
        instr_wdata_o <= {instr_wdata_o[23:0], rx_data};
        instr_we_o    <= flash_counter[1:0] == 2'b01;
        instr_addr_o  <= flash_addr + flash_counter - 1;
        end
     else
        begin 
        instr_wdata_o <= instr_wdata_o;
        instr_we_o    <= 1'b0;
        instr_addr_o  <= instr_addr_o;
        end     
end

always_ff @(posedge clk_i)
begin
if (rst_i) begin data_addr_o <= 32'b0; data_wdata_o <= 32'b0; data_we_o = 1'b0;  end
else if ((state == FLASH) & (flash_addr >= INSTR_MEM_SIZE_BYTES) & rx_valid)
        begin 
        data_wdata_o <= {data_wdata_o[23:0], rx_data};
        data_we_o    <= flash_counter[1:0] == 2'b01;
        data_addr_o  <= flash_addr + flash_counter - 1;
        end
     else
        begin 
        data_wdata_o <= data_wdata_o;
        data_we_o    <= 1'b0;
        data_addr_o  <= data_addr_o;
        end     
end

always_ff @(posedge clk_i)
begin
if (rst_i)                              flash_size <= '0;
else if (state == RCV_SIZE && rx_valid) flash_size <= {flash_size[2:0], rx_data};
     else                               flash_size <= flash_size;
end

always_ff @(posedge clk_i)
begin
if (rst_i)                                      flash_addr <= '0;
else if (state == RCV_NEXT_COMMAND && rx_valid) flash_addr <= {flash_addr[2:0], rx_data};
     else                                       flash_addr <= flash_addr;
end

assign core_reset_o = (state == FINISH)? 1'b0 : 1'b1;

uart_rx rx(
  .clk_i      (clk_i      ),
  .rst_i      (rst_i      ),
  .rx_i       (rx_i       ),
  .busy_o     (rx_busy    ),
  .baudrate_i (17'd115200 ),
  .parity_en_i(1'b1       ),
  .stopbit_i  (2'b1       ),
  .rx_data_o  (rx_data    ),
  .rx_valid_o (rx_valid   )
);

uart_tx tx(
  .clk_i      (clk_i      ),
  .rst_i      (rst_i      ),
  .tx_o       (tx_o       ),
  .busy_o     (tx_busy    ),
  .baudrate_i (17'd115200 ),
  .parity_en_i(1'b1       ),
  .stopbit_i  (2'b1       ),
  .tx_data_i  (tx_data    ),
  .tx_valid_i (tx_valid   )
);


endmodule
