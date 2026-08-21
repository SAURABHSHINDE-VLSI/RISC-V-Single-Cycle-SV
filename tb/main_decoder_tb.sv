module main_decoder_tb;
    logic [6:0] Op;
    logic Zero;
    logic RegWrite, ALUSrc, MemWrite, ResultSrc, Branch, PCSrc;
    logic [1:0] ImmSrc, ALUOp;
    int errors = 0;

    Main_Decoder dut (.*);

    task automatic check(input logic [6:0] opcode, input logic zero_value,
                         input logic expected_reg_write, input logic expected_alu_src,
                         input logic expected_mem_write, input logic expected_result_src,
                         input logic [1:0] expected_imm_src, input logic [1:0] expected_alu_op,
                         input logic expected_branch, input logic expected_pc_src,
                         input string name);
        Op = opcode;
        Zero = zero_value;
        #1;
        if ({RegWrite, ALUSrc, MemWrite, ResultSrc, ImmSrc, ALUOp, Branch, PCSrc} !==
            {expected_reg_write, expected_alu_src, expected_mem_write, expected_result_src,
             expected_imm_src, expected_alu_op, expected_branch, expected_pc_src}) begin
            $display("FAIL [%s]", name);
            errors++;
        end else $display("PASS [%s]", name);
    endtask

    initial begin
        check(7'b0110011, 1'b0, 1, 0, 0, 0, 2'b00, 2'b10, 0, 0, "R-type");
        check(7'b0000011, 1'b0, 1, 1, 0, 1, 2'b00, 2'b00, 0, 0, "load");
        check(7'b0100011, 1'b0, 0, 1, 1, 0, 2'b01, 2'b00, 0, 0, "store");
        check(7'b1100011, 1'b0, 0, 0, 0, 0, 2'b10, 2'b01, 1, 0, "branch not taken");
        check(7'b1100011, 1'b1, 0, 0, 0, 0, 2'b10, 2'b01, 1, 1, "branch taken");
        if (errors == 0) $display("=== MAIN DECODER TESTS PASSED ===");
        else $display("=== MAIN DECODER TESTS FAILED: %0d error(s) ===", errors);
        $finish;
    end
endmodule
