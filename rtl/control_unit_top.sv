
`include "alu_decoder.sv"
`include "main_decoder.sv"

import riscv_pkg::*;

module Control_Unit_Top (
  input  decoded_instr_t dec,     // decoded instruction fields (riscv_pkg)
  input  logic           Zero,    // ALU zero flag (for branch resolution)
  output ctrl_t          ctrl,    // bundled control signals (riscv_pkg)
  output logic           PCSrc    // 1 = take branch/jump target
);

  // Individual signals from the (unchanged) leaf decoders.
  logic       reg_write, alu_src, mem_write, result_src, branch;
  logic [1:0] imm_src;
  logic [1:0] alu_op;
  logic [2:0] alu_control;

  Main_Decoder Main_Decoder (
      .Op(dec.opcode),
      .Zero(Zero),
      .RegWrite(reg_write),
      .ImmSrc(imm_src),
      .MemWrite(mem_write),
      .ResultSrc(result_src),
      .Branch(branch),
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
  // A few fields are forward-looking for the planned 5-stage pipeline / jumps:
  //   * jump is tied low (no jal/jalr yet)
  //   * result_src's 2'b10 (PC+4) encoding is reserved for jumps
  always_comb begin
    ctrl.reg_write  = reg_write;
    ctrl.alu_src    = alu_src;
    ctrl.mem_write  = mem_write;
    ctrl.mem_read   = result_src;            // load: write-back comes from memory
    ctrl.branch     = branch;
    ctrl.jump       = 1'b0;                  // jal/jalr not in the single-cycle core yet
    ctrl.result_src = {1'b0, result_src};    // 00 = ALU, 01 = mem  (10 = PC+4 reserved)
    ctrl.imm_sel    = imm_sel_t'(imm_src);   // 00->IMM_I, 01->IMM_S, 10->IMM_B
    ctrl.alu_ctrl   = alu_op_t'(alu_control);
  end

endmodule
