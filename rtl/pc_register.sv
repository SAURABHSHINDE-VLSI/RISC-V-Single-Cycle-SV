// pc.sv
// Program Counter for the single-cycle RV32I core.
// Holds the address of the current instruction; updates to pc_next every
// clock edge. Resets to 0 so the CPU always boots from a known address.

module PC_Module (
  input  logic        clk,
  input  logic        rst,      // synchronous reset, active high
  input  logic [31:0] PC_Next,  // next PC value (from PCSrc mux in top-level)
  output logic [31:0] PC        // current PC -> Instruction Memory address
);

  always_ff @(posedge clk) begin
    if (rst)
      PC <= 32'b0;
    else
      PC <= PC_Next;
  end

endmodule
