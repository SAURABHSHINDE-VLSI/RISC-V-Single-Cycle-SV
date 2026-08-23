# R-type — register OP register

An **R-type** instruction takes two registers, does an arithmetic or logic
operation on them, and writes the answer into a third register. No memory, no
immediate, no branching — just pure register-to-register compute.

> **In plain words:** "take what's in these two boxes, combine them, put the
> result in that box." Nothing leaves the register file except to visit the ALU
> and come right back.

## Which instructions are R-type?

All share opcode `0110011`; `funct3` (and sometimes `funct7`) picks the exact op:

`add`, `sub`, `and`, `or`, `xor`, `sll`, `srl`, `sra`, `slt`

## Bit layout

```
   31        25 24   20 19   15 14   12 11    7 6        0
  ┌────────────┬───────┬───────┬───────┬───────┬──────────┐
  │   funct7   │  rs2  │  rs1  │funct3 │  rd   │  opcode  │
  │   7 bits   │ 5 bits│ 5 bits│ 3 bits│ 5 bits│  7 bits  │
  └────────────┴───────┴───────┴───────┴───────┴──────────┘
```

## Example we will trace: `add x9, x1, x6`

From the demo program (Group 2). Before it runs, earlier instructions have
already set `x1 = 5` and `x6 = 20`, so we expect `x9 = 5 + 20 = 25`.

Machine code: **`0x006084B3`**

### Step 1 — decode the bits

```
   0x006084B3 = 0000000 00110 00001 000 01001 0110011
                └─funct7┘└rs2─┘└rs1─┘└f3┘└─rd─┘└opcode┘
```

| Field  | Bits          | Value     | Meaning |
|--------|---------------|-----------|---------|
| opcode | `0110011`     | R-type    | "register OP register" |
| rd     | `01001` = 9   | `x9`      | destination |
| funct3 | `000`         | add/sub   | which op (with funct7) |
| rs1    | `00001` = 1   | `x1`      | first source |
| rs2    | `00110` = 6   | `x6`      | second source |
| funct7 | `0000000`     | add       | `0100000` would mean sub |

### Step 2 — control signals the decoder produces

The [Control Unit](../docs/control_unit_top.md) sees opcode `0110011` and sets:

| Signal      | Value    | Effect |
|-------------|----------|--------|
| `RegWrite`  | `1`      | we will write the result into `x9` |
| `ALUSrc`    | `0`      | ALU operand B comes from **`rs2`**, not an immediate |
| `ALUOp`     | `10`     | "R-type — let funct3/funct7 choose the op" |
| `ALUControl`| `ALU_ADD`| funct3=000 + funct7=0000000 → add |
| `MemWrite`  | `0`      | memory untouched |
| `ResultSrc` | `00`     | write-back comes from the **ALU** |
| `Branch`/`Jump` | `0`  | PC just advances to PC+4 |

### Step 3 — walk the data through the datapath

```
   x1 (=5) ─► RD1 ─────────────► A ┐
                                   ▼
   x6 (=20)─► RD2 ─► [MUX ALUSrc=0]─► B ─►┌──────┐
                        (picks rs2)       │ ALU  │─► ALUResult = 25
                              ALU_ADD ───►│ add  │
                                          └──────┘
                                              │ ResultSrc=00 (pick ALU)
                                              ▼
                                        [Result MUX] ─► Result = 25
                                              │ RegWrite=1
                                              ▼
                                       write into x9   ✓  x9 = 25
```

1. The register file reads `rs1 = x1` onto `RD1` (value `5`) and `rs2 = x6` onto
   `RD2` (value `20`).
2. Because `ALUSrc = 0`, the operand-B mux passes `RD2` (`20`) — **not** an
   immediate — into the ALU's `B` input.
3. `ALUControl = ALU_ADD`, so the ALU computes `5 + 20 = 25` on `ALUResult`.
4. `ResultSrc = 00`, so the write-back mux forwards `ALUResult` as `Result`.
5. `RegWrite = 1`, so on the clock edge `25` is stored into `x9`.
6. This isn't a branch or jump, so `PCSrc = 0` and the PC advances to `PC + 4`.

**Result: `x9 = 25`.** ✓

## Try another: `sub x10, x6, x1`

Same path, one field differs. Machine code **`0x40130533`**: `funct7 = 0100000`,
so `funct7[5] = 1`. With `funct3 = 000` **and** the R-type opcode, the
[ALU Decoder](../docs/alu_decoder.md) selects `ALU_SUB` instead of `ALU_ADD`, and
the ALU computes `x6 - x1 = 20 - 5 = 15` → `x10 = 15`.

> **Why does only a real R-type become "sub"?** The sub marker `funct7[5]` can
> accidentally appear inside an `addi` immediate. The decoder therefore requires
> **both** `op[5]=1` (R-type) **and** `funct7[5]=1` before choosing subtract — so
> `addi` never turns into a subtraction by accident.

## Related documentation

- Blocks used: [Register File](../docs/register_file.md),
  [ALU](../docs/alu.md), [ALU Decoder](../docs/alu_decoder.md)
- Compare with immediate math: [I-type](I-type.md)
