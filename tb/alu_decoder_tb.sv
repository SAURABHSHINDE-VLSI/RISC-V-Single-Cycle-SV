import riscv_pkg::*;

module alu_decoder_tb;
    logic [1:0] ALUOp;
    logic [2:0] funct3;
    logic [6:0] funct7;
    logic [6:0] op;
    logic [3:0] ALUControl;
    int errors = 0;

    ALU_Decoder dut (.*);

    task automatic check(input logic [1:0] alu_op, input logic [2:0] funct3_value,
                         input logic [6:0] funct7_value, input logic [6:0] opcode,
                         input logic [3:0] expected, input string name);
        ALUOp = alu_op;
        funct3 = funct3_value;
        funct7 = funct7_value;
        op = opcode;
        #1;
        if (ALUControl !== expected) begin
            $display("FAIL [%s]: expected %04b, got %04b", name, expected, ALUControl);
            errors++;
        end else $display("PASS [%s]", name);
    endtask

    initial begin
        // --- original coverage (unchanged behaviour) ---
        check(2'b00, 3'b000, 7'b0000000, 7'b0000011, ALU_ADD, "load add");
        check(2'b01, 3'b000, 7'b0000000, 7'b1100011, ALU_SUB, "branch subtract");
        check(2'b10, 3'b000, 7'b0000000, 7'b0110011, ALU_ADD, "R-type add");
        check(2'b10, 3'b000, 7'b0100000, 7'b0110011, ALU_SUB, "R-type subtract");
        check(2'b10, 3'b010, 7'b0000000, 7'b0110011, ALU_SLT, "slt");
        check(2'b10, 3'b110, 7'b0000000, 7'b0110011, ALU_OR,  "or");
        check(2'b10, 3'b111, 7'b0000000, 7'b0110011, ALU_AND, "and");

        // --- step 2: the new operations ---
        check(2'b10, 3'b100, 7'b0000000, 7'b0110011, ALU_XOR, "xor");
        check(2'b10, 3'b001, 7'b0000000, 7'b0110011, ALU_SLL, "sll");
        check(2'b10, 3'b101, 7'b0000000, 7'b0110011, ALU_SRL, "srl (logical)");
        check(2'b10, 3'b101, 7'b0100000, 7'b0110011, ALU_SRA, "sra (arithmetic)");

        // --- subtle cases (validate the guards) ---
        // I-type shift: op[5]=0 but funct7[5]=1 must STILL pick SRA (srai)
        check(2'b10, 3'b101, 7'b0100000, 7'b0010011, ALU_SRA, "srai (I-type -> SRA)");
        // addi with a negative immediate sets funct7[5]=1, but op[5]=0 -> must stay ADD
        check(2'b10, 3'b000, 7'b0100000, 7'b0010011, ALU_ADD, "addi (not mistaken for sub)");

        if (errors == 0) $display("=== ALU DECODER TESTS PASSED ===");
        else $display("=== ALU DECODER TESTS FAILED: %0d error(s) ===", errors);
        $finish;
    end
endmodule
