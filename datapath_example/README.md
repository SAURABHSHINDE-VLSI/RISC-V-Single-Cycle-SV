# Datapath Examples — Learning by Tracing Real Instructions

This folder teaches the processor **one instruction format at a time**. Instead
of describing the hardware abstractly, each page picks a *real* instruction from
the demo program (`tb/memfile.mem`), decodes its bits, and walks the value
through the datapath step by step — the same "follow the data" style used to
learn `addi` and `jal`.

> **How to read these:** pick a format below, then follow the numbered steps.
> Each step shows which wires are active and what value they carry. ASCII arrows
> mark the path the data actually takes for that instruction.

## The five RV32I formats in this project

| Format | Meaning | Example instruction | Page |
|--------|---------|---------------------|------|
| **R-type** | register OP register | `add x9, x1, x6` | [R-type.md](R-type.md) |
| **I-type** | register OP immediate (and loads) | `addi x1, x0, 5`, `lw x18, 0(x0)` | [I-type.md](I-type.md) |
| **S-type** | store to memory | `sw x9, 0(x0)` | [S-type.md](S-type.md) |
| **B-type** | conditional branch | `beq`/`bne x1, x2, +8` | [B-type.md](B-type.md) |
| **J-type** | unconditional jump-and-link | `jal x21, +8` | [J-type.md](J-type.md) |

U-type (`lui`/`auipc`) is defined in the type system but **not implemented** in
this single-cycle subset, so it has no page yet.

## The 32-bit instruction, at a glance

Every instruction is 32 bits. The formats differ in how they use those bits —
especially where the immediate lives.

```
   bit: 31            25 24   20 19   15 14  12 11    7 6      0
       ┌────────────────┬───────┬───────┬──────┬───────┬────────┐
   R:  │     funct7     │  rs2  │  rs1  │funct3│  rd   │ opcode │
       ├────────────────┴───────┼───────┼──────┼───────┼────────┤
   I:  │      imm[11:0]          │  rs1  │funct3│  rd   │ opcode │
       ├────────────────┬───────┼───────┼──────┼───────┼────────┤
   S:  │   imm[11:5]    │  rs2  │  rs1  │funct3│imm[4:0]│ opcode │
       ├──┬─────────────┼───────┼───────┼──────┼──────┬─┼────────┤
   B:  │12│  imm[10:5]  │  rs2  │  rs1  │funct3│imm4:1│11│ opcode │
       ├──┴─────────────┴───────┴───┬───┴──────┴──────┴─┴────────┤
   J:  │20│    imm[10:1]    │11│ imm[19:12] │      rd     │opcode │
       └────────────────────────────┴───────────────────────────┘
```

> **Key idea:** `opcode` (and, for some, `funct3`/`funct7`) tells the control
> unit *what* the instruction is; the [Sign Extend](../docs/sign_extend.md)
> module knows how to rebuild the immediate for each format.

## Related documentation

- The blocks these examples flow through are documented in [`../docs/`](../docs).
- Start with the full picture: [Single-Cycle Top](../docs/single_cycle_top.md).
- The exact demo program: [`../tb/memfile.mem`](../tb/memfile.mem).
