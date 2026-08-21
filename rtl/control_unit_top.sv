
`include "alu_decoder.sv"
`include "main_decoder.sv"

module Control_Unit_Top (
  input  logic [6:0] Op,
  input  logic       Zero,
  output logic       RegWrite,
  output logic [1:0] ImmSrc,
  output logic       ALUSrc,
  output logic       MemWrite,
  output logic       ResultSrc,
  output logic       Branch,
  output logic       PCSrc,
  input  logic [2:0] funct3,
  input  logic [6:0] funct7,
  output logic [2:0] ALUControl
);

   logic [1:0]ALUOp;

    Main_Decoder Main_Decoder(
                .Op(Op),
                .Zero(Zero),
                .RegWrite(RegWrite),
                .ImmSrc(ImmSrc),
                .MemWrite(MemWrite),
                .ResultSrc(ResultSrc),
                .Branch(Branch),
                .PCSrc(PCSrc),
                .ALUSrc(ALUSrc),
                .ALUOp(ALUOp)
  );

    ALU_Decoder ALU_Decoder(
                            .ALUOp(ALUOp),
                            .funct3(funct3),
                            .funct7(funct7),
                            .op(Op),
                            .ALUControl(ALUControl)
    );


endmodule