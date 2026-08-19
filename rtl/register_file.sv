// register_file.sv
// 32 x 32-bit register file for the single-cycle RV32I core.
// Two combinational read ports, one clocked write port.
// x0 is hardwired to zero (writes to it are ignored, reads always return 0).

module register_file (
  input  logic        clk,
  input  logic        WE3,     // write enable (from Control Unit's RegWrite)
  input  logic [4:0]  A1,      // read address 1 (rs1)
  input  logic [4:0]  A2,      // read address 2 (rs2)
  input  logic [4:0]  A3,      // write address  (rd)
  input  logic [31:0] WD3,     // write data
  output logic [31:0] RD1,     // read data 1
  output logic [31:0] RD2      // read data 2
);

  // --- Unpacked array: 32 separate 32-bit registers ---
  // logic [31:0]  -> each element is a 32-bit word  (this is the "packed" part)
  // regs [31:0]   -> there are 32 such elements      (this is the "unpacked" part)
  // Think of it as: 32 boxes, each box holds one 32-bit value.
  logic [31:0] regs [31:0];

  // --- Sequential write: always_ff = "this block has memory, triggered by a clock edge" ---
  // Only x0 (address 0) is protected; every other register is freely writable.
  always_ff @(posedge clk) begin
    if (WE3 && A3 != 5'd0) begin
      regs[A3] <= WD3;   // non-blocking assignment: update happens "at the clock edge"
    end
  end

  // --- Combinational reads: no clock, output follows input instantly ---
  // x0 always reads as zero, regardless of what (if anything) was ever written to it.
  assign RD1 = (A1 == 5'd0) ? 32'd0 : regs[A1];
  assign RD2 = (A2 == 5'd0) ? 32'd0 : regs[A2];

endmodule
