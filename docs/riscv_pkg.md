# riscv_pkg — Shared Types Package

`riscv_pkg` is not a hardware block; it is the **shared dictionary** every other
module imports with `import riscv_pkg::*;`. Instead of scattering "magic
numbers" (like `2'b10` or `4'b1000`) across the design, we give them **names**
(`ALU_SRA`, `IMM_J`, …) in one file. If a name and its encoding are defined
here, every module automatically agrees on what it means.

> **In plain words:** think of this file as the *legend* on a map. The datapath
> modules are the map itself; this package just says "this symbol means that."

## Why a package at all?

Without a shared package, two modules can disagree. The Control Unit might think
`result_src = 2'b10` means "PC+4" while the top-level mux thinks it means
something else — and the compiler would never catch it. By defining the codes
**once** as enums and structs, a mismatch becomes a *type error* instead of a
silent bug.

```
                 ┌────────────────────────┐
                 │       riscv_pkg         │   (this file — no gates, just names)
                 │  alu_op_t   imm_sel_t   │
                 │  ctrl_t     decoded_… │
                 └────────────┬───────────┘
        import riscv_pkg::*;  │  (everyone reads from the same dictionary)
        ┌───────────┬─────────┼──────────┬─────────────┐
        ▼           ▼         ▼          ▼             ▼
      ALU     alu_decoder  sign_extend  control_…   single_cycle_top
```

## What it defines

The package contains four types. Two are **enums** (a name for each numeric
code) and two are **packed structs** (a bundle of named 1-bit/multi-bit fields
that travels through the datapath as a single vector).

### 1. `alu_op_t` — which operation the ALU performs

A 4-bit enum. It is the single source of truth for the `ALUControl` encoding, so
the ALU Control (`alu_decoder`) can output it directly and the `ALU` can `case`
on it with no re-mapping.

| Name      | Code   | Used by                          |
|-----------|--------|----------------------------------|
| `ALU_ADD` | `0000` | `lw`, `sw`, `addi`, `add`        |
| `ALU_SUB` | `0001` | `beq`, `bne`, `sub`              |
| `ALU_AND` | `0010` | `and`, `andi`                    |
| `ALU_OR`  | `0011` | `or`, `ori`                      |
| `ALU_XOR` | `0100` | `xor`, `xori`                    |
| `ALU_SLT` | `0101` | `slt` (signed set-less-than)     |
| `ALU_SLL` | `0110` | `sll`, `slli` (shift left logical)   |
| `ALU_SRL` | `0111` | `srl`, `srli` (shift right logical)  |
| `ALU_SRA` | `1000` | `sra`, `srai` (shift right arithmetic) |

> **Why 4 bits?** With 9 operations we need at least 4 bits (3 bits only cover
> 8 codes). This is why `ALUControl` is `[3:0]` everywhere, not `[2:0]`.

### 2. `imm_sel_t` — which immediate format to build

A 3-bit enum that tells the `sign_extend` module how to reassemble the
scattered immediate bits of an instruction.

| Name    | Code  | Instruction format | Example instructions |
|---------|-------|--------------------|----------------------|
| `IMM_I` | `000` | I-type             | `addi`, `lw`, `jalr` |
| `IMM_S` | `001` | S-type             | `sw`                 |
| `IMM_B` | `010` | B-type             | `beq`, `bne`         |
| `IMM_U` | `011` | U-type             | `lui`, `auipc` *(not built yet)* |
| `IMM_J` | `100` | J-type             | `jal`                |

> **Why 3 bits?** `IMM_J` is code `100`, which needs 3 bits. That is why
> `ImmSrc`/`imm_sel` is `[2:0]` throughout the design, not `[1:0]`.

### 3. `ctrl_t` — the control-signal bundle

Everything the Control Unit decides for one instruction, packed into a single
struct. Bundling avoids a wide, error-prone port list on every module.

| Field         | Width | Meaning |
|---------------|-------|---------|
| `reg_write`   | 1     | Write the result back into the register file |
| `alu_src`     | 1     | ALU operand B: `0` = `rs2`, `1` = immediate |
| `mem_write`   | 1     | Store to data memory (`sw`) |
| `mem_read`    | 1     | Load from data memory (`lw`) |
| `branch`      | 1     | Instruction is a branch |
| `jump`        | 1     | Instruction is an unconditional jump (`jal`) |
| `result_src`  | 2     | Write-back source: `00`=ALU, `01`=memory, `10`=PC+4 |
| `imm_sel`     | 3     | Immediate format (`imm_sel_t`) |
| `alu_ctrl`    | 4     | ALU operation (`alu_op_t`) |

> **In plain words:** `ctrl_t` is the instruction's "to-do list" for the
> datapath — one tidy envelope that says *write the register? use the immediate?
> touch memory? which ALU op?* — filled in fresh every cycle.

### 4. `decoded_instr_t` — the chopped-up instruction

The raw 32-bit instruction split into its named fields, so the rest of the
design never has to slice bit ranges by hand.

| Field    | Width | Instruction bits |
|----------|-------|------------------|
| `rs1`    | 5     | `[19:15]` |
| `rs2`    | 5     | `[24:20]` |
| `rd`     | 5     | `[11:7]`  |
| `opcode` | 7     | `[6:0]`   |
| `funct3` | 3     | `[14:12]` |
| `funct7` | 7     | `[31:25]` |

## Design notes

- **Single source of truth.** `alu_op_t` is defined here and reused by both
  `alu_decoder` (producer) and `alu` (consumer), so their encodings can never
  drift apart.
- **Forward-looking fields.** `jump` and `result_src = 2'b10` (PC+4) were
  reserved here before `jal` existed, which is why adding `jal` needed **zero**
  datapath rewiring — the wires were already named and routed.
- **`IMM_U` is defined but not yet implemented.** `lui`/`auipc` are out of the
  current subset; `sign_extend` leaves that case as `x` on purpose. The name is
  kept so the enum ordering stays stable for later.
- **Enums are cast at the boundary.** The leaf decoders compute plain
  `logic` vectors; `control_unit_top` casts them into the enum types
  (`imm_sel_t'(...)`, `alu_op_t'(...)`) exactly once, where the bundle is built.

## Related documentation

- Consumers of these types: [ALU](alu.md), [ALU Decoder](alu_decoder.md),
  [Sign Extend](sign_extend.md), [Control Unit (top)](control_unit_top.md),
  [Single-Cycle Top](single_cycle_top.md).
- See the per-instruction walkthroughs in
  [`instructions_type/`](../instructions_type/README.md) to watch these signals
  take real values.

> This module is a pure type/constant package. It has no ports, no testbench,
> and no synthesized hardware of its own, so there are no waveform or schematic
> images for it.
