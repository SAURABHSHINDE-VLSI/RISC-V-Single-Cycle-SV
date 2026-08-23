`timescale 1ns / 1ps

module single_cycle_top_tb;

    logic clk = 0;
    logic rst;

    // Instantiate the top-level DUT.
    single_cycle_top dut (
        .clk(clk),
        .rst(rst)
    );

    // 10 ns clock period -> 100 MHz
    always #5 clk = ~clk;

    task automatic print_state(input string tag);
        $display("[%0t] %s | PC=0x%08h | IR=0x%08h | x1=0x%08h | x2=0x%08h | x5=0x%08h | x6=0x%08h | x7=0x%08h",
                 $time,
                 tag,
                 dut.PC_Top,
                 dut.RD_Instr,
                 dut.register_file.regs[1],
                 dut.register_file.regs[2],
                 dut.register_file.regs[5],
                 dut.register_file.regs[6],
                 dut.register_file.regs[7]);
    endtask

    initial begin
        rst = 1'b1;

        // Let the core stay in reset for a few cycles.
        repeat (3) @(posedge clk);
        rst = 1'b0;

        // Run long enough to reach every group (28-instruction program).
        repeat (32) begin
            @(posedge clk);
            #1;
            print_state("cycle");
        end

        // Final register dump — proves each instruction group worked.
        $display("\n=== FINAL REGISTER STATE ===");
        $display("GROUP 1  I-type ALU:");
        $display("  x1 =%0d (exp 5)   x2 =%0d (exp -8)  x3 =%0d (exp 1)   x4 =%0d (exp 7)",
                 $signed(dut.register_file.regs[1]), $signed(dut.register_file.regs[2]),
                 $signed(dut.register_file.regs[3]), $signed(dut.register_file.regs[4]));
        $display("  x5 =%0d (exp 2)   x6 =%0d (exp 20)  x7 =%0d (exp 2)   x8 =%0d (exp -4)",
                 $signed(dut.register_file.regs[5]), $signed(dut.register_file.regs[6]),
                 $signed(dut.register_file.regs[7]), $signed(dut.register_file.regs[8]));
        $display("GROUP 2  R-type:");
        $display("  x9 =%0d (exp 25)  x10=%0d (exp 15)  x11=%0d (exp 5)   x12=%0d (exp -3)",
                 $signed(dut.register_file.regs[9]),  $signed(dut.register_file.regs[10]),
                 $signed(dut.register_file.regs[11]), $signed(dut.register_file.regs[12]));
        $display("  x13=%0d (exp 2)   x14=%0d (exp 160) x15=%0d (exp 0)   x16=%0d (exp -1)  x17=%0d (exp 1)",
                 $signed(dut.register_file.regs[13]), $signed(dut.register_file.regs[14]),
                 $signed(dut.register_file.regs[15]), $signed(dut.register_file.regs[16]),
                 $signed(dut.register_file.regs[17]));
        $display("GROUP 3  Memory:      x18=%0d (exp 25, loaded back from mem[0])",
                 $signed(dut.register_file.regs[18]));
        $display("GROUP 4  Branches:    x19=%0d x20=%0d (BOTH exp 0 - traps skipped by taken branches)",
                 $signed(dut.register_file.regs[19]), $signed(dut.register_file.regs[20]));
        $display("GROUP 5  jal:         x21=0x%08h (exp 0x00000068 - linked PC+4)   x22=%0d (exp 0 - trap skipped)",
                 dut.register_file.regs[21], $signed(dut.register_file.regs[22]));

        $display("\n=== single_cycle_top TB FINISHED ===");
        $finish;
    end

endmodule
