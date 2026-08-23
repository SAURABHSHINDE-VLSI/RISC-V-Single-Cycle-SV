module Main_Decoder (
    input  logic [6:0] Op,
    input  logic [2:0] funct3,     // [bne] needed to tell beq (000) from bne (001)
    input  logic       Zero,
    output logic       RegWrite,
    output logic       ALUSrc,
    output logic       MemWrite,
    output logic [1:0] ResultSrc,  // [jal] widened 1->2 bits: 00=ALU, 01=mem, 10=PC+4
    output logic [2:0] ImmSrc,     // [jal] widened 2->3 bits so it can carry IMM_J (100)
    output logic [1:0] ALUOp,
    output logic       Branch,
    output logic       Jump,       // [jal] 1 = unconditional jump (jal)
    output logic       PCSrc
);

    // jal writes PC+4 into rd, so it is also a register-writing instruction.
    assign RegWrite = (Op == 7'b0000011 | Op == 7'b0110011 |
                       Op == 7'b0010011 | Op == 7'b1101111) ? 1'b1 : 1'b0;

    // Immediate format: I=000, S=001, B=010, J=100  (matches riscv_pkg::imm_sel_t)
    assign ImmSrc = (Op == 7'b0100011) ? 3'b001 :   // S-type (sw)
                     (Op == 7'b1100011) ? 3'b010 :   // B-type (beq/bne)
                     (Op == 7'b1101111) ? 3'b100 :   // J-type (jal)
                                          3'b000;     // I-type (addi/lw/...)

    assign ALUSrc = (Op == 7'b0000011 | Op == 7'b0100011 | Op == 7'b0010011) ? 1'b1 : 1'b0;

    assign MemWrite = (Op == 7'b0100011) ? 1'b1 : 1'b0;

    // Write-back source: lw takes memory (01), jal takes PC+4 (10), everything else ALU (00)
    assign ResultSrc = (Op == 7'b0000011) ? 2'b01 :   // lw
                        (Op == 7'b1101111) ? 2'b10 :   // jal
                                             2'b00;     // ALU ops

    assign Branch = (Op == 7'b1100011) ? 1'b1 : 1'b0;
    assign Jump   = (Op == 7'b1101111) ? 1'b1 : 1'b0;  // [jal]

    assign ALUOp = (Op == 7'b0110011 | Op == 7'b0010011) ? 2'b10 :  // R-type & I-type ALU: funct3 picks op
                    (Op == 7'b1100011) ? 2'b01 :                    // branch: subtract to compare
                                         2'b00;                      // lw / sw / jal: add (or don't-care)

    // [bne] Is the branch condition satisfied?
    //   beq (funct3=000): take it when the operands are equal      -> Zero
    //   bne (funct3=001): take it when they are NOT equal          -> ~Zero
    logic branch_taken;
    assign branch_taken = (funct3 == 3'b000) ? Zero  :
                          (funct3 == 3'b001) ? ~Zero :
                                               1'b0;   // other branch types not in our subset

    // Redirect the PC when we take a branch OR when it is an unconditional jump.
    assign PCSrc = Jump | (Branch & branch_taken);

endmodule
