`include "pc_register.sv"
`include "instruction_memory.sv"
`include "register_file.sv"
`include "sign_extend.sv"
`include "alu.sv"
`include "control_unit_top.sv"
`include "data_memory.sv"

module single_cycle_top (
    input logic clk,
    input logic rst,
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

    logic RegWrite;
    logic MemWrite;
    logic ALUSrc;
    logic ResultSrc;
    logic [1:0] ImmSrc;
    logic [2:0] ALUControl_Top;
    logic Branch;
    logic PCSrc;
    logic Zero;

    // Program Counter: stores the address of the current instruction
    PC_Module PC (
        .clk(clk),
        .rst(rst),
        .PC(PC_Top),
        .PC_Next(PCSrc ? PCBranch : PCPlus4)
    );

    // PC Adder: calculates the address of the next sequential instruction
    assign PCPlus4 = PC_Top + 32'd4;
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
        .WE3(RegWrite),
        .WD3(Result) ,
        .A1(RD_Instr[19:15]),
        .A2(RD_Instr[24:20]),
        .A3(RD_Instr[11:7]),
        .RD1(RD1_Top),
        .RD2(RD2_Top)
    );

    // Sign Extension: generates the 32-bit immediate from the instruction
    Sign_Extend sign_extend (
        .In(RD_Instr),
        .ImmSrc(ImmSrc),
        .Imm_Ext(Imm_Ext_Top)
    );

    // MUX: selects register data or immediate as ALU input B
    assign SrcB = ALUSrc ? Imm_Ext_Top : RD2_Top;

    // ALU: performs arithmetic and logical operations
    ALU ALU (
        .A(RD1_Top),
        .B(SrcB),
        .Result(ALUResult),
        .ALUControl(ALUControl_Top),
        .OverFlow(),
        .Carry(),
        .Zero(Zero),
        .Negative()
    );

    // Control Unit: generates control signals from the instruction fields
    Control_Unit_Top Control_Unit_Top (
        .Op(RD_Instr[6:0]),
        .Zero(Zero),
        .RegWrite(RegWrite),
        .ImmSrc(ImmSrc),
        .ALUSrc(ALUSrc),
        .MemWrite(MemWrite),
        .ResultSrc(ResultSrc),
        .Branch(Branch),
        .PCSrc(PCSrc),
        .funct3(RD_Instr[14:12]),
        .funct7(RD_Instr[31:25]),
        .ALUControl(ALUControl_Top)
    );

    // Data Memory: handles load and store operations
    Data_Memory data_memory (
        .clk(clk),
        .WE(MemWrite),
        .WD(RD2_Top),
        .A(ALUResult),
        .RD(ReadData)
    );

    // MUX: selects ALU result or memory data for register write-back
    assign Result = ResultSrc ? ReadData : ALUResult;

endmodule