module decoder_riscv (
  input  logic [31:0]  fetched_instr_i,
  output logic [1:0]   a_sel_o,
  output logic [2:0]   b_sel_o,
  output logic [4:0]   alu_op_o,
  output logic [2:0]   csr_op_o,
  output logic         csr_we_o,
  output logic         mem_req_o,
  output logic         mem_we_o,
  output logic [2:0]   mem_size_o,
  output logic         gpr_we_o,
  output logic [1:0]   wb_sel_o,
  output logic         illegal_instr_o,
  output logic         branch_o,
  output logic         jal_o,
  output logic         jalr_o,
  output logic         mret_o
);
import decoder_pkg::*;

logic JALR;
logic JAL;
logic NOP;
logic UI;
logic uiPC;
logic BRANCH;
logic [1:0] SYSTEM;
logic LOAD;
logic STORE;
logic RR;
logic RI;
logic shift_i;
always_comb
case (fetched_instr_i[6:2])
LOAD_OPCODE:
    begin
             LOAD = ((&fetched_instr_i[14:13])|(&fetched_instr_i[13:12]))? 1'b0 : 1'b1; JALR = 1'b0;  RR = 1'b0; RI = 1'b0;
             NOP = 1'b0; BRANCH = 1'b0; SYSTEM = 2'b0;  STORE  = 1'b0;   UI = 1'b0; uiPC = 1'b0; JAL = 1'b0; shift_i = 1'b0;  
    end
    
STORE_OPCODE:    
            begin
            STORE = (fetched_instr_i[14]|&fetched_instr_i[13:12])? 1'b0: 1'b1; JALR = 1'b0; JAL = 1'b0; shift_i = 1'b0; NOP = 1'b0; BRANCH = 1'b0; 
            SYSTEM = 2'b0; LOAD = 1'b0; RR = 1'b0; RI = 1'b0; UI = 1'b0; uiPC = 1'b0;
            end
MISC_MEM_OPCODE:  
       begin
            NOP = (|fetched_instr_i[14:12])? 1'b0: 1'b1 ; JALR = 1'b0; JAL = 1'b0; shift_i = 1'b0; BRANCH = 1'b0; SYSTEM = 2'b0;
            LOAD = 1'b0; STORE  = 1'b0;  RR = 1'b0; RI = 1'b0; UI = 1'b0; uiPC = 1'b0;
       end
OP_IMM_OPCODE:
    case (fetched_instr_i[14:12])
        3'b001: 
            case (fetched_instr_i[31:25])
                   7'b0: begin   shift_i = 1'b0; RI=1'b1; JALR = 1'b0; JAL = 1'b0; NOP = 1'b0; BRANCH = 1'b0;
                    SYSTEM = 2'b0; LOAD = 1'b0; STORE  = 1'b0;  RR = 1'b0; UI = 1'b0; uiPC = 1'b0;
                   end  
                   default: begin
                        JALR = 1'b0; JAL = 1'b0; shift_i = 1'b0; NOP = 1'b0; BRANCH = 1'b0; SYSTEM = 2'b0; 
                        LOAD = 1'b0; STORE  = 1'b0;  RR = 1'b0; RI = 1'b0; UI = 1'b0; uiPC = 1'b0;
                   end
            endcase
        3'b101:
            case (fetched_instr_i[31:25])
                   7'b0, 7'b0100000: begin shift_i = 1'b1; RI = 1'b1;
                   JALR = 1'b0; JAL = 1'b0; NOP = 1'b0; BRANCH = 1'b0; SYSTEM = 2'b0; LOAD = 1'b0; STORE  = 1'b0;  RR = 1'b0; UI = 1'b0; uiPC = 1'b0;
                   end        
                   default: begin
                        JALR = 1'b0; JAL = 1'b0; shift_i = 1'b0; NOP = 1'b0; BRANCH = 1'b0; SYSTEM = 2'b0; 
                        LOAD = 1'b0; STORE  = 1'b0;  RR = 1'b0; RI = 1'b0; UI = 1'b0; uiPC = 1'b0;
                   end
            endcase
        default: begin shift_i = 1'b0; RI = 1'b1;
        JALR = 1'b0; JAL = 1'b0; NOP = 1'b0; BRANCH = 1'b0; SYSTEM = 2'b0; LOAD = 1'b0; STORE  = 1'b0;  RR = 1'b0; UI = 1'b0; uiPC = 1'b0;
        end
    endcase
