`timescale 1ns / 1ps

// -----------------------------------------------------------------------------
// data_memory_tb
// -----------------------------------------------------------------------------
// Testbench for Data_Memory.  It verifies:
//   1. The initial value at byte address 112 (memory word 28).
//   2. A clocked store to byte address 16 (memory word 4).
//   3. A later asynchronous load from the same address.
// -----------------------------------------------------------------------------
module data_memory_tb;

    // Signals that connect the testbench to the design under test (dut).
    logic        clk;
    logic        WE;
    logic [31:0] A;
    logic [31:0] WD;
    logic [31:0] RD;

    // Instantiate the data-memory module being tested.
    Data_Memory dut (
        .clk (clk),
        .WE  (WE),
        .A   (A),
        .WD  (WD),
        .RD  (RD)
    );

    // Generate a 10 ns clock period: rising edges occur at 5, 15, 25 ns, etc.
    always #5 clk = ~clk;

    initial begin
        // Start with a read from the initialized memory location.
        clk = 1'b0;
        WE  = 1'b0;
        A   = 32'd112;
        WD  = 32'd0;

        // Allow combinational read data to settle, then check mem[28].
        #1;
        if (RD !== 32'h0000_0020)
            $fatal(1, "Initial read failed: RD = %h", RD);

        // Store 0x12345678 at byte address 16.  Since a word is four bytes,
        // the module converts this to word index 16 / 4 = 4.
        A  = 32'd16;
        WD = 32'h1234_5678;
        WE = 1'b1;
        // Wait for the rising edge that commits the synchronous write.
        @(posedge clk);
        #1;
        WE = 1'b0;

        // With WE low, RD is the asynchronously read value at address 16.
        if (RD !== 32'h1234_5678)
            $fatal(1, "Store/load failed: RD = %h", RD);

        $display("PASS: Data_Memory read and write tests completed.");
        $finish;
    end

endmodule
