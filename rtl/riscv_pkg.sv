// riscv_pkg.sv
// Shared types for the single-cycle RV32I core.
// Import this in every module: `import riscv_pkg::*;`

package riscv_pkg;

  // ---------------------------------------------------------------
  // ALU operation select — decoded by ALU Control from funct3/funct7/opcode
  // ---------------------------------------------------------------
  // Encoding matches the MERL course ALU Decoder truth table exactly
  // (ALUOp/funct3/funct7 -> ALUControl), so Control Unit output can be
  // used directly without re-mapping.
  typedef enum logic [2:0] {
    ALU_ADD = 3'b000,   // lw, sw, addi, add
    ALU_SUB = 3'b001,   // beq, sub
    ALU_AND = 3'b010,   // and
    ALU_OR  = 3'b011,   // or
    ALU_SLT = 3'b101    // slt
  } alu_op_t;

  // ---------------------------------------------------------------
  // Immediate format select — tells the Immediate Generator how to
  // sign-extend / assemble the immediate from the raw instruction
  // ---------------------------------------------------------------
  typedef enum logic [2:0] {
    IMM_I,   // addi, lw, jalr
    IMM_S,   // sw
    IMM_B,   // beq, bne, ...
    IMM_U,   // lui, auipc
    IMM_J    // jal
  } imm_sel_t;

  // ---------------------------------------------------------------
  // Control signals produced by the Control Unit (combinational,
  // decoded from opcode/funct3/funct7 each cycle in single-cycle design)
  // ---------------------------------------------------------------
  typedef struct packed {
    logic       reg_write;   // write result back to register file
    logic       alu_src;     // 0 = rs2, 1 = immediate  (ALU operand B mux)
    logic       mem_write;   // store to data memory
    logic       mem_read;    // load from data memory
    logic       branch;      // is a branch instruction
    logic       jump;        // is a jump instruction (jal/jalr)
    logic [1:0] result_src;  // 00 = ALU result, 01 = mem data, 10 = PC+4
    imm_sel_t   imm_sel;
    alu_op_t    alu_ctrl;
  } ctrl_t;

  // ---------------------------------------------------------------
  // Decoded instruction fields — output of Instruction Decode stage
  // ---------------------------------------------------------------
  typedef struct packed {
    logic [4:0] rs1;
    logic [4:0] rs2;
    logic [4:0] rd;
    logic [6:0] opcode;
    logic [2:0] funct3;
    logic [6:0] funct7;
  } decoded_instr_t;

endpackage : riscv_pkg
