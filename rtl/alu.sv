// alu.sv
// Single-cycle RV32I ALU. Matches the MERL course ALUControl encoding
// defined in riscv_pkg::alu_op_t (see page 3-6 of the course reference).
//
//   ALUControl | Operation
//   -----------+-----------
//     000      | add            (lw, sw, addi, add)
//     001      | subtract       (beq, sub)
//     010      | and
//     011      | or
//     101      | set-less-than  (slt)
//
// Any other ALUControl value is a don't-care per the course spec, so we
// default Result to 0 for those cases.

import riscv_pkg::*;


module ALU (
  input  logic [31:0] A,
  input  logic [31:0] B,
  input  alu_op_t     ALUControl,
  output logic [31:0] Result,
  output logic        Zero,
  output logic        Negative,
  output logic        Carry,
  output logic        OverFlow
);

  logic [32:0] Sum_ext;
  logic [31:0] Sum;
  logic        Cout;

  logic [3:0] ALUControl_bits;
  assign ALUControl_bits = ALUControl;

  // Adder/subtractor: b is two's-complement negated for subtract
  // (same trick - ALU uses: A + (~B + 1))
  assign Sum_ext = (ALUControl_bits[0] == 1'b0) ? ({1'b0, A} + {1'b0, B})
                                                  : ({1'b0, A} + {1'b0, ~B} + 33'b1);
  assign {Cout, Sum} = Sum_ext;

  logic SLT_result_bit;
  assign SLT_result_bit = Sum[31];

  always_comb begin
    case (ALUControl)
      ALU_ADD: Result = Sum;                              // add   (lw, sw, addi, add)
      ALU_SUB: Result = Sum;                              // sub   (beq, bne, sub)
      ALU_AND: Result = A & B;                            // and,  andi
      ALU_OR : Result = A | B;                            // or,   ori
      ALU_XOR: Result = A ^ B;                            // xor,  xori
      ALU_SLT: Result = SLT_result_bit ? 32'd1 : 32'd0;   // slt,  slti  (signed)
      ALU_SLL: Result = A << B[4:0];                      // sll,  slli
      ALU_SRL: Result = A >> B[4:0];                      // srl,  srli  (logical)
      ALU_SRA: Result = $signed(A) >>> B[4:0];            // sra,  srai  (arithmetic)
      default: Result = 32'b0;
    endcase
  end

  // Flags  meaningful only for add/subtractor
  assign OverFlow = (Sum[31] ^ A[31])
                   & ~(ALUControl_bits[0] ^ B[31] ^ A[31])
                   & ~ALUControl_bits[1];
  assign Carry    = ~ALUControl_bits[1] & Cout;
  assign Zero     = (Result == 32'b0);
  assign Negative = Result[31];

endmodule