// pc_register_tb.sv
// Testbench for pc_register.sv
// Tests: reset behavior, normal increment (PC+4), branch jump, sequential execution

`timescale 1ns / 1ps

module pc_register_tb;

  logic        clk;
  logic        rst;
  logic [31:0] PC_Next;
  logic [31:0] PC;

  int errors = 0;

  // Port names and capitalization match PC_Module in pc_register.sv.
  PC_Module dut (
    .clk    (clk),
    .rst    (rst),
    .PC_Next(PC_Next),
    .PC     (PC)
  );

  // Clock generator: 10-unit period
  initial clk = 0;
  always #5 clk = ~clk;

  task automatic check(input logic [31:0] exp, input string name);
    if (PC !== exp) begin
      $display("FAIL [%s]: expected 0x%08h, got 0x%08h", name, exp, PC);
      errors++;
    end else
      $display("PASS [%s]: PC = 0x%08h", name, PC);
  endtask

  // Drive PC_Next and wait one clock edge, then check PC.
  task automatic drive_and_check(
    input logic [31:0] next_val,
    input logic [31:0] exp_pc,
    input string name
  );
    PC_Next = next_val;
    @(posedge clk); #1;   // #1 lets the always_ff output settle after the edge
    check(exp_pc, name);
  endtask

  initial begin
    rst = 1;
    PC_Next = 32'h0;

    // --- Reset: PC must go to 0 ---
    @(posedge clk); #1;
    check(32'h0, "reset to 0");

    // --- Release reset, drive PC+4 sequence ---
    rst = 0;
    drive_and_check(32'h4,  32'h4,  "PC+4 first");
    drive_and_check(32'h8,  32'h8,  "PC+4 second");
    drive_and_check(32'hC,  32'hC,  "PC+4 third");

    // --- Branch: jump to a non-sequential address ---
    drive_and_check(32'h100, 32'h100, "branch to 0x100");
    drive_and_check(32'h104, 32'h104, "resume PC+4 after branch");

    // --- Re-assert reset mid-execution: PC must go back to 0 ---
    rst = 1;
    @(posedge clk); #1;
    check(32'h0, "mid-execution reset back to 0");

    if (errors == 0)
      $display("\n=== ALL TESTS PASSED ===");
    else
      $display("\n=== %0d TEST(S) FAILED ===", errors);

    $finish;
  end

endmodule
