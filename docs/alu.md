# ALU (Arithmetic Logic Unit)

The ALU is the core compute block of the single-cycle RV32I datapath. It takes two
32-bit operands and a 4-bit control code, and produces a result plus status flags.

> **In plain words:** the ALU is the calculator. The rest of the CPU decides
> *which* button to press (`ALUControl`) and *what numbers* to feed it (`A`, `B`);
> the ALU just computes and also reports a few facts about the answer (the flags).

## Interface

| Port          | Direction | Width | Description                                  |
|---------------|-----------|-------|-----------------------------------------------|
| `A`           | input     | 32    | Operand A (SrcA — typically `rs1`)            |
| `B`           | input     | 32    | Operand B (SrcB — `rs2` or sign-extended imm) |
| `ALUControl`  | input     | 4 (enum `alu_op_t`) | Selects the operation to perform |
| `Result`      | output    | 32    | Result of the operation                       |
| `Zero`        | output    | 1     | `1` if `Result == 0` (used by `beq`/`bne`)    |
| `Negative`    | output    | 1     | Sign bit of `Result`                          |
| `Carry`       | output    | 1     | Carry-out of add/subtract                     |
| `OverFlow`    | output    | 1     | Signed overflow of add/subtract               |

## ALUControl encoding

The encoding is the `alu_op_t` enum in [`rtl/riscv_pkg.sv`](riscv_pkg.md) — the
single source of truth shared with the [ALU Decoder](alu_decoder.md).

| ALUControl | Operation                | Used by                          |
|:----------:|--------------------------|----------------------------------|
| `0000`     | add                      | `lw`, `sw`, `addi`, `add`        |
| `0001`     | subtract                 | `beq`, `bne`, `sub`              |
| `0010`     | and                      | `and`, `andi`                    |
| `0011`     | or                       | `or`, `ori`                      |
| `0100`     | xor                      | `xor`, `xori`                    |
| `0101`     | set-less-than (signed)   | `slt`                            |
| `0110`     | shift left logical       | `sll`, `slli`                    |
| `0111`     | shift right logical      | `srl`, `srli`                    |
| `1000`     | shift right arithmetic   | `sra`, `srai`                    |

Because `ALUControl` is the typed enum `alu_op_t`, it is checked at compile time —
it is not possible to drive the ALU with an undefined code.

```
         A[31:0] ─────┐        ┌───── B[31:0]
                      ▼        ▼
                 ┌─────────────────────┐
   ALUControl ──►│   op-select (case)  │
     [3:0]       │  add sub and or xor │
                 │  slt sll srl sra    │
                 └──────────┬──────────┘
                            ▼
                        Result[31:0] ──► Zero, Negative
                 (Carry / OverFlow valid for add & subtract)
```

## Design notes

- **Add/subtract share one adder.** Subtraction is done as `A + (~B) + 1`
  (two's-complement negation), selected by `ALUControl[0]`, so there is no second
  adder. `Zero` on a subtract therefore means "operands are equal" — exactly what
  `beq`/`bne` need.
- **`slt` reuses the subtractor.** `A < B` (signed) is true exactly when `A - B`
  is negative, so `slt` reads the sign bit of the subtraction result and
  zero-extends it to `1` or `0`. The same sign-bit trick generalizes to signed
  branch comparisons (e.g. `blt`) in a future extension.
- **Shifts use `B[4:0]` as the shift amount.** Only the low 5 bits matter for a
  32-bit word. `sra`/`srai` uses `$signed(A) >>> B[4:0]` so the sign bit is
  replicated (arithmetic shift), while `srl`/`srli` uses a plain `>>` (logical).
- **`xor` is a plain bitwise operation**, added alongside `and`/`or` to complete
  the R-/I-type logical set.
- **Flags (`Carry`, `OverFlow`, `Negative`) are only meaningful for add/subtract.**

## Verification

Directed testbench: `tb/alu_tb.sv`. Each case checks `Result` against an expected
value, plus targeted checks on the `Zero`, `Negative`, `Carry`, and `OverFlow`
flags.

| # | Test               | A            | B            | ALUControl | Expected Result |
|---|--------------------|--------------|--------------|:----------:|------------------|
| 1 | add                | `5`          | `3`          | `0000`     | `8`              |
| 2 | subtract           | `10`         | `4`          | `0001`     | `6`              |
| 3 | and                | `0xFF00FF00` | `0x0F0F0F0F` | `0010`     | `0x0F000F00`     |
| 4 | or                 | `0xF0F0F0F0` | `0x0F0F0F0F` | `0011`     | `0xFFFFFFFF`     |
| 5 | slt (true case)    | `3`          | `5`          | `0101`     | `1`              |
| 6 | slt (false case)   | `5`          | `3`          | `0101`     | `0`              |
| 7 | zero flag          | `4`          | `4`          | `0001`     | `0`, `Zero=1`    |
| 8 | address calc       | `0x2004`     | `0xFFFFFFFC` | `0000`     | `0x2000`         |
| 9 | negative flag      | `4`          | `10`         | `0001`     | `0xFFFFFFFA`, `Negative=1` |
| 10| carry              | `0xFFFFFFFF` | `2`          | `0000`     | `0x1`, `Carry=1`, `OverFlow=0` |

> The shift and `xor` operations (`sll`/`srl`/`sra`/`xor`) are additionally
> exercised end-to-end by the 28-instruction demo program in `tb/memfile.mem`,
> checked in [`single_cycle_top`](single_cycle_top.md)'s testbench (e.g. `x6=20`,
> `x8=-4`, `x13=2`, `x14=160`, `x16=-1`).

All checks pass in Vivado xsim (Behavioral Simulation):

```
=== ALL TESTS PASSED ===
$finish called at time : 100 ns
```

### Console output

![Console output showing all tests passing](images/alu/console_pass.png)

### Waveform

Test cases stepping through in simulation, each `ALUControl` value visible
alongside its inputs/outputs.

![ALU waveform across all test cases](images/alu/waveform.png)

### Synthesized hardware view

Vivado's RTL schematic, generated from the SystemVerilog, confirms the design is
synthesizable, not just simulation-only. Shows the adder, the operation-select
mux, and the shift/logic paths.

![Synthesized ALU schematic](images/alu/schematic.png)

## Related documentation

- Operation encoding: [riscv_pkg](riscv_pkg.md)
- Chooses the operation: [ALU Decoder](alu_decoder.md)
- Integrated in: [Single-Cycle Top](single_cycle_top.md)
- In action: [R-type](../datapath_example/R-type.md),
  [I-type](../datapath_example/I-type.md)
