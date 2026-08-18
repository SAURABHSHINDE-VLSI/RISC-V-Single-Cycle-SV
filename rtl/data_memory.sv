// -----------------------------------------------------------------------------
// Data_Memory
// -----------------------------------------------------------------------------
// 4 KiB data memory for a single-cycle RISC-V processor.
//
// The processor supplies byte addresses on A.  Each memory entry stores one
// 32-bit word (4 bytes), so A[1:0] identifies a byte within the word and is
// ignored here.  A[11:2] selects one of the 1024 word locations.
//
// This module implements aligned word accesses only:
//   * Store: WD is written on a rising clock edge when WE is high.
//   * Load : RD always reflects the word at address A (asynchronous read).
// -----------------------------------------------------------------------------
module Data_Memory (
    input  logic        clk, // Processor clock; used for stores.
    input  logic        WE,  // Write enable: 1 = store WD, 0 = read only.
    input  logic [31:0] A,   // Byte address supplied by the CPU.
    input  logic [31:0] WD,  // Write data from the CPU register file.
    output logic [31:0] RD   // Read data returned to the CPU register file.
);

    // 1024 words x 32 bits/word = 4096 bytes (4 KiB).
    logic [31:0] mem [0:1023];

    // Store a complete 32-bit word.  The write occurs only at a clock edge,
    // which corresponds to the behavior of the RISC-V sw instruction.
    always_ff @(posedge clk) begin
        if (WE)
            mem[A[11:2]] <= WD;
    end

    // Read a complete 32-bit word without waiting for a clock edge.  For
    // example, A = 112 selects mem[112 / 4] = mem[28].
    assign RD = mem[A[11:2]];

    // Simulation/test initialization.  This makes lw from byte address 112
    // return decimal 32 before any store is performed.  Remove or replace this
    // block later when loading memory contents from a program data file.
    initial begin
        mem[28] = 32'h0000_0020;
    end

endmodule
