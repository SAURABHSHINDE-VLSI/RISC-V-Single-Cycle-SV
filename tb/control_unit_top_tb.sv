module control_unit_top_tb;
    logic [6:0] Op;
    logic [2:0] funct3;
    logic [6:0] funct7;
    logic Zero;
    logic RegWrite, ALUSrc, MemWrite, ResultSrc, Branch;
    logic PCSrc;
    logic [1:0] ImmSrc;
    logic [2:0] ALUControl;
    int errors = 0;

    Control_Unit_Top dut (.*);

    task automatic check(input logic [6:0] opcode, input logic [2:0] funct3_value,
                         input logic [6:0] funct7_value, input logic expected_reg_write,
                         input logic expected_alu_src, input logic expected_mem_write,
                         input logic expected_result_src, input logic expected_branch,
                         input logic expected_pc_src,
                         input logic [1:0] expected_imm_src, input logic [2:0] expected_alu_control,
                         input string name);
        Op = opcode;
        funct3 = funct3_value;
        funct7 = funct7_value;
        #1;
           if ({RegWrite, ALUSrc, MemWrite, ResultSrc, Branch, PCSrc, ImmSrc, ALUControl} !==
            {expected_reg_write, expected_alu_src, expected_mem_write, expected_result_src,
               expected_branch, expected_pc_src, expected_imm_src, expected_alu_control}) begin
            $display("FAIL [%s]", name);
            errors++;
        end else $display("PASS [%s]", name);
    endtask

    initial begin
        Zero = 1'b0;
        check(7'b0110011, 3'b000, 7'b0000000, 1, 0, 0, 0, 0, 0, 2'b00, 3'b000, "add control");
        check(7'b0110011, 3'b000, 7'b0100000, 1, 0, 0, 0, 0, 0, 2'b00, 3'b001, "sub control");
        check(7'b0000011, 3'b010, 7'b0000000, 1, 1, 0, 1, 0, 0, 2'b00, 3'b000, "load control");
        check(7'b0100011, 3'b010, 7'b0000000, 0, 1, 1, 0, 0, 0, 2'b01, 3'b000, "store control");
        Zero = 1'b0;
        check(7'b1100011, 3'b000, 7'b0000000, 0, 0, 0, 0, 1, 0, 2'b10, 3'b001, "branch not taken");
        Zero = 1'b1;
        check(7'b1100011, 3'b000, 7'b0000000, 0, 0, 0, 0, 1, 1, 2'b10, 3'b001, "branch taken");
        if (errors == 0) $display("=== CONTROL UNIT TESTS PASSED ===");
        else $display("=== CONTROL UNIT TESTS FAILED: %0d error(s) ===", errors);
        $finish;
    end
endmodule
