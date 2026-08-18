// register_file.sv
// 32 x 32-bit register file for the single-cycle RV32I core.
// Two combinational read ports, one clocked write port.
// x0 is hardwired to zero (writes to it are ignored, reads always return 0).

module register_file (
  input  logic        clk,
  input  logic        we3,     // write enable (from Control Unit's RegWrite)
  input  logic [4:0]  a1,      // read address 1 (rs1)
  input  logic [4:0]  a2,      // read address 2 (rs2)
  input  logic [4:0]  a3,      // write address  (rd)
  input  logic [31:0] wd3,     // write data
  output logic [31:0] rd1,     // read data 1
  output logic [31:0] rd2      // read data 2
);

  // --- Unpacked array: 32 separate 32-bit registers ---
  // logic [31:0]  -> each element is a 32-bit word  (this is the "packed" part)
  // regs [31:0]   -> there are 32 such elements      (this is the "unpacked" part)
  // Think of it as: 32 boxes, each box holds one 32-bit value.
  logic [31:0] regs [31:0];

  // --- Sequential write: always_ff = "this block has memory, triggered by a clock edge" ---
  // Only x0 (address 0) is protected; every other register is freely writable.
  always_ff @(posedge clk) begin
    if (we3 && a3 != 5'd0) begin
      regs[a3] <= wd3;   // non-blocking assignment: update happens "at the clock edge"
    end
  end

  // --- Combinational reads: no clock, output follows input instantly ---
  // x0 always reads as zero, regardless of what (if anything) was ever written to it.
  assign rd1 = (a1 == 5'd0) ? 32'd0 : regs[a1];
  assign rd2 = (a2 == 5'd0) ? 32'd0 : regs[a2];

endmodule
