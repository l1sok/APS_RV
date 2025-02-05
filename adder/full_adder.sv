//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 23.07.2024 20:13:11
// Design Name: 
// Module Name: full_adder
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module full_adder(
                    input logic a,
                    input logic b,
                    input logic c_in,
                    output logic res,
                    output logic c_out
    );
    assign res = a ^ b ^ c_in;
    assign c_out = (a & b) | (a & c_in) | (b & c_in);
endmodule
