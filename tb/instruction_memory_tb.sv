module instruction_memory_tb;

    logic [31:0] A;
    logic [31:0] RD;
    integer errors;

    instruction_memory dut (
        .A  (A),
        .RD (RD)
    );

    task check_instruction;
        input logic [31:0] address;
        input logic [31:0] expected_instruction;
        input string test_name;
        begin
            A = address;
            #10;

            if (RD === expected_instruction) begin
                $display("PASS [%s]: A=0x%08h RD=0x%08h", test_name, A, RD);
            end
            else begin
                $display("FAIL [%s]: A=0x%08h expected=0x%08h got=0x%08h",
                         test_name, A, expected_instruction, RD);
                errors = errors + 1;
            end
        end
    endtask

    initial begin
        A      = 32'h0000_0000;
        errors = 0;

        // instruction_memory loads these instructions from memfile.hex.
        // The testbench only reads and checks them.
        #1;
        check_instruction(32'h0000_0000, 32'h0050_0093, "instruction at PC = 0");
        check_instruction(32'h0000_0004, 32'h00A0_0113, "instruction at PC = 4");
        check_instruction(32'h0000_0008, 32'h0020_81B3, "instruction at PC = 8");
        check_instruction(32'h0000_000C, 32'h0000_006F, "instruction at PC = 12");

        if (errors == 0) begin
            $display("=== ALL TESTS PASSED ===");
        end
        else begin
            $display("=== TESTS FAILED: %0d error(s) ===", errors);
        end

        $finish;
    end

endmodule
