//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 23.07.2024 20:43:02
// Design Name: 
// Module Name: fulladder32
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


module fulladder32(
    input logic [31:0]  a_i,
    input logic [31:0]  b_i,
    input logic         carry_i,
    output logic [31:0] sum_o,
    output logic        carry_o
    );

logic [30:0] c_in;
full_adder sum_0(
            .a(a_i[0]),
            .b(b_i[0]),
            .c_in(carry_i),
            .res(sum_o[0]),
            .c_out(c_in[0]));
full_adder full_adder_array[29:0](
                    .a(a_i[30:1]),
                    .b(b_i[30:1]),
                    .c_in(c_in[29:0]),
                    .res(sum_o[30:1]),
                    .c_out(c_in[30:1])
                    );
full_adder sum_31(
            .a(a_i[31]),
            .b(b_i[31]),
            .c_in(c_in[30]),
            .res(sum_o[31]),
            .c_out(carry_o));                  
endmodule
