# Single-Cycle Top

`single_cycle_top` is the **whole processor**: it instantiates and wires every
block so that one full RV32I instruction is fetched, decoded, executed, and
written back in a single clock cycle. Everything else in `rtl/` is a piece; this
is the assembled machine.

> **In plain words:** if the other modules are the organs, this is the body that
> connects them — PC feeds instruction memory, which feeds the decoder and
> register file, which feed the ALU, which feeds memory and the write-back mux,
> which feeds the registers and the next PC. All in one tick of the clock.

## Interface

| Port       | Direction | Width | Description |
|------------|-----------|-------|-------------|
| `clk`      | input     | 1     | Processor clock |
| `rst`      | input     | 1     | Synchronous, active-high reset (resets the PC to 0) |
| `debug_pc` | output    | 32    | Current PC, exposed for waveform/debug visibility |

> **Note:** only `debug_pc` is exported. Register and memory contents are
> inspected hierarchically in simulation (e.g. `dut.register_file.regs[9]`),
> which is how `tb/single_cycle_top_tb.sv` dumps the final register state.

## Datapath block diagram

```
                 PCSrc (from Control Unit)
                     │
             ┌───────▼────────┐
   PCPlus4 ─►│ 0              │
             │       MUX      ├─► PC_Next ─┐
   PCBranch ─►│ 1             │            │
             └────────────────┘            │
                                           ▼
      rst ─────────────────────────► ┌───────────┐
      clk ─────────────────────────► │    PC     │──┬──► debug_pc
                                      └───────────┘  │
                                        PC_Top       │
             ┌───────────────────────────┴───────────┤
             │                                        │
   +4 ───►(PC_Top + 4) = PCPlus4              (PC_Top + Imm_Ext) = PCBranch
             │                                        ▲
             ▼                                        │
      ┌──────────────┐   RD_Instr                     │
      │ Instruction  ├───────────┬─────────────┬──────┼───────────┐
      │   Memory     │           │             │      │           │
      └──────────────┘           ▼             ▼      │           ▼
        A = PC_Top          decode fields   Sign_Extend        (funct fields)
                          rs1 rs2 rd op f3 f7  │ Imm_Ext_Top       │
                             │  │  │           │                   │
                             ▼  ▼  ▼           │                   ▼
                    ┌─────────────────┐        │           ┌───────────────┐
                    │  Register File  │        │           │ Control Unit  │
                    │  RD1 ─────────► A│ (ALU)  │           │  ctrl_t,PCSrc │
                    │  RD2 ──┐        │        │           └───────┬───────┘
                    └────────┼────────┘        │        ctrl.* ────┘
                             │        alu_src ──┼──┐   (steer every mux/enable)
                             │                  │  ▼
                             │           ┌──────────────┐
                             │  RD2 ─► 0 │     MUX      │─► SrcB ─┐
                             │  Imm ─► 1 │              │         │
                             │           └──────────────┘         ▼
                             │                              ┌───────────┐
                             │                    RD1 ─► A ─►│    ALU    │─► ALUResult ─┐
                             │                              │  Zero ────┼──► Control    │
                             │                              └───────────┘   (branch)   │
                             │                                                          │
                             ▼ (WD = RD2)                                               │
                      ┌──────────────┐   ReadData                                       │
                      │ Data Memory  ├───────────────┐                                  │
                      │  A = ALUResult│               │                                 │
                      └──────────────┘               │                                 │
                        WE = mem_write               ▼                                 ▼
                                              ┌──────────────────────────────────────────┐
                                     result_src│ 00: ALUResult   01: ReadData   10: PCPlus4│
                                              │                MUX                         │
                                              └───────────────────┬────────────────────────┘
                                                                  │ Result
                                                                  ▼
                                                     WD3 → Register File (write rd)
```

## One-cycle instruction flow

Every instruction walks the same five conceptual steps, all within one cycle:

1. **Fetch** — the PC addresses instruction memory; `RD_Instr` comes back.
2. **Decode** — `RD_Instr` is split into `decoded_instr_t` fields; the Control
   Unit produces `ctrl_t` and `PCSrc`; Sign Extend builds the immediate.
