# J-type — jump-and-link

A **J-type** instruction (`jal`) does two things at once: it **jumps**
unconditionally to a PC-relative target, and it **links** — saves the return
address (`PC + 4`) into a register so the program can come back later. This is
the backbone of function calls.

> **In plain words:** "jump to over there, but first leave a bookmark (the
> address of the next instruction) in a register so we can return." Unlike a
> branch, there is no condition — `jal` always jumps.

## Which instructions are J-type?

Opcode `1101111`: **`jal`**. (`jalr`, the register-indirect jump, is I-format and
not in this subset.)

## Bit layout

The 21-bit (even) offset is scrambled across the instruction:

```
   31   30           21 20  19            12 11    7 6        0
  ┌──┬─────────────────┬──┬─────────────────┬───────┬──────────┐
  │20│    imm[10:1]    │11│   imm[19:12]    │  rd   │  opcode  │
  └──┴─────────────────┴──┴─────────────────┴───────┴──────────┘
   └── immediate = {imm20, imm19:12, imm11, imm10:1, 0} ──┘
```

Note that `rd` is in its usual place — `jal` **does** write a register.

## The two jobs of `jal`

```
        ┌──────────── JUMP ────────────┐   ┌──────── LINK ────────┐
   PC ─►(＋)─► PCBranch = PC + Imm       │   PC ─►(＋4)─► PCPlus4    │
         ▲                              │              │           │
   Imm ──┘         PCSrc = Jump = 1 ────┘   ResultSrc=10 (pick PC+4)│
                        │                              ▼            │
                        ▼                    [Result MUX] ─► write rd
                   [PC MUX] ─► PC_Next = PCBranch
```

- **Jump:** `Jump = 1` forces `PCSrc = 1`, so the PC mux takes `PCBranch =
  PC + immediate` (same adder the branches use).
- **Link:** `ResultSrc = 10` routes `PC + 4` through the write-back mux, and
  `RegWrite = 1` stores it into `rd`.

## Example we will trace: `jal x21, +8`

From Group 5. In the demo program this instruction sits at byte address `0x64`.
It jumps `+8` bytes (to `0x6C`, skipping a trap `addi`) and links the return
address `0x68` into `x21`.

Machine code: **`0x00800AEF`**

### Step 1 — decode

| Field | Value | Meaning |
|-------|-------|---------|
| opcode | `1101111` | `jal` |
| rd | `10101` = 21 (`x21`) | where to store the return address |
| imm | `+8` | jump offset (bytes) |

### Step 2 — control signals

| Signal | Value | Effect |
|--------|-------|--------|
| `Jump` | `1` | unconditional jump |
| `PCSrc` | `1` | PC takes the branch/jump target |
| `ImmSrc` | `IMM_J` | build a J-type immediate |
| `ResultSrc` | `10` | write-back source = **PC + 4** |
| `RegWrite` | `1` | store the return address into `x21` |
| `ALUSrc` / `MemWrite` / `Branch` | `0` | ALU result and memory unused; not a branch |

### Step 3 — data flow

```
   PC = 0x64 ─┬─►(＋)─► PCBranch = 0x64 + 8 = 0x6C ─► [PC MUX] ─► PC_Next=0x6C
              │   ▲                                      ▲  (PCSrc=1)
     Imm=+8 ──┘   │                                      │
                  │                                       
              └──►(＋4)─► PCPlus4 = 0x68 ─► [Result MUX] ─► Result=0x68
                                              (ResultSrc=10)   │ RegWrite=1
                                                               ▼
                                                        write x21 = 0x68 ✓
```

1. The branch adder computes `PCBranch = PC + imm = 0x64 + 8 = 0x6C`.
2. `Jump = 1` → `PCSrc = 1`, so `PC_Next = 0x6C`. The next instruction fetched
   is the halt, **skipping** the trap `addi x22, x0, 99` at `0x68`.
3. In parallel, `PCPlus4 = 0x64 + 4 = 0x68` is the return address.
4. `ResultSrc = 10` selects `PCPlus4`; `RegWrite = 1` stores it → `x21 = 0x68`.

**Result: PC jumps to `0x6C`, and `x21 = 0x00000068` (the return address).** ✓
The skipped `addi x22, x0, 99` never runs, so `x22` stays `0`.

> **`jal` needed no new datapath wires.** The `PCBranch` adder already existed for
> branches, and the `ResultSrc = 10` (PC+4) path was reserved ahead of time in
> [`riscv_pkg`](../docs/riscv_pkg.md). Enabling `jal` was purely a control-unit
> change — a nice payoff of planning the encodings early.

## Branch vs. jump — the key contrast

| | B-type (`beq`/`bne`) | J-type (`jal`) |
|---|---|---|
| Jumps? | only if condition holds | **always** |
| Writes a register? | no | yes (return address) |
| `PCSrc` | `Branch & branch_taken` | `Jump` (= 1) |
| `ResultSrc` | `00` (unused) | `10` (PC+4) |

## Related documentation

- Decision/control: [Main Decoder](../docs/main_decoder.md)
- Target & PC+4 adders: [Single-Cycle Top](../docs/single_cycle_top.md)
- Offset reconstruction: [Sign Extend](../docs/sign_extend.md)
- Conditional cousin: [B-type](B-type.md)
