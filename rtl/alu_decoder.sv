// alu_decoder.sv
// Second-level ("ALU") decoder. Turns the 2-bit ALUOp (from the Main Decoder)
// plus funct3/funct7/opcode into the 4-bit ALUControl code the ALU understands.
// ALUControl values come from riscv_pkg::alu_op_t (single source of truth).
import riscv_pkg::*;

module ALU_Decoder (
    input  logic [1:0] ALUOp,
    input  logic [2:0] funct3,
    input  logic [6:0] funct7,
    input  logic [6:0] op,
    output logic [3:0] ALUControl
);

    always_comb begin
        case (ALUOp)
            // 00 : lw / sw / addi -> add (address calc or plain add)
            2'b00: ALUControl = ALU_ADD;

            // 01 : branch (beq/bne) -> subtract, so the Zero flag reports equality
            2'b01: ALUControl = ALU_SUB;

            // 10 : R-type now (I-type ALU too, after step 3) -> funct3 picks the op
            2'b10: begin
                case (funct3)
                    // add vs sub: only a *real* R-type sub (op[5]=1 & funct7[5]=1)
                    // becomes SUB. addi (op[5]=0) always stays ADD, even if its
                    // immediate happens to set funct7[5].
                    3'b000: ALUControl = ({op[5], funct7[5]} == 2'b11) ? ALU_SUB
                                                                        : ALU_ADD;
                    3'b001: ALUControl = ALU_SLL;                        // sll / slli
                    3'b010: ALUControl = ALU_SLT;                        // slt / slti
                    3'b100: ALUControl = ALU_XOR;                        // xor / xori
                    // srl vs sra: funct7[5] selects arithmetic. This works for BOTH
                    // R-type and I-type shifts (srli/srai use funct7 as the selector),
                    // so it is NOT gated on op[5] the way add/sub is.
                    3'b101: ALUControl = funct7[5] ? ALU_SRA : ALU_SRL;
                    3'b110: ALUControl = ALU_OR;                         // or  / ori
                    3'b111: ALUControl = ALU_AND;                        // and / andi
                    default: ALUControl = ALU_ADD;
                endcase
            end

            default: ALUControl = ALU_ADD;
        endcase
    end
endmodule
