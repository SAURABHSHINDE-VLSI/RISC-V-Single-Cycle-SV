import riscv_pkg::*;

module Sign_Extend (
    input  logic [31:0] In,
    input  imm_sel_t    ImmSrc,      // immediate format select (riscv_pkg)
    output logic [31:0] Imm_Ext
);

    always_comb begin
        case (ImmSrc)
            IMM_I:   Imm_Ext = {{20{In[31]}}, In[31:20]};                               // I-type
            IMM_S:   Imm_Ext = {{20{In[31]}}, In[31:25], In[11:7]};                     // S-type
            IMM_B:   Imm_Ext = {{19{In[31]}}, In[31], In[7], In[30:25], In[11:8], 1'b0};// B-type
            IMM_J:   Imm_Ext = {{11{In[31]}}, In[31], In[19:12], In[20], In[30:21], 1'b0};// J-type (jal)
            default: Imm_Ext = 32'bx;   // IMM_U not implemented in single-cycle yet
        endcase
    end

endmodule
