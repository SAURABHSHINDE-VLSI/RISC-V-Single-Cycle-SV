# Main Decoder

The Main Decoder is the **first level** of the control unit. It looks only at the
7-bit `Op` (opcode) field — plus `funct3` and the ALU `Zero` flag for branches —
and produces the high-level control signals that steer the datapath. The
second-level [ALU Decoder](alu_decoder.md) then refines the exact ALU operation.

> **In plain words:** the opcode is the instruction's "job title." The Main
> Decoder reads that title and decides the big questions: *do we write a
> register? use an immediate? touch memory? is this a branch or a jump?*

## Interface

| Port        | Direction | Width | Description |
|-------------|-----------|-------|-------------|
| `Op`        | input     | 7     | Opcode, instruction bits `[6:0]` |
| `funct3`    | input     | 3     | Distinguishes `beq` (`000`) from `bne` (`001`) |
| `Zero`      | input     | 1     | ALU zero flag — `1` when the two operands are equal |
| `RegWrite`  | output    | 1     | Write result to the register file |
| `ALUSrc`    | output    | 1     | ALU operand B: `0` = `rs2`, `1` = immediate |
| `MemWrite`  | output    | 1     | Store to data memory |
| `ResultSrc` | output    | 2     | Write-back source: `00`=ALU, `01`=mem, `10`=PC+4 |
| `ImmSrc`    | output    | 3     | Immediate format select (feeds `sign_extend`) |
| `ALUOp`     | output    | 2     | Coarse ALU class for the ALU Decoder |
| `Branch`    | output    | 1     | Instruction is a branch |
| `Jump`      | output    | 1     | Instruction is an unconditional jump (`jal`) |
| `PCSrc`     | output    | 1     | `1` = redirect PC to the branch/jump target |

## Opcode → control truth table

This is the heart of the module. Each row is one instruction class.

| Instruction | `Op`      | RegWrite | ALUSrc | MemWrite | ResultSrc | ImmSrc | ALUOp | Branch | Jump |
|-------------|-----------|:--------:|:------:|:--------:|:---------:|:------:|:-----:|:------:|:----:|
| R-type      | `0110011` | 1        | 0      | 0        | `00`      | `000`* | `10`  | 0      | 0    |
| I-type ALU  | `0010011` | 1        | 1      | 0        | `00`      | `000`  | `10`  | 0      | 0    |
| `lw`        | `0000011` | 1        | 1      | 0        | `01`      | `000`  | `00`  | 0      | 0    |
| `sw`        | `0100011` | 0        | 1      | 1        | `00`      | `001`  | `00`  | 0      | 0    |
| `beq`/`bne` | `1100011` | 0        | 0      | 0        | `00`      | `010`  | `01`  | 1      | 0    |
| `jal`       | `1101111` | 1        | 0      | 0        | `10`      | `100`  | `00`  | 0      | 1    |

<sub>*R-type has no immediate; `ImmSrc` is a don't-care and defaults to `000`.</sub>

## Branch and jump resolution

The Main Decoder also decides **whether the PC should jump this cycle**. It
combines a static branch flag with the runtime `Zero` flag:

```
   funct3 ─┐
           ▼
   beq (000): take if operands EQUAL      → branch_taken = Zero
   bne (001): take if operands DIFFER     → branch_taken = ~Zero
                                   │
   Branch ─────────────┐          │
                       ▼          ▼
                   ┌───────────────────┐
   Jump ──────────►│  PCSrc = Jump |    │──► PCSrc
                   │  (Branch &         │    (1 = take target)
                   │   branch_taken)    │
                   └───────────────────┘
```

So `PCSrc` is asserted when the instruction is an unconditional jump (`jal`), or
when it is a branch **and** its condition is satisfied.

> **Why does `funct3` live here?** `beq` and `bne` share the same opcode
> (`1100011`); only `funct3` tells them apart. The ALU always *subtracts* for a
> branch, and `Zero` tells us if the operands matched — `beq` takes the branch on
> `Zero`, `bne` on `~Zero`.

## Design notes

- **`jal` writes a register.** Even though it is a jump, `jal` links the return
  address (PC+4) into `rd`, so `RegWrite = 1` and `ResultSrc = 10` for it.
- **`ImmSrc` is 3 bits, `ResultSrc` is 2 bits.** These were widened to make room
  for `IMM_J` (`100`) and the PC+4 write-back path (`10`). See
  [`riscv_pkg`](riscv_pkg.md) for the encodings.
- **Single-cycle only (for now).** Because `PCSrc` depends on the runtime `Zero`
  flag, this branch-resolution logic will need to move to the EX/MEM stage when
  the design is pipelined. In single-cycle everything settles in one cycle, so
  computing it here is correct.
- **Priority-mux style.** The outputs use chained ternaries (`?:`), which
  synthesize to priority muxes — readable and matches the one-hot opcode space.

## Verification

Directed testbench: `tb/main_decoder_tb.sv`. Each vector drives an opcode
(+`funct3`, +`Zero`) and compares the full concatenated output bundle against a
hand-computed expected value.

| # | Case                     | Notable check |
|---|--------------------------|---------------|
| 1 | R-type                   | `ALUOp=10`, `RegWrite=1`, `ALUSrc=0` |
| 2 | I-type ALU               | `ALUSrc=1`, `ImmSrc=000` |
| 3 | `lw`                     | `ResultSrc=01`, `ALUOp=00` |
| 4 | `sw`                     | `MemWrite=1`, `ImmSrc=001` |
| 5 | `beq`, `Zero=0`          | `PCSrc=0` (not taken) |
| 6 | `beq`, `Zero=1`          | `PCSrc=1` (taken) |
| 7 | `bne`, `Zero=1` (equal)  | `PCSrc=0` (not taken) |
| 8 | `bne`, `Zero=0` (differ) | `PCSrc=1` (taken) |
| 9 | `jal`                    | `Jump=1`, `PCSrc=1`, `ResultSrc=10`, `ImmSrc=100` |

All checks pass in Vivado xsim (Behavioral Simulation):

```
=== ALL TESTS PASSED ===
```

### Console output

![Console output showing all main-decoder tests passing](images/main_decoder/console_pass.png)

### Waveform

The waveform steps through each opcode and shows the control bundle changing,
including `PCSrc` toggling with `Zero` for the branch cases.

![Main decoder waveform across all test cases](images/main_decoder/waveform.png)

### Synthesized hardware view

Vivado's RTL schematic — the opcode decode logic feeding the control outputs and
the `PCSrc` OR/AND resolution gate.

![Synthesized main decoder schematic](images/main_decoder/schematic.png)

## Related documentation

- Parent: [Control Unit (top)](control_unit_top.md)
- Sibling: [ALU Decoder](alu_decoder.md)
- Types: [riscv_pkg](riscv_pkg.md)
- Branch/jump in action: [B-type](../datapath_example/B-type.md),
  [J-type](../datapath_example/J-type.md)