3. **Execute** — the ALU computes on `RD1` and `SrcB` (either `rs2` or the
   immediate, chosen by `alu_src`); it also raises `Zero` for branches.
4. **Memory** — for `lw`/`sw`, the data memory is read/written at `ALUResult`.
5. **Write-back** — the `result_src` mux picks ALU / memory / PC+4, and (if
   `reg_write`) writes it into `rd`. Meanwhile the PC mux (via `PCSrc`) chooses
   `PCPlus4` or `PCBranch` for the next cycle.

> **Why "single-cycle"?** All of steps 1–5 are combinational except the two
> state elements (PC and the register/data-memory write ports). The clock edge
> latches the results, so exactly one instruction completes per cycle.

## Sub-modules instantiated

| Instance | Module | Doc |
|----------|--------|-----|
| `PC` | `PC_Module` | [pc_register.md](pc_register.md) |
| `instruction_memory` | `Instruction_Memory` | [instruction_memory.md](instruction_memory.md) |
| `register_file` | `Register_File` | [register_file.md](register_file.md) |
| `sign_extend` | `Sign_Extend` | [sign_extend.md](sign_extend.md) |
| `ALU` | `ALU` | [alu.md](alu.md) |
| `Control_Unit_Top` | `Control_Unit_Top` | [control_unit_top.md](control_unit_top.md) |
| `data_memory` | `Data_Memory` | [data_memory.md](data_memory.md) |

## Key internal wiring

- `PC_Next = PCSrc ? PCBranch : PCPlus4` — the branch/jump decision point.
- `PCPlus4 = PC_Top + 4` and `PCBranch = PC_Top + Imm_Ext_Top`.
- `SrcB = alu_src ? Imm_Ext_Top : RD2_Top` — ALU operand B mux.
- `Result` mux: `00 → ALUResult`, `01 → ReadData`, `10 → PCPlus4`.
- Data memory write data is `RD2_Top` (the `rs2` value), addressed by
  `ALUResult` (the computed effective address).

## Design notes

- **Only the PC (and write ports) hold state.** Reset touches the PC; the
  register file and data memory have their own write-enable gating. Everything
  between them is combinational.
- **`jal` needed no datapath changes.** `PCBranch` (PC + J-immediate) and the
  `result_src = 10` (PC+4) write-back path already existed, so enabling `jal`
  was purely a control-unit change.
- **Pipelining is future work.** Because branch resolution uses the runtime
  `Zero` flag inside the control path, splitting this into IF/ID/EX/MEM/WB
  stages will require moving branch resolution to the EX/MEM boundary. See the
  roadmap in the [project README](../README.md).

## Verification

Integration testbench: `tb/single_cycle_top_tb.sv`. It holds `rst` for a few
cycles, runs the 28-instruction demo program in `tb/memfile.mem` for 32 cycles,
then dumps the final register file and compares against expected values.

The program exercises **every implemented instruction type** (I-type ALU,
R-type, load/store, taken & not-taken `beq`/`bne`, and `jal`). Expected final
state (abridged):

| Register | Expected | Proves |
|----------|----------|--------|
| `x9`  | `25`  | R-type `add` (5 + 20) |
| `x18` | `25`  | `sw` then `lw` round-trip through memory |
| `x19`, `x20` | `0` | traps correctly **skipped** by taken branches |
| `x21` | `0x00000068` | `jal` linked PC+4 into `rd` |
| `x22` | `0` | trap after `jal` correctly skipped |

A successful run prints the grouped register dump ending with:

```
=== single_cycle_top TB FINISHED ===
```

### Console output

The register dump showing every group's expected values.

![Single-cycle top console register dump](images/single_cycle_top/console_pass.png)

### Waveform

`PC` advancing by 4, jumping on taken branches/`jal`, with the register file
updating as each instruction retires.

![Single-cycle top waveform](images/single_cycle_top/waveform.png)

### Synthesized hardware view

Vivado's RTL schematic of the complete datapath and control unit wired together.

![Synthesized single-cycle top schematic](images/single_cycle_top/schematic.png)

## Related documentation

- Every sub-module doc linked in the table above.
- Per-instruction datapath walkthroughs:
  [`instructions_type/`](../instructions_type/README.md)
- Project overview and how to simulate: [README](../README.md)
