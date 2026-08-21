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

        // Run for a number of cycles and inspect behavior.
        repeat (20) begin
            @(posedge clk);
            #1;
            print_state("cycle");
        end

        $display("\n=== single_cycle_top TB FINISHED ===");
        $finish;
    end

endmodule
