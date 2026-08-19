// register_file_tb.sv
// Testbench for register_file.sv.
//
// KEY DIFFERENCE FROM alu_tb.sv:
// The ALU is pure combinational -> we just set inputs and wait a fixed #10.
// The Register File has a WRITE PORT driven by a clock (always_ff @(posedge clk)
// inside the DUT) -> the testbench must generate its own clock and wait for
// clock EDGES, not just fixed delays, or writes won't actually happen.
// This is the standard pattern for testing any sequential (clocked) module.

`timescale 1ns / 1ps

module register_file_tb;

  logic        clk;
  logic        WE3;
  logic [4:0]  A1, A2, A3;
  logic [31:0] WD3;
  logic [31:0] RD1, RD2;

  int errors = 0;

  // DUT port names must exactly match register_file.sv.
  // SystemVerilog is case-sensitive: WE3 is different from we3.
  register_file dut (
    .clk(clk),
    .WE3(WE3),
    .A1 (A1),
    .A2 (A2),
    .A3 (A3),
    .WD3(WD3),
    .RD1(RD1),
    .RD2(RD2)
  );

  // --- Clock generator ---
  // In Verilog you'd write this exact same way: toggle every 5 time units,
  // giving a 10-unit period. Nothing SV-specific here, just new *for you*
  // because alu_tb.sv never needed a clock at all.
  initial clk = 0;
  always #5 clk = ~clk;

  // --- Helper task: perform a clocked write ---
  // "automatic" (same meaning as in alu_tb.sv's check task): each call gets
  // its own local variables, so calls don't interfere if ever run concurrently.
  task automatic write_reg(
    input logic [4:0]  addr,
    input logic [31:0] data
  );
    @(posedge clk);       // wait for a rising edge...
    A3  = addr;
    WD3 = data;
    WE3 = 1'b1;
    @(posedge clk);       // ...the write happens ON this edge (always_ff in the DUT)
    WE3 = 1'b0;           // drop write-enable so we don't accidentally write again
  endtask

  // --- Helper task: check both read ports at once ---
  task automatic check_read(
    input logic [4:0]  addr1,
    input logic [4:0]  addr2,
    input logic [31:0] exp1,
    input logic [31:0] exp2,
    input string       name
  );
    A1 = addr1;
    A2 = addr2;
    #1; // reads are combinational (assign statements) -> settle after a tiny delay

    if (RD1 !== exp1 || RD2 !== exp2) begin
      $display("FAIL [%s]: RD1=0x%08h (exp 0x%08h)  RD2=0x%08h (exp 0x%08h)",
                name, RD1, exp1, RD2, exp2);
      errors++;
    end
    else begin
      $display("PASS [%s]: RD1=0x%08h  RD2=0x%08h", name, RD1, RD2);
    end
  endtask

  initial begin
    WE3 = 0;
    A1  = 0;
    A2  = 0;
    A3  = 0;
    WD3 = 0;

    // --- x0 must read as zero before anything is written ---
    check_read(5'd0, 5'd0, 32'd0, 32'd0, "x0 initial (both ports)");

    // --- Attempt to write x0 -> must be silently ignored ---
    write_reg(5'd0, 32'hDEAD_BEEF);
    check_read(5'd0, 5'd0, 32'd0, 32'd0,
               "x0 after write attempt (still zero)");

    // --- Write x5, read it back on port 1 ---
    write_reg(5'd5, 32'hAAAA_5555);
    check_read(5'd5, 5'd0, 32'hAAAA_5555, 32'd0,
               "x5 write then read (port1)");

    // --- Write x10 (different register), confirm x5 is undisturbed ---
    write_reg(5'd10, 32'h1234_5678);
    check_read(5'd5, 5'd10, 32'hAAAA_5555, 32'h1234_5678,
               "x5 and x10 simultaneous read");

    // --- WE3=0 write attempt: must NOT overwrite existing data ---
    // An unwritten register has no defined value in a design with no reset.
    // Therefore write a KNOWN value first, then prove a disabled write cannot
    // change it.
    write_reg(5'd7, 32'h1111_2222);
    A3  = 5'd7;
    WD3 = 32'hFFFF_FFFF;
    WE3 = 1'b0;
    @(posedge clk);

    check_read(5'd7, 5'd0, 32'h1111_2222, 32'd0,
               "x7 unchanged (WE3 was low)");

    // --- Overwrite x5 with a new value ---
    write_reg(5'd5, 32'hCAFE_F00D);
    check_read(5'd5, 5'd10, 32'hCAFE_F00D, 32'h1234_5678,
               "x5 overwritten, x10 unchanged");

    if (errors == 0)
      $display("\n=== ALL TESTS PASSED ===");
    else
      $display("\n=== %0d TEST(S) FAILED ===", errors);

    $finish;
  end

endmodule
