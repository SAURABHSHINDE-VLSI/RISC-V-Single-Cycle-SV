
`include "alu_decoder.sv"
`include "main_decoder.sv"

import riscv_pkg::*;

module Control_Unit_Top (
  input  decoded_instr_t dec,     // decoded instruction fields (riscv_pkg)
  input  logic           Zero,    // ALU zero flag (for branch resolution)
  output ctrl_t          ctrl,    // bundled control signals (riscv_pkg)
  output logic           PCSrc    // 1 = take branch/jump target
);

  // Individual signals from the leaf decoders.
  logic       reg_write, alu_src, mem_write, branch, jump;
  logic [1:0] result_src;   // [jal] widened to 2 bits (00=ALU, 01=mem, 10=PC+4)
  logic [2:0] imm_src;      // [jal] widened to 3 bits so it can carry IMM_J
  logic [1:0] alu_op;
  logic [3:0] alu_control;

  Main_Decoder Main_Decoder (
      .Op(dec.opcode),
      .funct3(dec.funct3),     // [bne] lets the decoder distinguish beq from bne
      .Zero(Zero),
      .RegWrite(reg_write),
      .ImmSrc(imm_src),
      .MemWrite(mem_write),
      .ResultSrc(result_src),
      .Branch(branch),
      .Jump(jump),             // [jal]
      .PCSrc(PCSrc),
      .ALUSrc(alu_src),
      .ALUOp(alu_op)
  );

  ALU_Decoder ALU_Decoder (
      .ALUOp(alu_op),
      .funct3(dec.funct3),
      .funct7(dec.funct7),
      .op(dec.opcode),
      .ALUControl(alu_control)
  );

  // Bundle everything into ctrl_t — the single source of truth for the datapath.
  // result_src == 2'b10 (PC+4) is now used by jal; jump is driven by the decoder.
  always_comb begin
    ctrl.reg_write  = reg_write;
    ctrl.alu_src    = alu_src;
    ctrl.mem_write  = mem_write;
    ctrl.mem_read   = (result_src == 2'b01); // load is the only write-back that reads memory
    ctrl.branch     = branch;
    ctrl.jump       = jump;                  // [jal] no longer tied low
    ctrl.result_src = result_src;            // 00 = ALU, 01 = mem, 10 = PC+4 (jal)
    ctrl.imm_sel    = imm_sel_t'(imm_src);   // 000->I, 001->S, 010->B, 100->J
    ctrl.alu_ctrl   = alu_op_t'(alu_control);
  end

endmodule
