module alu_decoder_tb;
    logic [1:0] ALUOp;
    logic [2:0] funct3;
    logic [6:0] funct7;
    logic [6:0] op;
    logic [2:0] ALUControl;
    int errors = 0;

    ALU_Decoder dut (.*);

    task automatic check(input logic [1:0] alu_op, input logic [2:0] funct3_value,
                         input logic [6:0] funct7_value, input logic [6:0] opcode,
                         input logic [2:0] expected, input string name);
        ALUOp = alu_op;
        funct3 = funct3_value;
        funct7 = funct7_value;
        op = opcode;
        #1;
        if (ALUControl !== expected) begin
            $display("FAIL [%s]: expected %03b, got %03b", name, expected, ALUControl);
            errors++;
        end else $display("PASS [%s]", name);
    endtask

    initial begin
        check(2'b00, 3'b000, 7'b0000000, 7'b0000011, 3'b000, "load add");
        check(2'b01, 3'b000, 7'b0000000, 7'b1100011, 3'b001, "branch subtract");
        check(2'b10, 3'b000, 7'b0000000, 7'b0110011, 3'b000, "R-type add");
        check(2'b10, 3'b000, 7'b0100000, 7'b0110011, 3'b001, "R-type subtract");
        check(2'b10, 3'b010, 7'b0000000, 7'b0110011, 3'b101, "slt");
        check(2'b10, 3'b110, 7'b0000000, 7'b0110011, 3'b011, "or");
        check(2'b10, 3'b111, 7'b0000000, 7'b0110011, 3'b010, "and");
        if (errors == 0) $display("=== ALU DECODER TESTS PASSED ===");
        else $display("=== ALU DECODER TESTS FAILED: %0d error(s) ===", errors);
        $finish;
    end
endmodule
