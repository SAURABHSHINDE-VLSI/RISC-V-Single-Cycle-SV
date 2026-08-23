module Instruction_Memory (
    input  logic [31:0] A,
    output logic [31:0] RD
);

    // 1024 instructions x 32 bits = 4 KB instruction memory.
    logic [31:0] mem [0:1023];

    // A is a byte address.  A[31:2] is the instruction-word address.
    always_comb begin
        RD = mem[A[11:2]];
    end

    // Load program instructions from a hexadecimal text file.
    // Bare filename (no absolute path) so this works on any machine: add
    // tb/memfile.mem as a Vivado *simulation source* and xsim resolves it by
    // name from the simulation run directory.
    initial begin
         mem = '{default: 32'b0};
         $readmemh("memfile.mem", mem);
    end

endmodule
