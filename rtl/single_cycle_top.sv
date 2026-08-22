`include "pc_register.sv"
`include "instruction_memory.sv"
`include "register_file.sv"
`include "sign_extend.sv"
`include "alu.sv"
`include "control_unit_top.sv"
`include "data_memory.sv"

import riscv_pkg::*;

module single_cycle_top (
    input  logic        clk,
    input  logic        rst,
    output logic [31:0] debug_pc
);

    logic [31:0] PC_Top;
    logic [31:0] RD_Instr;
    logic [31:0] RD1_Top;
    logic [31:0] RD2_Top;
    logic [31:0] Imm_Ext_Top;
    logic [31:0] ALUResult;
    logic [31:0] ReadData;
    logic [31:0] PCPlus4;
    logic [31:0] PCBranch;
    logic [31:0] SrcB;
    logic [31:0] Result;

    logic        Zero;
    logic        PCSrc;

    // Decoded instruction fields (decoded_instr_t from riscv_pkg)
    decoded_instr_t dec;
    always_comb begin
        dec.opcode = RD_Instr[6:0];
        dec.rd     = RD_Instr[11:7];
        dec.funct3 = RD_Instr[14:12];
        dec.rs1    = RD_Instr[19:15];
        dec.rs2    = RD_Instr[24:20];
        dec.funct7 = RD_Instr[31:25];
    end

    // Bundled control signals (ctrl_t from riscv_pkg)
    ctrl_t ctrl;

    // Program Counter: stores the address of the current instruction
    PC_Module PC (
        .clk(clk),
        .rst(rst),
        .PC(PC_Top),
        .PC_Next(PCSrc ? PCBranch : PCPlus4)
    );

    // PC adders: next sequential instruction and branch target
    assign PCPlus4  = PC_Top + 32'd4;
    assign PCBranch = PC_Top + Imm_Ext_Top;
    assign debug_pc = PC_Top;

    // Instruction Memory: fetches the instruction using the PC address
    Instruction_Memory instruction_memory (
        .A(PC_Top),
        .RD(RD_Instr)
    );

    // Register File: reads rs1 and rs2 and writes the result into rd
    Register_File register_file (
        .clk(clk),
        .WE3(ctrl.reg_write),
        .WD3(Result),
        .A1(dec.rs1),
        .A2(dec.rs2),
        .A3(dec.rd),
        .RD1(RD1_Top),
        .RD2(RD2_Top)
    );

    // Sign Extension: generates the 32-bit immediate from the instruction
    Sign_Extend sign_extend (
        .In(RD_Instr),
        .ImmSrc(ctrl.imm_sel),
        .Imm_Ext(Imm_Ext_Top)
    );

    // MUX: selects register data or immediate as ALU input B
    assign SrcB = ctrl.alu_src ? Imm_Ext_Top : RD2_Top;

    // ALU: performs arithmetic and logical operations
    ALU ALU (
        .A(RD1_Top),
        .B(SrcB),
        .Result(ALUResult),
        .ALUControl(ctrl.alu_ctrl),
        .OverFlow(),
        .Carry(),
        .Zero(Zero),
        .Negative()
    );

    // Control Unit: decodes the instruction into the ctrl_t bundle
    Control_Unit_Top Control_Unit_Top (
        .dec(dec),
        .Zero(Zero),
        .ctrl(ctrl),
        .PCSrc(PCSrc)
    );

    // Data Memory: handles load and store operations
    Data_Memory data_memory (
        .clk(clk),
        .WE(ctrl.mem_write),
        .WD(RD2_Top),
        .A(ALUResult),
        .RD(ReadData)
    );

    // MUX: write-back source select
    //   00 = ALU result, 01 = memory data, 10 = PC+4 (reserved for jal/jalr)
    always_comb begin
        case (ctrl.result_src)
            2'b00:   Result = ALUResult;
            2'b01:   Result = ReadData;
            2'b10:   Result = PCPlus4;
            default: Result = ALUResult;
        endcase
    end

endmodule
