# Control Unit (Top)

The Control Unit is the **brain** of the processor: given a decoded instruction,
it produces every control signal the datapath needs for that cycle. This module
is a thin wrapper that wires together the two leaf decoders and bundles their
outputs into a single `ctrl_t` struct.

> **In plain words:** this file doesn't decide much on its own — it hires two
> specialists ([Main Decoder](main_decoder.md) and [ALU Decoder](alu_decoder.md)),
> collects their answers, and packs them into one neat envelope (`ctrl_t`) for
> the datapath.

## Interface

| Port    | Direction | Type              | Description |
|---------|-----------|-------------------|-------------|
| `dec`   | input     | `decoded_instr_t` | Decoded instruction fields (opcode, funct3, funct7, rs1/rs2/rd) |
| `Zero`  | input     | `logic`           | ALU zero flag, used for branch resolution |
| `ctrl`  | output    | `ctrl_t`          | Bundled control signals for the datapath |
| `PCSrc` | output    | `logic`           | `1` = redirect PC to branch/jump target |

Both `decoded_instr_t` and `ctrl_t` are defined in [riscv_pkg](riscv_pkg.md).

## Internal structure

```
            decoded_instr_t dec              Zero
        ┌──────────┬──────────┬───────┐        │
        │ opcode   │ funct3   │funct7 │        │
        ▼          ▼          │       │        ▼
   ┌─────────────────────┐    │   ┌───────────────────────┐
   │    Main_Decoder     │◄───┼───┤  (Zero into main dec)  │
   │  RegWrite, ALUSrc,  │    │   └───────────────────────┘
   │  MemWrite, Branch,  │    │
   │  Jump, ResultSrc,   │    │
   │  ImmSrc, ALUOp ─────┼────┤
   │  PCSrc ─────────────┼────┼──────────────────────────► PCSrc
   └─────────────────────┘    │
                              ▼
        opcode,funct3,funct7 ─┴─►┌─────────────────┐
                                 │   ALU_Decoder   │
                                 │  ALUControl[3:0]│
                                 └────────┬────────┘
                                          │
        ┌─────────────────────────────────┴──────────────────┐
        ▼           bundle into ctrl_t (one always_comb)      ▼
   ┌──────────────────────────────────────────────────────────┐
   │ ctrl = {reg_write, alu_src, mem_write, mem_read, branch,   │
   │         jump, result_src, imm_sel, alu_ctrl}               │──► ctrl
   └──────────────────────────────────────────────────────────┘
```

## What the wrapper adds

Beyond instantiating the two decoders, this module performs a little "glue":

- **Derives `mem_read`.** There is no explicit load signal from the Main
  Decoder, so it is computed as `mem_read = (result_src == 2'b01)` — the load is
  the only write-back that pulls data from memory.
- **Casts plain vectors into enums.** The decoders emit raw `logic` vectors;
  here they are cast into their named types exactly once:
  `imm_sel = imm_sel_t'(imm_src)` and `alu_ctrl = alu_op_t'(alu_control)`.
- **Passes `Zero` and `funct3` into the Main Decoder** so branch direction
  (`beq` vs `bne`, taken vs not) is resolved and surfaced as `PCSrc`.

> **Why bundle into `ctrl_t`?** Without the struct, the top-level would need to
> route ~10 separate control wires by hand, and any mismatch would be a silent
> bug. One typed envelope makes the connection self-checking.

## Design notes

- **Two-level decode.** Splitting into Main + ALU decoders mirrors the classic
  Harris & Harris organization and keeps each piece small and testable.
- **`jump` is live.** Earlier in development `ctrl.jump` was tied to `0`; with
  `jal` implemented it is now driven by the Main Decoder's `Jump` output.
- **Combinational.** The whole control unit is pure `always_comb`/`assign`
  logic — it settles within the single cycle, no clock involved.

## Verification

Directed testbench: `tb/control_unit_top_tb.sv`. It drives a `decoded_instr_t`
(plus `Zero`) and checks the packed `ctrl_t` fields and `PCSrc`.

| # | Case | Key expectations |
|---|------|------------------|
| 1 | `add` control | `alu_ctrl=ALU_ADD`, `reg_write=1` |
| 2 | `sub` control | `alu_ctrl=ALU_SUB` |
| 3 | `lw` control | `result_src=01`, `alu_src=1`, `imm_sel=IMM_I` |
| 4 | `sw` control | `mem_write=1`, `imm_sel=IMM_S` |
| 5 | `beq` not taken (`Zero=0`) | `branch=1`, `PCSrc=0` |
| 6 | `beq` taken (`Zero=1`) | `PCSrc=1` |
| 7 | `bne` not taken (equal) | `PCSrc=0` |
| 8 | `bne` taken (differ) | `PCSrc=1` |
| 9 | `jal` | `result_src=10`, `PCSrc=1`, `imm_sel=IMM_J` |

All checks pass in Vivado xsim (Behavioral Simulation):

```
=== CONTROL UNIT TESTS PASSED ===
```

### Console output

![Console output showing all control-unit tests passing](images/control_unit_top/console_pass.png)

### Waveform

The waveform walks each instruction class and shows the `ctrl_t` fields and
`PCSrc` responding to opcode/`funct3`/`Zero`.

![Control unit waveform across all test cases](images/control_unit_top/waveform.png)

### Synthesized hardware view

Vivado's RTL schematic — the Main Decoder and ALU Decoder side by side, feeding
the `ctrl_t` bundle.

![Synthesized control unit schematic](images/control_unit_top/schematic.png)

## Related documentation

- Children: [Main Decoder](main_decoder.md), [ALU Decoder](alu_decoder.md)
- Top-level integration: [Single-Cycle Top](single_cycle_top.md)
- Types: [riscv_pkg](riscv_pkg.md)
