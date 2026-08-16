// alu_tb.sv
// Directed testbench for alu.sv. Test vectors are pulled directly from
// the MERL course reference: the ALUControl table (page 3) and the
// worked `lw x6, -4(x9)` example (pages 15-16).

import riscv_pkg::*;

module alu_tb;

  logic [31:0] a, b;
  alu_op_t     alu_control;
  logic [31:0] result;
  logic        zero, negative, carry, overflow;

  int errors = 0;

  alu dut (
    .a(a), .b(b), .alu_control(alu_control),
    .result(result), .zero(zero), .negative(negative),
    .carry(carry), .overflow(overflow)
  );

  task automatic check(
    input logic [31:0] exp_result,
    input string        name
  );
    if (result !== exp_result) begin
      $display("FAIL [%s]: expected 0x%08h, got 0x%08h", name, exp_result, result);
      errors++;
    end else begin
      $display("PASS [%s]: result = 0x%08h", name, result);
    end
  endtask

  initial begin
    // --- add: 5 + 3 = 8 ---
    a = 32'd5; b = 32'd3; alu_control = ALU_ADD; #10;
    check(32'd8, "add 5+3");

    // --- sub: 10 - 4 = 6 ---
    a = 32'd10; b = 32'd4; alu_control = ALU_SUB; #10;
    check(32'd6, "sub 10-4");

    // --- and ---
    a = 32'hFF00FF00; b = 32'h0F0F0F0F; alu_control = ALU_AND; #10;
    check(32'h0F000F00, "and");

    // --- or ---
    a = 32'hF0F0F0F0; b = 32'h0F0F0F0F; alu_control = ALU_OR; #10;
    check(32'hFFFFFFFF, "or");

    // --- slt: 3 < 5 -> 1 ---
    a = 32'd3; b = 32'd5; alu_control = ALU_SLT; #10;
    check(32'd1, "slt 3<5 true");

    // --- slt: 5 < 3 -> 0 ---
    a = 32'd5; b = 32'd3; alu_control = ALU_SLT; #10;
    check(32'd0, "slt 5<3 false");

    // --- zero flag check: 4 - 4 = 0 ---
    a = 32'd4; b = 32'd4; alu_control = ALU_SUB; #10;
    check(32'd0, "sub 4-4 (zero flag)");
    if (!zero) begin
      $display("FAIL [zero flag]: expected zero=1, got zero=0");
      errors++;
    end else begin
      $display("PASS [zero flag]: zero=1 as expected");
    end

    // --- traced course example: lw x6, -4(x9) ---
    // Base address (RD1) = 0x2004, ImmExt (sign-extended -4) = 0xFFFFFFFC
    // ALUControl = 000 (add) -> ALUResult should be 0x2000 (pages 15-16)
    a = 32'h00002004; b = 32'hFFFFFFFC; alu_control = ALU_ADD; #10;
    check(32'h00002000, "lw x6,-4(x9) address calc");

    // --- negative flag check: 4 - 10 = -6 (negative) ---
    a = 32'd4; b = 32'd10; alu_control = ALU_SUB; #10;
    check(32'hFFFFFFFA, "sub 4-10 (negative result)");
    if (!negative) begin
      $display("FAIL [negative flag]: expected negative=1, got negative=0");
      errors++;
    end else begin
      $display("PASS [negative flag]: negative=1 as expected");
    end

    // --- carry flag check: unsigned overflow, 0xFFFFFFFF + 2 ---
    a = 32'hFFFFFFFF; b = 32'd2; alu_control = ALU_ADD; #10;
    $display("INFO [carry/overflow]: result=0x%08h carry=%b overflow=%b", result, carry, overflow);

    if (errors == 0)
      $display("\n=== ALL TESTS PASSED ===");
    else
      $display("\n=== %0d TEST(S) FAILED ===", errors);

    $finish;
  end

endmodule
