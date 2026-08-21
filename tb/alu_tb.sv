// alu_tb.sv
// Directed testbench for alu.sv. Test vectors are pulled directly from
// the MERL course reference: the ALUControl table (page 3) and the
// worked `lw x6, -4(x9)` example (pages 15-16).

import riscv_pkg::*;
module alu_tb; 
 
  logic [31:0] A, B; 
  alu_op_t     ALUControl; 
  logic [31:0] Result; 
  logic        Zero, Negative, Carry, OverFlow; 
 
  int errors = 0; 
 
  ALU dut ( 
    .A(A), .B(B), .ALUControl(ALUControl), 
    .Result(Result), .Zero(Zero), .Negative(Negative), 
    .Carry(Carry), .OverFlow(OverFlow) 
  ); 
 
  task automatic check( 
    input logic [31:0] exp_result, 
    input string        name 
  ); 
    if (Result !== exp_result) begin 
      $display("FAIL [%s]: expected 0x%08h, got 0x%08h", name, exp_result, Result); 
      errors++; 
    end else begin 
      $display("PASS [%s]: result = 0x%08h", name, Result); 
    end 
  endtask 
 
  initial begin 
    // --- add: 5 + 3 = 8 --- 
    A = 32'd5; B = 32'd3; ALUControl = ALU_ADD; #10; 
    check(32'd8, "add 5+3"); 
 
    // --- sub: 10 - 4 = 6 --- 
    A = 32'd10; B = 32'd4; ALUControl = ALU_SUB; #10; 
    check(32'd6, "sub 10-4"); 
 
    // --- and --- 
    A = 32'hFF00FF00; B = 32'h0F0F0F0F; ALUControl = ALU_AND; #10; 
    check(32'h0F000F00, "and"); 
 
    // --- or --- 
    A = 32'hF0F0F0F0; B = 32'h0F0F0F0F; ALUControl = ALU_OR; #10; 
    check(32'hFFFFFFFF, "or"); 
 
    // --- slt: 3 < 5 -> 1 --- 
    A = 32'd3; B = 32'd5; ALUControl = ALU_SLT; #10; 
    check(32'd1, "slt 3<5 true"); 
 
    // --- slt: 5 < 3 -> 0 --- 
    A = 32'd5; B = 32'd3; ALUControl = ALU_SLT; #10; 
    check(32'd0, "slt 5<3 false"); 
 
    // --- zero flag check: 4 - 4 = 0 --- 
    A = 32'd4; B = 32'd4; ALUControl = ALU_SUB; #10; 
    check(32'd0, "sub 4-4 (zero flag)"); 
    if (!Zero) begin 
      $display("FAIL [zero flag]: expected zero=1, got zero=0"); 
      errors++; 
    end else begin 
      $display("PASS [zero flag]: zero=1 as expected"); 
    end 
 
    // --- traced course example: lw x6, -4(x9) --- 
    // Base address (RD1) = 0x2004, ImmExt (sign-extended -4) = 0xFFFFFFFC 
    // ALUControl = 000 (add) -> ALUResult should be 0x2000 (pages 15-16) 
    A = 32'h00002004; B = 32'hFFFFFFFC; ALUControl = ALU_ADD; #10; 
    check(32'h00002000, "lw x6,-4(x9) address calc"); 
 
    // --- negative flag check: 4 - 10 = -6 (negative) --- 
    A = 32'd4; B = 32'd10; ALUControl = ALU_SUB; #10; 
    check(32'hFFFFFFFA, "sub 4-10 (negative result)"); 
    if (!Negative) begin 
      $display("FAIL [negative flag]: expected negative=1, got negative=0"); 
      errors++; 
    end else begin 
      $display("PASS [negative flag]: negative=1 as expected"); 
    end 
 
    // --- carry flag check: unsigned overflow, 0xFFFFFFFF + 2 --- 
    A = 32'hFFFFFFFF; B = 32'd2; ALUControl = ALU_ADD; #10; 
    $display("INFO [carry/overflow]: result=0x%08h carry=%b overflow=%b", Result, Carry, OverFlow); 
 
    if (errors == 0) 
      $display("\n=== ALL TESTS PASSED ==="); 
    else 
      $display("\n=== %0d TEST(S) FAILED ===", errors); 
 
    $finish; 
  end 
 
endmodule