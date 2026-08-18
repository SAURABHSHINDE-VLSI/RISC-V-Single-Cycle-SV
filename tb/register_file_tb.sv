// register_file_tb.sv
// Testbench for register_file.sv.
//
// KEY DIFFERENCE FROM alu_tb.sv:
// The ALU is pure combinational -> we just set inputs and wait a fixed #10.
// The Register File has a WRITE PORT driven by a clock (always_ff @(posedge clk)
// inside the DUT) -> the testbench must generate its own clock and wait for
// clock EDGES, not just fixed delays, or writes won't actually happen.
// This is the standard pattern for testing any sequential (clocked) module.

module register_file_tb;

  logic        clk;
  logic        we3;
  logic [4:0]  a1, a2, a3;
  logic [31:0] wd3;
  logic [31:0] rd1, rd2;

  int errors = 0;

  register_file dut (
    .clk(clk), .we3(we3),
    .a1(a1), .a2(a2), .a3(a3), .wd3(wd3),
    .rd1(rd1), .rd2(rd2)
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
  task automatic write_reg(input logic [4:0] addr, input logic [31:0] data);
    @(posedge clk);       // wait for a rising edge...
    a3  = addr;
    wd3 = data;
    we3 = 1'b1;
    @(posedge clk);       // ...the write happens ON this edge (always_ff in the DUT)
    we3 = 1'b0;            // drop write-enable so we don't accidentally write again
  endtask

  // --- Helper task: check both read ports at once ---
  task automatic check_read(
    input  logic [4:0]  addr1,
    input  logic [4:0]  addr2,
    input  logic [31:0] exp1,
    input  logic [31:0] exp2,
    input  string        name
  );
    a1 = addr1;
    a2 = addr2;
    #1; // reads are combinational (assign statements) -> settle after a tiny delay
    if (rd1 !== exp1 || rd2 !== exp2) begin
      $display("FAIL [%s]: rd1=0x%08h (exp 0x%08h)  rd2=0x%08h (exp 0x%08h)",
                name, rd1, exp1, rd2, exp2);
      errors++;
    end else begin
      $display("PASS [%s]: rd1=0x%08h  rd2=0x%08h", name, rd1, rd2);
    end
  endtask

  initial begin
    we3 = 0; a1 = 0; a2 = 0; a3 = 0; wd3 = 0;

    // --- x0 must read as zero before anything is written ---
    check_read(5'd0, 5'd0, 32'd0, 32'd0, "x0 initial (both ports)");

    // --- Attempt to write x0 -> must be silently ignored ---
    write_reg(5'd0, 32'hDEADBEEF);
    check_read(5'd0, 5'd0, 32'd0, 32'd0, "x0 after write attempt (still zero)");

    // --- Write x5, read it back on port 1 ---
    write_reg(5'd5, 32'hAAAA5555);
    check_read(5'd5, 5'd0, 32'hAAAA5555, 32'd0, "x5 write then read (port1)");

    // --- Write x10 (different register), confirm x5 is undisturbed ---
    write_reg(5'd10, 32'h12345678);
    check_read(5'd5, 5'd10, 32'hAAAA5555, 32'h12345678, "x5 and x10 simultaneous read");

    // --- we3=0 write attempt: must NOT overwrite existing data ---
    // (An unwritten register has no defined value in a design with no reset --
    //  so we write a KNOWN value first, then prove a disabled write can't change it.)
    write_reg(5'd7, 32'h11112222);
    a3  = 5'd7;
    wd3 = 32'hFFFFFFFF;
    we3 = 1'b0;
    @(posedge clk);
    check_read(5'd7, 5'd0, 32'h11112222, 32'd0, "x7 unchanged (we3 was low)");

    // --- Overwrite x5 with a new value ---
    write_reg(5'd5, 32'hCAFEF00D);
    check_read(5'd5, 5'd10, 32'hCAFEF00D, 32'h12345678, "x5 overwritten, x10 unchanged");

    if (errors == 0)
      $display("\n=== ALL TESTS PASSED ===");
    else
      $display("\n=== %0d TEST(S) FAILED ===", errors);

    $finish;
  end

endmodule