AUIPC_OPCODE: 
    begin
    uiPC = 1'b1; JALR = 1'b0; JAL = 1'b0; shift_i = 1'b0; NOP = 1'b0; BRANCH = 1'b0;
    SYSTEM = 2'b0; LOAD = 1'b0; STORE  = 1'b0;  RR = 1'b0; RI = 1'b0; UI = 1'b0; 
    end
OP_OPCODE:
    case (fetched_instr_i[31:25])
        7'b0: begin RR = 1'b1;
        JALR = 1'b0; JAL = 1'b0; shift_i = 1'b0; NOP = 1'b0; BRANCH = 1'b0; 
        SYSTEM = 2'b0; LOAD = 1'b0; STORE  = 1'b0; RI = 1'b0; UI = 1'b0; uiPC = 1'b0;
        end       
        7'b0100000: 
        case(fetched_instr_i[14:12])
            3'b000, 3'b101: begin RR = 1'b1; 
            JALR = 1'b0; JAL = 1'b0; shift_i = 1'b0; NOP = 1'b0; BRANCH = 1'b0; 
            SYSTEM = 2'b0; LOAD = 1'b0; STORE  = 1'b0; RI = 1'b0; UI = 1'b0; uiPC = 1'b0;
            end  
            default: 
                   begin
                        JALR = 1'b0; JAL = 1'b0; shift_i = 1'b0; NOP = 1'b0; BRANCH = 1'b0; SYSTEM = 2'b0; 
                        LOAD = 1'b0; STORE  = 1'b0;  RR = 1'b0; RI = 1'b0; UI = 1'b0; uiPC = 1'b0;
                   end
        endcase
    default:       begin
                        JALR = 1'b0; JAL = 1'b0; shift_i = 1'b0; NOP = 1'b0; BRANCH = 1'b0; SYSTEM = 2'b0; 
                        LOAD = 1'b0; STORE  = 1'b0;  RR = 1'b0; RI = 1'b0; UI = 1'b0; uiPC = 1'b0;
                   end
    endcase
LUI_OPCODE:    begin  
    UI = 1'b1; JALR = 1'b0; JAL = 1'b0; shift_i = 1'b0; NOP = 1'b0; BRANCH = 1'b0;
    SYSTEM = 2'b0; LOAD = 1'b0; STORE  = 1'b0;  RR = 1'b0; RI = 1'b0; uiPC = 1'b0;
    end 
BRANCH_OPCODE: 
    begin
        BRANCH = (~fetched_instr_i[14]&fetched_instr_i[13])? 1'b0: 1'b1;  shift_i = 1'b0; NOP = 1'b0; SYSTEM = 2'b0;
        LOAD = 1'b0; STORE  = 1'b0;  RR = 1'b0; RI = 1'b0; UI = 1'b0; uiPC = 1'b0; JALR = 1'b0; JAL = 1'b0;
    end
JALR_OPCODE:
 begin
        JALR = (|fetched_instr_i[14:12])?1'b0 : 1'b1; JAL = 1'b0; shift_i = 1'b0; NOP = 1'b0; BRANCH = 1'b0; SYSTEM = 2'b0;
        LOAD = 1'b0; STORE  = 1'b0;  RR = 1'b0; RI = 1'b0; UI = 1'b0; uiPC = 1'b0;
 end
JAL_OPCODE:    
    begin
    JAL = 1'b1; JALR = 1'b0; shift_i = 1'b0; NOP = 1'b0; BRANCH = 1'b0; SYSTEM = 2'b0;
    LOAD = 1'b0; STORE  = 1'b0;  RR = 1'b0; RI = 1'b0; UI = 1'b0; uiPC = 1'b0;
    end
