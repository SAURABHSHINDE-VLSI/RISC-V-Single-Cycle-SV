# B-type — conditional branch

A **B-type** instruction compares two registers and, *if a condition holds*,
redirects the PC to a nearby target instead of just advancing to the next
instruction. This is how the CPU makes decisions (loops, `if`/`else`).

> **In plain words:** "if these two registers pass the test, jump ahead (or
> back) by this offset; otherwise, carry on to the next instruction." The clever
> part is *how* the compare is done — the ALU just **subtracts** and reports
> whether the answer was zero.

## Which instructions are B-type?

Opcode `1100011`; `funct3` picks the test. In this subset:

- `beq` (`funct3 = 000`) — branch if **equal**
- `bne` (`funct3 = 001`) — branch if **not equal**

## Bit layout

The immediate is scattered the most in B-type, because the offset is a 13-bit
*even* number (bit 0 is always 0):

```
   31    30       25 24   20 19   15 14  12 11     8  7  6      0
  ┌──┬─────────────┬───────┬───────┬─────┬─────────┬──┬────────┐
  │12│  imm[10:5]  │  rs2  │  rs1  │funct3│imm[4:1]│11│ opcode │
  └──┴─────────────┴───────┴───────┴─────┴─────────┴──┴────────┘
   └── the immediate bits are: {imm12, imm11, imm10:5, imm4:1, 0} ──┘
```

## How the comparison works

The branch never uses a dedicated comparator. Instead:

```
   rs1 ─► A ┐
            ▼
   rs2 ─► B ─►┌──────┐
       ALU_SUB│ ALU  │─► (result thrown away)
              │ sub  │─► Zero = 1  if rs1 - rs2 == 0  (i.e. rs1 == rs2)
              └──────┘
                 │
                 ▼            beq: take if  Zero        (equal)
          branch_taken  ◄──   bne: take if  ~Zero       (not equal)
                 │
   Branch=1 ─────┴──► PCSrc = Branch & branch_taken  ──► pick PCBranch or PC+4
```

`ALUOp = 01` forces the ALU to **subtract**. If the operands are equal, the
difference is `0`, so `Zero = 1`. The [Main Decoder](../docs/main_decoder.md)
then uses `funct3` to interpret `Zero`: `beq` branches on `Zero`, `bne` branches
on `~Zero`.

---

## Example A: `beq x1, x2, +8` (NOT taken)

From Group 4. At this point `x1 = 5` and `x2 = -8`. Since `5 != -8`, this `beq`
should **fall through** to the next instruction.

Machine code: **`0x00208463`**

### Decode

| Field | Value | Meaning |
|-------|-------|---------|
| opcode | `1100011` | branch |
| funct3 | `000` | `beq` |
| rs1 | `00001` = 1 (`x1` = 5) | first operand |
| rs2 | `00010` = 2 (`x2` = -8) | second operand |
| imm | `+8` | target offset (bytes) |

### What happens

1. `ALUOp = 01` → ALU computes `x1 - x2 = 5 - (-8) = 13`.
2. `13 ≠ 0`, so `Zero = 0`.
3. `beq` (`funct3 = 000`) → `branch_taken = Zero = 0`.
4. `PCSrc = Branch & branch_taken = 1 & 0 = 0`.
5. The PC mux picks `PCPlus4` → execution continues at the next instruction.

**Result: branch NOT taken; PC → PC + 4.** ✓

---

## Example B: `bne x1, x2, +8` (TAKEN)

The very next instruction. Same operands, opposite test: `5 != -8` is **true**,
so this branch **is** taken and skips over the instruction after it (a "trap"
`addi` that would set `x19 = 99`).

Machine code: **`0x00209463`**

### Decode

| Field | Value | Meaning |
|-------|-------|---------|
| opcode | `1100011` | branch |
| funct3 | `001` | `bne` |
| rs1 | `00001` = 1 (`x1` = 5) | first operand |
| rs2 | `00010` = 2 (`x2` = -8) | second operand |
| imm | `+8` | target offset (bytes) |

### What happens

1. ALU subtracts: `5 - (-8) = 13`, so `Zero = 0`.
2. `bne` (`funct3 = 001`) → `branch_taken = ~Zero = 1`.
3. `PCSrc = Branch & branch_taken = 1 & 1 = 1`.
4. The PC mux picks `PCBranch = PC + 8`, skipping the next instruction.

**Result: branch TAKEN; PC → PC + 8.** The skipped `addi x19, x0, 99` never
runs, so `x19` stays `0`. ✓

## The branch-target adder

The target is **relative to the current PC**, computed by a dedicated adder in
the [top level](../docs/single_cycle_top.md):

```
   PCBranch = PC + Imm_Ext        (Imm_Ext = +8 here)

   PC ───────┐
             ▼
   Imm=+8 ─►(＋)─► PCBranch ─► [PC MUX] ─► PC_Next   (chosen when PCSrc=1)
                                  ▲
   PC+4 ──────────────────────────┘                 (chosen when PCSrc=0)
```

> **Why `+8` and not `+2`?** The offset is measured in **bytes**, and each
> instruction is 4 bytes. `+8` bytes = skip exactly one instruction. The Sign
> Extend module already appends the implicit `0` low bit, so branch offsets are
> always even.

## Related documentation

- Decision logic: [Main Decoder](../docs/main_decoder.md)
- The subtract-and-check-zero trick: [ALU](../docs/alu.md)
- Offset reconstruction: [Sign Extend](../docs/sign_extend.md)
- Unconditional cousin: [J-type](J-type.md)
