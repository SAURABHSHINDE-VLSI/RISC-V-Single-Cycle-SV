module Main_Decoder (
    input  logic [6:0] Op,
    input  logic       Zero,
    output logic       RegWrite,
    output logic       ALUSrc,
    output logic       MemWrite,
    output logic       ResultSrc,
    output logic [1:0] ImmSrc,
    output logic [1:0] ALUOp,
    output logic      Branch,
    output logic      PCSrc  
);

    logic branch_;
    assign branch_ = Branch ;


    assign RegWrite = (Op == 7'b0000011 | Op == 7'b0110011) ? 1'b1 : 1'b0;

    assign ImmSrc = (Op == 7'b0100011) ? 2'b01 :
                     (Op == 7'b1100011) ? 2'b10 :
                                          2'b00;

    assign ALUSrc = (Op == 7'b0000011 | Op == 7'b0100011) ? 1'b1 : 1'b0;

    assign MemWrite = (Op == 7'b0100011) ? 1'b1 : 1'b0;

    assign ResultSrc = (Op == 7'b0000011) ? 1'b1 : 1'b0;

    assign branch = (Op == 7'b1100011) ? 1'b1 : 1'b0;

    assign ALUOp = (Op == 7'b0110011) ? 2'b10 :
                    (Op == 7'b1100011) ? 2'b01 :
                                         2'b00;

    assign PCSrc = Zero & branch_;

endmodule