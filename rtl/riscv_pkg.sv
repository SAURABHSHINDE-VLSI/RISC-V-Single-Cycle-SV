// riscv_pkg.sv
// Shared types for the single-cycle RV32I core.
// Import this in every module: `import riscv_pkg::*;`

package riscv_pkg;

  // ---------------------------------------------------------------
  // ALU operation select — decoded by ALU Control from funct3/funct7/opcode
  // ---------------------------------------------------------------
  
  // (ALUOp/funct3/funct7 -> ALUControl), so Control Unit output can be
  // used directly without re-mapping.
  typedef enum logic [3:0] {
    ALU_ADD = 4'b0000,   // lw, sw, addi, add
    ALU_SUB = 4'b0001,   // beq, bne, sub
    ALU_AND = 4'b0010,   // and, andi
    ALU_OR  = 4'b0011,   // or,  ori
    ALU_XOR = 4'b0100,   // xor, xori
    ALU_SLT = 4'b0101,   // slt, slti
    ALU_SLL = 4'b0110,   // sll, slli   (shift left  logical)
    ALU_SRL = 4'b0111,   // srl, srli   (shift right logical)
    ALU_SRA = 4'b1000    // sra, srai   (shift right arithmetic)
  } alu_op_t;

  // NOTE: imm_sel_t, ctrl_t, and decoded_instr_t below are all wired into
  // the single-cycle datapath — control_unit_top emits ctrl_t, and the top
  // uses decoded_instr_t and imm_sel_t. A few ctrl_t fields are forward-
  // looking for the planned 5-stage pipeline / jumps: jump is tied low, and
  // result_src's 2'b10 (PC+4) encoding is reserved for jal/jalr.

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