SYSTEM_OPCODE: 
    case (fetched_instr_i[14:12])
        3'b100: 
                begin
                     JALR = 1'b0; JAL = 1'b0; shift_i = 1'b0; NOP = 1'b0; BRANCH = 1'b0; SYSTEM = 2'b0;
                     LOAD = 1'b0; STORE  = 1'b0;  RR = 1'b0; RI = 1'b0; UI = 1'b0; uiPC = 1'b0; 
                      
                end
        3'b000: 
        case(fetched_instr_i[31:7])
            25'b10000000000000, 25'b0: 
            begin
                 JALR = 1'b0; JAL = 1'b0; shift_i = 1'b1; NOP = 1'b0; BRANCH = 1'b0; SYSTEM = 2'b01;
                 LOAD = 1'b0; STORE  = 1'b0;  RR = 1'b0; RI = 1'b0; UI = 1'b0; uiPC = 1'b0; 
            end
            25'b0011000000100000000000000: 
            begin
                 JALR = 1'b0; JAL = 1'b0; shift_i = 1'b0; NOP = 1'b0; BRANCH = 1'b0; SYSTEM = 2'b10;
                 LOAD = 1'b0; STORE  = 1'b0;  RR = 1'b0; RI = 1'b0; UI = 1'b0; uiPC = 1'b0;
            end 
            default: 
            begin 
                 JALR = 1'b0; JAL = 1'b0; shift_i = 1'b0; NOP = 1'b0; BRANCH = 1'b0; SYSTEM = 2'b0;
                  LOAD = 1'b0; STORE  = 1'b0;  RR = 1'b0; RI = 1'b0; UI = 1'b0; uiPC = 1'b0;
             end
        endcase
        default:
        begin
            SYSTEM = 2'b11; JALR = 1'b0; JAL = 1'b0; shift_i = 1'b0; NOP = 1'b0; BRANCH = 1'b0;
            LOAD = 1'b0; STORE  = 1'b0;  RR = 1'b0; RI = 1'b0; UI = 1'b0; uiPC = 1'b0;
        end
    endcase
default: 
    begin 
        JALR = 1'b0; JAL = 1'b0; shift_i = 1'b0; NOP = 1'b0; BRANCH = 1'b0; SYSTEM = 2'b0;
        LOAD = 1'b0; STORE  = 1'b0;  RR = 1'b0; RI = 1'b0; UI = 1'b0; uiPC = 1'b0; 
    end
endcase

assign illegal_instr_o = ~(JALR|JAL|NOP|BRANCH|SYSTEM[1]|LOAD|STORE|RR|RI|UI|uiPC)|(~(&fetched_instr_i[1:0]))|(SYSTEM[0]&shift_i);
assign mret_o   = SYSTEM[1]&(~SYSTEM[0]);
assign wb_sel_o = SYSTEM[1]? WB_CSR_DATA : (LOAD? WB_LSU_DATA : WB_EX_RESULT);
assign a_sel_o  = (JAL|JALR|uiPC)?(OP_A_CURR_PC):((UI|NOP? OP_A_ZERO:OP_A_RS1)); 
assign b_sel_o  = (JAL|JALR)?OP_B_INCR:((UI|uiPC)? OP_B_IMM_U :((RR|BRANCH)? OP_B_RS2 : (STORE? OP_B_IMM_S: OP_B_IMM_I)) );

assign alu_op_o = (RR)? {fetched_instr_i[31:30],fetched_instr_i[14:12]} : (RI?(shift_i? {fetched_instr_i[31:30], fetched_instr_i[14:12]}:{2'b0, fetched_instr_i[14:12]}) : (BRANCH? {2'b11, fetched_instr_i[14:12]} : ALU_ADD));

assign gpr_we_o   = ((!illegal_instr_o)&((&SYSTEM) |JAL|JALR|LOAD|RI|RR|UI|uiPC))? 1'b1: 1'b0;

assign csr_we_o   = (&SYSTEM) &(!illegal_instr_o)? 1'b1 : 1'b0;
assign csr_op_o   = (&SYSTEM)&(!illegal_instr_o)? fetched_instr_i[14:12] : 3'b0;

assign jal_o      = JAL &(!illegal_instr_o)? 1'b1 : 1'b0 ;
assign jalr_o     = JALR &(!illegal_instr_o)? 1'b1 : 1'b0;
assign branch_o   = BRANCH &(!illegal_instr_o)? 1'b1 : 1'b0;

assign mem_req_o  = (LOAD|STORE)&(!illegal_instr_o)? 1'b1 : 1'b0;
assign mem_size_o = (LOAD|STORE)&(!illegal_instr_o)? fetched_instr_i[14:12] : 3'b0;
assign mem_we_o   = STORE&(!illegal_instr_o)? 1'b1 : 1'b0;

endmodule
