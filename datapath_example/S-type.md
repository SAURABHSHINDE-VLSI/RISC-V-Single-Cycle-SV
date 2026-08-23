# S-type — store to memory

An **S-type** instruction writes a register value **into** data memory. It is
the mirror image of a load: the ALU still computes an address, but instead of
reading, the register value is written there. Because nothing is written **back**
into the register file, S-type has no `rd`.

> **In plain words:** "take what's in this register and park it in memory at this
> address." The register file only reads here; the writing happens in memory.

## Which instructions are S-type?

Opcode `0100011`; `funct3` picks the size. In this subset: **`sw`** (store word).
(`sb`/`sh` byte/half stores are not implemented.)

## Bit layout

The immediate is **split** into two chunks so the `rs1`/`rs2` fields can stay in
their usual positions:

```
   31        25 24   20 19   15 14   12 11        7 6        0
  ┌────────────┬───────┬───────┬───────┬───────────┬──────────┐
  │ imm[11:5]  │  rs2  │  rs1  │funct3 │  imm[4:0] │  opcode  │
  │  7 bits    │ 5 bits│ 5 bits│ 3 bits│   5 bits  │  7 bits  │
  └────────────┴───────┴───────┴───────┴───────────┴──────────┘
```

- `rs1` = base address register
- `rs2` = the data to store
- immediate = byte offset, rebuilt as `{imm[11:5], imm[4:0]}` and sign-extended

## Example we will trace: `sw x9, 0(x0)`

From the demo program (Group 3). Earlier, `add x9, x1, x6` put `25` in `x9`. This
store parks that `25` into memory address `0`.

Machine code: **`0x00902023`**

### Step 1 — decode

```
   0x00902023 = 0000000 01001 00000 010 00000 0100011
                └imm11:5┘└rs2=9┘└rs1=0┘└f3┘└im4:0┘└opcode┘
```

| Field  | Value        | Meaning |
|--------|--------------|---------|
| opcode | `0100011`    | store |
| imm    | `0000000` + `00000` = 0 | byte offset |
| rs2    | `01001` = 9 (`x9`) | **data** to store (=25) |
| rs1    | `00000` (`x0`) | base address (=0) |
| funct3 | `010`        | `sw` (word) |

> **Note there is no `rd`.** Those bits (`[11:7]`) are reused to hold `imm[4:0]`.

### Step 2 — control signals

| Signal | Value | Effect |
|--------|-------|--------|
| `RegWrite` | `0` | **nothing** is written back to the register file |
| `ALUSrc` | `1` | ALU adds base + immediate to form the address |
| `ImmSrc` | `IMM_S` | build an S-type immediate |
| `ALUOp` | `00` → `ALU_ADD` | address = `rs1 + imm` |
| `MemWrite` | `1` | **write** the data into memory this cycle |
| `ResultSrc` | `00` | (don't-care — no write-back happens) |

### Step 3 — data flow

```
   x0 (=0) ─► RD1 ─► A ┐
                       ▼
   imm=0 ─► [MUX=1] ─► B ─►┌──────┐
                    ALU_ADD│ ALU  │─► addr = 0 ─────┐
                           │ add  │                 ▼
                           └──────┘          ┌──────────────┐
                                             │ Data Memory  │
   x9 (=25) ─► RD2 ─────────────────► WD ───►│  mem[0] ⇐ 25 │  (MemWrite=1)
                                             └──────────────┘
                                     RegWrite=0 → register file NOT written
```

1. The register file reads `rs1 = x0` (`0`) onto `RD1` and `rs2 = x9` (`25`) onto
   `RD2`.
2. `ALUSrc = 1`, so the ALU adds `rs1 + imm = 0 + 0 = 0` → the effective address.
3. The address goes to the data memory's address port; `RD2` (`25`) goes to its
   write-data port `WD`.
4. `MemWrite = 1`, so on the clock edge memory stores `mem[0] = 25`.
5. `RegWrite = 0`, so the register file is left unchanged.

**Result: `mem[0] = 25`.** ✓ The later `lw x18, 0(x0)` reads it back — see
[I-type, Example B](I-type.md).

> **Store vs. load, side by side:** both compute `address = rs1 + imm` in the
> ALU. A load sets `ResultSrc = 01` and `RegWrite = 1` (memory → register); a
> store sets `MemWrite = 1` and `RegWrite = 0` (register → memory). Same address
> math, opposite direction.

## Related documentation

- Blocks used: [Register File](../docs/register_file.md),
  [Sign Extend](../docs/sign_extend.md), [ALU](../docs/alu.md),
  [Data Memory](../docs/data_memory.md)
- The matching load: [I-type](I-type.md)
