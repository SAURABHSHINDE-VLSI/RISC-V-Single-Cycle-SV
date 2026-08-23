module main_decoder_tb;
    logic [6:0] Op;
    logic [2:0] funct3;
    logic Zero;
    logic RegWrite, ALUSrc, MemWrite, Branch, Jump, PCSrc;
    logic [1:0] ResultSrc;
    logic [2:0] ImmSrc;
    logic [1:0] ALUOp;
    int errors = 0;

    Main_Decoder dut (.*);

    task automatic check(input logic [6:0] opcode, input logic [2:0] funct3_value,
                         input logic zero_value,
                         input logic expected_reg_write, input logic expected_alu_src,
                         input logic expected_mem_write, input logic [1:0] expected_result_src,
                         input logic [2:0] expected_imm_src, input logic [1:0] expected_alu_op,
                         input logic expected_branch, input logic expected_jump,
                         input logic expected_pc_src, input string name);
        Op = opcode;
        funct3 = funct3_value;
        Zero = zero_value;
        #1;
        if ({RegWrite, ALUSrc, MemWrite, ResultSrc, ImmSrc, ALUOp, Branch, Jump, PCSrc} !==
            {expected_reg_write, expected_alu_src, expected_mem_write, expected_result_src,
             expected_imm_src, expected_alu_op, expected_branch, expected_jump, expected_pc_src}) begin
            $display("FAIL [%s]", name);
            errors++;
        end else $display("PASS [%s]", name);
    endtask

    initial begin
        //     opcode      funct3  Zero  RW AS MW RS     Imm    ALUOp  Br Jmp PC   name
        check(7'b0110011, 3'b000, 1'b0, 1, 0, 0, 2'b00, 3'b000, 2'b10, 0, 0, 0, "R-type");
        check(7'b0000011, 3'b010, 1'b0, 1, 1, 0, 2'b01, 3'b000, 2'b00, 0, 0, 0, "load");
        check(7'b0100011, 3'b010, 1'b0, 0, 1, 1, 2'b00, 3'b001, 2'b00, 0, 0, 0, "store");
        check(7'b0010011, 3'b000, 1'b0, 1, 1, 0, 2'b00, 3'b000, 2'b10, 0, 0, 0, "I-type ALU (addi/andi/slli/...)");

        // beq (funct3=000): branch when equal (Zero=1)
        check(7'b1100011, 3'b000, 1'b0, 0, 0, 0, 2'b00, 3'b010, 2'b01, 1, 0, 0, "beq not taken (Zero=0)");
        check(7'b1100011, 3'b000, 1'b1, 0, 0, 0, 2'b00, 3'b010, 2'b01, 1, 0, 1, "beq taken (Zero=1)");

        // bne (funct3=001): branch when NOT equal (Zero=0) — the opposite of beq
        check(7'b1100011, 3'b001, 1'b1, 0, 0, 0, 2'b00, 3'b010, 2'b01, 1, 0, 0, "bne not taken (Zero=1, equal)");
        check(7'b1100011, 3'b001, 1'b0, 0, 0, 0, 2'b00, 3'b010, 2'b01, 1, 0, 1, "bne taken (Zero=0, not equal)");

        // jal: unconditional jump, writes PC+4 (ResultSrc=10), J-immediate (ImmSrc=100)
        check(7'b1101111, 3'b000, 1'b0, 1, 0, 0, 2'b10, 3'b100, 2'b00, 0, 1, 1, "jal");

        if (errors == 0) $display("=== MAIN DECODER TESTS PASSED ===");
        else $display("=== MAIN DECODER TESTS FAILED: %0d error(s) ===", errors);
        $finish;
    end
endmodule
