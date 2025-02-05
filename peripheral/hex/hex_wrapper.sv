module hex_wrapper(
input logic  clk_i,
input logic [15:0] sw_i,
output logic [7:0] hex_sel_o,
output logic [6:0] hex_led_o
    );
    
    
                     
hex_sb_ctrl hx(
.clk_i(clk_i),          
.rst_i(sw_i[15]),          
.addr_i({26'b0, sw_i[13:8]}),         
.req_i(sw_i[14]),          
.write_data_i({24'b0, sw_i[7:0]}),   
.write_enable_i(1'b1),    
.hex_led_o(hex_led_o),
.hex_sel_o(hex_sel_o)
); 

endmodule
