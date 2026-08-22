import riscv_pkg::*;

module control_unit_top_tb;
    decoded_instr_t dec;
    logic           Zero;
    ctrl_t          ctrl;
    logic           PCSrc;
    int errors = 0;

    Control_Unit_Top dut (.dec(dec), .Zero(Zero), .ctrl(ctrl), .PCSrc(PCSrc));

    task automatic check(input logic [6:0] opcode, input logic [2:0] funct3_value,
                         input logic [6:0] funct7_value, input logic expected_reg_write,
                         input logic expected_alu_src, input logic expected_mem_write,
                         input logic [1:0] expected_result_src, input logic expected_branch,
                         input logic expected_pc_src,
                         input imm_sel_t expected_imm_sel, input alu_op_t expected_alu_ctrl,
                         input string name);
        dec = '0;
        dec.opcode = opcode;
        dec.funct3 = funct3_value;
        dec.funct7 = funct7_value;
        #1;
        if ({ctrl.reg_write, ctrl.alu_src, ctrl.mem_write, ctrl.result_src, ctrl.branch,
             PCSrc, ctrl.imm_sel, ctrl.alu_ctrl} !==
            {expected_reg_write, expected_alu_src, expected_mem_write, expected_result_src,
             expected_branch, expected_pc_src, expected_imm_sel, expected_alu_ctrl}) begin
            $display("FAIL [%s]", name);
            errors++;
        end else $display("PASS [%s]", name);
    endtask

    initial begin
        Zero = 1'b0;
        //     opcode       funct3   funct7      RW AS MW RS   BR PC  imm_sel alu_ctrl   name
        check(7'b0110011, 3'b000, 7'b0000000, 1, 0, 0, 2'b00, 0, 0, IMM_I, ALU_ADD, "add control");
        check(7'b0110011, 3'b000, 7'b0100000, 1, 0, 0, 2'b00, 0, 0, IMM_I, ALU_SUB, "sub control");
        check(7'b0000011, 3'b010, 7'b0000000, 1, 1, 0, 2'b01, 0, 0, IMM_I, ALU_ADD, "load control");
        check(7'b0100011, 3'b010, 7'b0000000, 0, 1, 1, 2'b00, 0, 0, IMM_S, ALU_ADD, "store control");
        Zero = 1'b0;
        check(7'b1100011, 3'b000, 7'b0000000, 0, 0, 0, 2'b00, 1, 0, IMM_B, ALU_SUB, "branch not taken");
        Zero = 1'b1;
        check(7'b1100011, 3'b000, 7'b0000000, 0, 0, 0, 2'b00, 1, 1, IMM_B, ALU_SUB, "branch taken");
        if (errors == 0) $display("=== CONTROL UNIT TESTS PASSED ===");
        else $display("=== CONTROL UNIT TESTS FAILED: %0d error(s) ===", errors);
        $finish;
    end
endmodule
