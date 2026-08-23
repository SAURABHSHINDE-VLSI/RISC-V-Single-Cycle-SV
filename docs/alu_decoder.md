# ALU Decoder

The ALU Decoder is the **second level** of the control unit. The
[Main Decoder](main_decoder.md) already narrowed the instruction down to a
coarse 2-bit `ALUOp`; this module turns `ALUOp` (plus `funct3`, `funct7`, and
`op`) into the exact 4-bit `ALUControl` code the [ALU](alu.md) understands.

> **In plain words:** the Main Decoder says "this is an arithmetic instruction";
> the ALU Decoder says *which* arithmetic — add? subtract? shift? and? The
> `funct3`/`funct7` bits are the fine print that pins it down.

## Interface

| Port         | Direction | Width | Description |
|--------------|-----------|-------|-------------|
| `ALUOp`      | input     | 2     | Coarse class from the Main Decoder |
| `funct3`     | input     | 3     | Instruction bits `[14:12]` — selects the operation |
| `funct7`     | input     | 7     | Instruction bits `[31:25]` — add/sub & srl/sra selector |
| `op`         | input     | 7     | Opcode `[6:0]` — separates real R-type from I-type |
| `ALUControl` | output    | 4     | ALU operation code (`alu_op_t` in [riscv_pkg](riscv_pkg.md)) |

## How it decodes

```
   ALUOp = 00  ───────────────────────────────►  ALU_ADD
      (lw / sw / jal: address add or don't-care)

   ALUOp = 01  ───────────────────────────────►  ALU_SUB
      (beq / bne: subtract so Zero reports equality)

   ALUOp = 10  ──► look at funct3 ┐
      (R-type & I-type ALU)       │
                                  ▼
        funct3 = 000 ─► add OR sub  ── decided by {op[5], funct7[5]}
        funct3 = 001 ─► ALU_SLL
        funct3 = 010 ─► ALU_SLT
        funct3 = 100 ─► ALU_XOR
        funct3 = 101 ─► srl OR sra ── decided by funct7[5]
        funct3 = 110 ─► ALU_OR
        funct3 = 111 ─► ALU_AND
```

### `ALUOp = 10` funct3 map

| `funct3` | Operation | Chosen `ALUControl` | Selector detail |
|----------|-----------|---------------------|-----------------|
| `000`    | add / sub | `ALU_SUB` if `{op[5],funct7[5]}==11`, else `ALU_ADD` | only a *real* R-type sub becomes SUB |
| `001`    | shift left logical | `ALU_SLL` | — |
| `010`    | set less than | `ALU_SLT` | signed comparison |
| `100`    | xor | `ALU_XOR` | — |
| `101`    | shift right | `ALU_SRA` if `funct7[5]`, else `ALU_SRL` | arithmetic vs logical |
| `110`    | or  | `ALU_OR` | — |
| `111`    | and | `ALU_AND` | — |

## The two tricky selectors

Two operations share a `funct3` with another operation, so an extra bit breaks
the tie. These are the subtle parts worth understanding.

- **add vs sub (`funct3 = 000`).** Both `add` and `sub` use `funct3 = 000`.
  Only a genuine R-type subtract should become `ALU_SUB`. The guard
  `{op[5], funct7[5]} == 2'b11` requires **both** the R-type opcode bit
  (`op[5]=1`) **and** the sub marker (`funct7[5]=1`). This matters because
  `addi`'s 12-bit immediate can accidentally place a `1` in the `funct7[5]`
  position — but `addi` has `op[5]=0`, so it correctly stays `ALU_ADD`.

- **srl vs sra (`funct3 = 101`).** Here `funct7[5]` alone selects arithmetic
  (`sra`/`srai`) vs logical (`srl`/`srli`). Unlike add/sub, this is **not**
  gated on `op[5]`, because the immediate shifts (`srli`/`srai`) legitimately
  use `funct7[5]` as their selector too.

> **Why the difference?** For shifts, `funct7[5]` is *architecturally* part of
> the immediate-shift encoding, so trusting it directly is correct. For add/sub,
> `funct7` is not part of the I-type immediate's meaning, so we must also check
> the opcode to avoid a false "subtract."

## Design notes

- **`ALUControl` is 4 bits.** The design supports 9 ALU operations, which needs
  4 bits. See `alu_op_t` in [riscv_pkg](riscv_pkg.md).
- **Outputs named constants, not raw numbers.** The `case` returns `ALU_ADD`,
  `ALU_SRA`, etc., so this decoder and the ALU can never disagree on encodings.
- **Purely combinational.** One `always_comb` block, no state — the output is a
  direct function of the inputs.

## Verification

Directed testbench: `tb/alu_decoder_tb.sv`. It drives representative
`ALUOp`/`funct3`/`funct7`/`op` combinations and checks `ALUControl`.

| # | Scenario | Inputs | Expected `ALUControl` |
|---|----------|--------|-----------------------|
| 1 | Load/store address add | `ALUOp=00` | `ALU_ADD` |
| 2 | Branch compare | `ALUOp=01` | `ALU_SUB` |
| 3 | R-type add | `ALUOp=10`, `funct3=000`, `op[5]=1`, `funct7[5]=0` | `ALU_ADD` |
| 4 | R-type sub | `ALUOp=10`, `funct3=000`, `op[5]=1`, `funct7[5]=1` | `ALU_SUB` |
| 5 | `addi` (immediate) | `ALUOp=10`, `funct3=000`, `op[5]=0`, `funct7[5]=1` | `ALU_ADD` (not sub!) |
| 6 | shift right logical | `ALUOp=10`, `funct3=101`, `funct7[5]=0` | `ALU_SRL` |
| 7 | shift right arithmetic | `ALUOp=10`, `funct3=101`, `funct7[5]=1` | `ALU_SRA` |
| 8 | and / or / xor / slt / sll | `ALUOp=10`, respective `funct3` | matching op |

All checks pass in Vivado xsim (Behavioral Simulation):

```
=== ALL TESTS PASSED ===
```

### Console output

![Console output showing all ALU-decoder tests passing](images/alu_decoder/console_pass.png)

### Waveform

The waveform sweeps `funct3` under `ALUOp=10` and shows `ALUControl` selecting
the matching operation, plus the add/sub and srl/sra tie-break cases.

![ALU decoder waveform across all test cases](images/alu_decoder/waveform.png)

### Synthesized hardware view

Vivado's RTL schematic — the nested `ALUOp`/`funct3` mux tree producing
`ALUControl`.

![Synthesized ALU decoder schematic](images/alu_decoder/schematic.png)

## Related documentation

- Parent: [Control Unit (top)](control_unit_top.md)
- Sibling: [Main Decoder](main_decoder.md)
- Consumer: [ALU](alu.md)
- Types: [riscv_pkg](riscv_pkg.md)
- In action: [R-type](../datapath_example/R-type.md),
  [I-type](../datapath_example/I-type.md)
