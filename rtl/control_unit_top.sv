
`include "alu_decoder.sv"
`include "main_decoder.sv"

module Control_Unit_Top(Op,RegWrite,ImmSrc,ALUSrc,MemWrite,ResultSrc,Branch,funct3,funct7,ALUControl);

   logic [6:0]Op,funct7;
   logic [2:0]funct3;
   logic RegWrite,ALUSrc,MemWrite,ResultSrc,Branch;
   logic [1:0]ImmSrc;
   loigc [2:0]ALUControl;

   logic [1:0]ALUOp;

    Main_Decoder Main_Decoder(
                .Op(Op),
                .RegWrite(RegWrite),
                .ite),ImmSrc(ImmSrc),
                .MemWrite(MemWr
                .ResultSrc(ResultSrc),
                .Branch(Branch),
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