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

module alu (
  input  logic [31:0] a,
  input  logic [31:0] b,
  input  alu_op_t      alu_control,
  output logic [31:0] result,
  output logic         zero,
  output logic         negative,
  output logic         carry,
  output logic         overflow
);

  logic [32:0] sum_ext;   // 33 bits: {carry_out, 32-bit sum}
  logic [31:0] sum;
  logic        cout;

  logic [2:0] alu_control_bits;
  assign alu_control_bits = alu_control;

  // Adder/subtractor: b is two's-complement negated for subtract
  // (same trick the course's Verilog ALU uses: A + (~B + 1))
  assign sum_ext = (alu_control_bits[0] == 1'b0) ? ({1'b0, a} + {1'b0, b})
                                                  : ({1'b0, a} + {1'b0, ~b} + 33'b1);
  assign {cout, sum} = sum_ext;

  logic slt_result_bit;
  assign slt_result_bit = sum[31];

  always_comb begin
    case (alu_control_bits)
      3'b000:  result = sum;               // ALU_ADD
      3'b001:  result = sum;               // ALU_SUB
      3'b010:  result = a & b;             // ALU_AND
      3'b011:  result = a | b;             // ALU_OR
      3'b101:  result = slt_result_bit ? 32'd1 : 32'd0;  // ALU_SLT
      default: result = 32'b0;
    endcase
  end

  // Flags — meaningful only for add/subtract (matches course's Verilog reference)
  assign overflow = (sum[31] ^ a[31])
                   & ~(alu_control_bits[0] ^ b[31] ^ a[31])
                   & ~alu_control_bits[1];
  assign carry    = ~alu_control_bits[1] & cout;
  assign zero     = (result == 32'b0);
  assign negative = result[31];

endmodule
