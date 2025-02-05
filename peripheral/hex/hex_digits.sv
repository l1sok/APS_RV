module hex_digits(
  input  logic       clk_i,
  input  logic       rst_i,
  input  logic [3:0] hex0_i,    // Öèôðà, âûâîäèìîé íà íóëåâîé (ñàìûé ïðàâûé) èíäèêàòîð
  input  logic [3:0] hex1_i,    // Öèôðà, âûâîäèìàÿ íà ïåðâûé èíäèêàòîð
  input  logic [3:0] hex2_i,    // Öèôðà, âûâîäèìàÿ íà âòîðîé èíäèêàòîð
  input  logic [3:0] hex3_i,    // Öèôðà, âûâîäèìàÿ íà òðåòèé èíäèêàòîð
  input  logic [3:0] hex4_i,    // Öèôðà, âûâîäèìàÿ íà ÷åòâåðòûé èíäèêàòîð
  input  logic [3:0] hex5_i,    // Öèôðà, âûâîäèìàÿ íà ïÿòûé èíäèêàòîð
  input  logic [3:0] hex6_i,    // Öèôðà, âûâîäèìàÿ íà øåñòîé èíäèêàòîð
  input  logic [3:0] hex7_i,    // Öèôðà, âûâîäèìàÿ íà ñåäüìîé èíäèêàòîð
  input  logic [7:0] bitmask_i, // Áèòîâàÿ ìàñêà äëÿ âêëþ÷åíèÿ/îòêëþ÷åíèÿ
                                // îòäåëüíûõ èíäèêàòîðîâ

  output logic [6:0] hex_led_o, // Ñèãíàë, êîíòðîëèðóþùèé êàæäûé îòäåëüíûé
                                // ñâåòîäèîä èíäèêàòîðà
  output logic [7:0] hex_sel_o  // Ñèãíàë, óêàçûâàþùèé íà êàêîé èíäèêàòîð
                                // âûñòàâëÿåòñÿ hex_led
    );

logic [3:0] hex_sel_led;
logic [7:0] hex_sel;
logic [2:0]  cnt_an_on;

localparam CNT_480Hz_MAX_VAL = 18'd20_333;

    logic         en_480Hz;
    logic [17:0] cnt_480Hz;
    
always_ff @(posedge clk_i) 
    if (rst_i)
        cnt_480Hz <= 18'b0;
    else begin 
        if (cnt_480Hz < CNT_480Hz_MAX_VAL - 18'd1)
            cnt_480Hz <= cnt_480Hz + 18'd1;
        else
            cnt_480Hz <= 18'b0;
    end

 always_ff @(posedge clk_i) begin 
    if (rst_i)
        cnt_an_on <= 3'd0;
    else if (en_480Hz) begin
        cnt_an_on <= cnt_an_on + 3'd1;
        end
end
    
    
always_comb en_480Hz = cnt_480Hz == (CNT_480Hz_MAX_VAL - 18'd1);


always_comb begin
case (cnt_an_on)
3'd0: begin hex_sel_led = hex0_i;  hex_sel_o = 8'b00000001 & bitmask_i; end
3'd1: begin hex_sel_led = hex1_i;  hex_sel_o = 8'b00000010 & bitmask_i; end
8'd2: begin hex_sel_led = hex2_i;  hex_sel_o = 8'b00000100 & bitmask_i; end
8'd3: begin hex_sel_led = hex3_i;  hex_sel_o = 8'b00001000 & bitmask_i; end
8'd4: begin hex_sel_led = hex4_i;  hex_sel_o = 8'b00010000 & bitmask_i; end
8'd5: begin hex_sel_led = hex5_i;  hex_sel_o = 8'b00100000 & bitmask_i; end
8'd6: begin hex_sel_led = hex6_i;  hex_sel_o = 8'b01000000 & bitmask_i; end
default: begin hex_sel_led = hex7_i;  hex_sel_o = 8'b10000000 & bitmask_i; end
endcase
end

always_comb begin
    case (hex_sel_led)
        4'b0000: hex_led_o[6:0] = 7'b1000000;
        4'b0001: hex_led_o[6:0] = 7'b1111001;
        4'b0010: hex_led_o[6:0] = 7'b0100100;
        4'b0011: hex_led_o[6:0] = 7'b0110000;
        4'b0100: hex_led_o[6:0] = 7'b0011001;
        4'b0101: hex_led_o[6:0] = 7'b0010010;
        4'b0110: hex_led_o[6:0] = 7'b0000010;
        4'b0111: hex_led_o[6:0] = 7'b1111000;
        4'b1000: hex_led_o[6:0] = 7'b0000000;
        4'b1001: hex_led_o[6:0] = 7'b0010000;
        4'b1010: hex_led_o[6:0] = 7'b0001000;
        4'b1011: hex_led_o[6:0] = 7'b0000011;
        4'b1100: hex_led_o[6:0] = 7'b1000110;
        4'b1101: hex_led_o[6:0] = 7'b0100001;
        4'b1110: hex_led_o[6:0] = 7'b0000110;
        default: hex_led_o[6:0] = 7'b0001110;
    endcase       
end


endmodule
