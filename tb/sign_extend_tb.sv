module sign_extend_tb;
    logic [31:0] In;
    logic [1:0] ImmSrc;
    logic [31:0] Imm_Ext;
    int errors = 0;

    Sign_Extend dut (.In(In), .ImmSrc(ImmSrc), .Imm_Ext(Imm_Ext));

    task automatic check(input logic [31:0] instruction, input logic [1:0] source,
                         input logic [31:0] expected, input string name);
        In = instruction;
        ImmSrc = source;
        #1;
        if (Imm_Ext !== expected) begin
            $display("FAIL [%s]: expected 0x%08h, got 0x%08h", name, expected, Imm_Ext);
            errors++;
        end else begin
            $display("PASS [%s]", name);
        end
    endtask

    initial begin
        check(32'h00500093, 2'b00, 32'h00000005, "I-type positive");
        check(32'hFFF00093, 2'b00, 32'hFFFFFFFF, "I-type negative");
        check(32'hFE208FA3, 2'b01, 32'hFFFFFFFF, "S-type negative");
        check(32'h00000063, 2'b10, 32'h00000000, "B-type zero");
        check(32'h00000163, 2'b10, 32'h00000002, "B-type positive");
        if (errors == 0) $display("=== SIGN EXTEND TESTS PASSED ===");
        else $display("=== SIGN EXTEND TESTS FAILED: %0d error(s) ===", errors);
        $finish;
    end
endmodule
