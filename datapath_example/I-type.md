# I-type — register OP immediate (and loads)

An **I-type** instruction uses one source register and a 12-bit immediate baked
into the instruction. Two families share this format: the **immediate ALU ops**
(`addi`, `andi`, …) and the **loads** (`lw`). They flow through the datapath
almost identically — the only difference is where the final result comes from.

> **In plain words:** instead of a second register, the number to work with is
> written right into the instruction. For `addi` the ALU result is the answer;
> for `lw` the ALU computes an *address* and the answer comes from memory.

## Which instructions are I-type?

- **ALU immediate** (opcode `0010011`): `addi`, `andi`, `ori`, `xori`, `slli`,
  `srli`, `srai`
- **Load** (opcode `0000011`): `lw`
- **Jump register** (`jalr`) is I-format too, but is not in this subset.

## Bit layout

```
   31            20 19   15 14   12 11    7 6        0
  ┌────────────────┬───────┬───────┬───────┬──────────┐
  │   imm[11:0]    │  rs1  │funct3 │  rd   │  opcode  │
  │    12 bits     │ 5 bits│ 3 bits│ 5 bits│  7 bits  │
  └────────────────┴───────┴───────┴───────┴──────────┘
```

The whole immediate sits in bits `[31:20]` and is **sign-extended** to 32 bits.

---

## Example A: `addi x1, x0, 5`

The very first instruction of the demo program. `x0` is always `0`, so this is
how we get the constant `5` into `x1`.

Machine code: **`0x00500093`**

### Step 1 — decode

```
   0x00500093 = 000000000101 00000 000 00001 0010011
                └──imm=5────┘└rs1=0┘└f3┘└rd=1┘└opcode┘
```

| Field  | Value        | Meaning |
|--------|--------------|---------|
| opcode | `0010011`    | I-type ALU |
| rd     | `00001` = 1 (`x1`) | destination |
| funct3 | `000`        | `addi` |
| rs1    | `00000` (`x0`) | source (zero) |
| imm    | `0x005` = 5  | the constant |

### Step 2 — control signals

| Signal | Value | Effect |
|--------|-------|--------|
| `RegWrite` | `1` | write result to `x1` |
| `ALUSrc` | `1` | ALU operand B = **immediate** (not `rs2`) |
| `ImmSrc` | `IMM_I` | build a 12-bit I-type immediate |
| `ALUOp` | `10` → `ALU_ADD` | funct3=000 → add |
| `ResultSrc` | `00` | write-back from ALU |
| `MemWrite` | `0` | memory untouched |

### Step 3 — data flow

```
   x0 (=0) ─► RD1 ──────────────► A ┐
                                    ▼
   instr ─► Sign_Extend ─► Imm=5 ─► [MUX ALUSrc=1] ─► B ─►┌──────┐
                                       (picks imm)        │ ALU  │─► 5
                                             ALU_ADD ────►│ add  │
                                                          └──────┘
                                                 ResultSrc=00 │
                                                              ▼
                                             [Result MUX] ─► 5 ─► write x1 ✓
```

1. `RD1 = x0 = 0`.
2. Sign Extend rebuilds `imm = 5` (see [Sign Extend](../docs/sign_extend.md)).
3. `ALUSrc = 1`, so the mux feeds the **immediate** `5` into ALU `B`.
4. ALU adds `0 + 5 = 5`.
5. `ResultSrc = 00` and `RegWrite = 1` → `x1 = 5`.

**Result: `x1 = 5`.** ✓

> Negative immediates work the same way: `addi x2, x0, -8` = `0xFF800113` has
> `imm[11:0] = 0xFF8`, which sign-extends to `0xFFFFFFF8` = `-8`, so `x2 = -8`.

---

## Example B: `lw x18, 0(x0)`

A load looks like `addi` up to the ALU — but the ALU output is used as a
**memory address**, and the value written back comes from memory.

Machine code: **`0x00002903`**

### Step 1 — decode

```
   0x00002903 = 000000000000 00000 010 10010 0000011
                └──imm=0────┘└rs1=0┘└f3┘└rd=18┘└opcode┘
```

| Field | Value | Meaning |
|-------|-------|---------|
| opcode | `0000011` | load |
| rd | `10010` = 18 (`x18`) | destination |
| funct3 | `010` | `lw` (32-bit word) |
| rs1 | `00000` (`x0`) | base address register |
| imm | `0` | byte offset |

### Step 2 — control signals

| Signal | Value | Effect |
|--------|-------|--------|
| `RegWrite` | `1` | write loaded word to `x18` |
| `ALUSrc` | `1` | ALU adds base + immediate to form the address |
| `ImmSrc` | `IMM_I` | I-type immediate |
| `ALUOp` | `00` → `ALU_ADD` | address = `rs1 + imm` |
| `ResultSrc` | `01` | write-back from **memory** (not ALU!) |
| `MemWrite` | `0` | this is a read, not a write |

### Step 3 — data flow

```
   x0 (=0) ─► RD1 ─► A ┐
                       ▼
   imm=0 ─► [MUX=1] ─► B ─►┌──────┐
                           │ ALU  │─► addr = 0 ──► Data Memory ─► ReadData
                    ALU_ADD│ add  │                   (read mem[0])
                           └──────┘                        │
                                          ResultSrc=01 ─────┘
                                                     ▼
                                        [Result MUX] ─► write x18 ✓
```

1. ALU computes the effective address `rs1 + imm = 0 + 0 = 0`.
2. Data memory returns the word at address `0` on `ReadData`.
3. Because `ResultSrc = 01`, the write-back mux picks `ReadData` (not the ALU
   output).
4. `RegWrite = 1` → `x18` gets `mem[0]`.

In the demo program a `sw x9, 0(x0)` ran just before, storing `25` into `mem[0]`,
so this load brings it back: **`x18 = 25`.** ✓ (See [S-type](S-type.md) for that
store.)

> **The one difference between `addi` and `lw`:** they use the ALU identically to
> compute a value/address; only `ResultSrc` differs — `00` (ALU) for `addi`, `01`
> (memory) for `lw`.

## Related documentation

- Blocks used: [Register File](../docs/register_file.md),
  [Sign Extend](../docs/sign_extend.md), [ALU](../docs/alu.md),
  [Data Memory](../docs/data_memory.md)
- The matching store: [S-type](S-type.md)
- Pure register math: [R-type](R-type.md)
