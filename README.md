# RV32I Single-Cycle Processor (SystemVerilog)

A single-cycle implementation of the **RISC-V RV32I** integer instruction set,
written in synthesizable SystemVerilog and verified in Vivado xsim. Every
instruction is fetched, decoded, executed, and written back in **one clock
cycle**. The design follows the classic Harris & Harris organization and is
built as a learning platform, with a full set of teaching docs and a
per-instruction datapath walkthrough.

> A 5-stage pipelined version is planned as the next step; the code is
> deliberately structured (typed control bundle, reserved encodings) to make that
> transition smooth.

---

## Features

- Complete single-cycle datapath: PC, instruction memory, register file, sign
  extender, ALU, two-level control unit, and data memory.
- **9 ALU operations** encoded in a shared, type-checked `alu_op_t` enum.
- Typed control path: control signals travel as a packed `ctrl_t` struct, and
  the instruction is decoded into a `decoded_instr_t` struct (see
  [`riscv_pkg`](docs/riscv_pkg.md)).
- Per-module directed testbenches **plus** a full-program integration test that
  exercises every implemented instruction type.
- Extensive documentation: one page per module and one page per instruction
  format, each with ASCII diagrams.

## Implemented instruction set

| Category | Instructions |
|----------|--------------|
| R-type | `add`, `sub`, `and`, `or`, `xor`, `sll`, `srl`, `sra`, `slt` |
| I-type ALU | `addi`, `andi`, `ori`, `xori`, `slli`, `srli`, `srai` |
| Load | `lw` |
| Store | `sw` |
| Branch | `beq`, `bne` |
| Jump | `jal` |

**Not yet implemented** (out of the current subset): `jalr`, `lui`, `auipc`,
byte/half memory accesses (`lb`/`lh`/`sb`/`sh`), and the remaining branches
(`blt`, `bge`, …). The `IMM_U` immediate format is defined in the type system but
unused.

---

## Architecture

```
                 PCSrc
                   │
         PC+4 ─►┌──┴──┐
                │ MUX │─► PC_Next ─► ┌────┐ ─► PC ─┬─────────────────────────┐
      PCBranch ─►└─────┘             │ PC │        │                         │
                                     └────┘        ▼                         │
                                            ┌─────────────┐                  │
                                            │ Instruction │─► instruction ─┐ │
                                            │   Memory    │                │ │
                                            └─────────────┘                │ │
             ┌─────────────────────────────────────────────┬──────────────┤ │
             ▼                     ▼                        ▼              │ │
     ┌───────────────┐    ┌───────────────┐        ┌───────────────┐      │ │
     │ Control Unit  │    │ Register File │        │  Sign Extend  │      │ │
     │  ctrl_t,PCSrc │    │  RD1, RD2     │        │   Imm_Ext     │      │ │
     └───────┬───────┘    └───┬───────┬───┘        └───────┬───────┘      │ │
        ctrl │            RD1 │   RD2 │        alu_src ─────┤              │ │
             │                │       ▼                     ▼              │ │
             │                │   ┌───────┐          ┌────────────┐        │ │
             │                │   │  MUX  │◄─ imm ───│            │        │ │
             │                │   └───┬───┘          └────────────┘        │ │
             │                ▼       ▼                                    │ │
             │            ┌───────────────┐                               │ │
             │     A ────►│      ALU      │─► ALUResult ─┬─► Data Memory ──┤ │
             │            │   + Zero flag │              │      │ ReadData │ │
             │            └───────────────┘              │      ▼          │ │
             │                                    ┌──────────────────────┐ │ │
             │                          result_src│ ALU / mem / PC+4  MUX │ │ │
             │                                    └───────────┬──────────┘ │ │
             │                                        Result  │            │ │
             └────────────────────────────────────────────────► write rd ─┘ │
                                                                             │
   (full, annotated version in docs/single_cycle_top.md) ────────────────────┘
```

See [**docs/single_cycle_top.md**](docs/single_cycle_top.md) for the fully
labeled datapath and a step-by-step one-cycle flow.

---

## Repository structure

```
RISC-V-Single-Cycle-SV/
├── rtl/                     # synthesizable SystemVerilog sources
│   ├── riscv_pkg.sv         #   shared types (alu_op_t, imm_sel_t, ctrl_t, ...)
│   ├── pc_register.sv       #   program counter
│   ├── instruction_memory.sv
│   ├── register_file.sv
│   ├── sign_extend.sv       #   immediate generator
│   ├── alu.sv
│   ├── alu_decoder.sv       #   2nd-level control (ALUControl)
│   ├── main_decoder.sv      #   1st-level control (opcode -> control bits)
│   ├── control_unit_top.sv  #   wraps the two decoders into ctrl_t
│   ├── data_memory.sv
│   └── single_cycle_top.sv  #   top level: wires everything together
├── tb/                      # testbenches + program image
│   ├── *_tb.sv              #   one directed testbench per module
│   ├── single_cycle_top_tb.sv  # full-program integration test
│   └── memfile.mem          #   the demo program (hex, one instr per line)
├── docs/                    # one Markdown page per module (+ images/)
└── datapath_example/        # one Markdown page per instruction format
```

---

## Documentation

**Module references** (in [`docs/`](docs)):

| Module | Doc |
|--------|-----|
| Shared types package | [riscv_pkg.md](docs/riscv_pkg.md) |
| Program counter | [pc_register.md](docs/pc_register.md) |
| Instruction memory | [instruction_memory.md](docs/instruction_memory.md) |
| Register file | [register_file.md](docs/register_file.md) |
| Sign extend | [sign_extend.md](docs/sign_extend.md) |
| ALU | [alu.md](docs/alu.md) |
| ALU decoder | [alu_decoder.md](docs/alu_decoder.md) |
| Main decoder | [main_decoder.md](docs/main_decoder.md) |
| Control unit (top) | [control_unit_top.md](docs/control_unit_top.md) |
| Data memory | [data_memory.md](docs/data_memory.md) |
| Single-cycle top | [single_cycle_top.md](docs/single_cycle_top.md) |

**Instruction datapath walkthroughs** (in [`datapath_example/`](datapath_example)):
[R-type](datapath_example/R-type.md) ·
[I-type](datapath_example/I-type.md) ·
[S-type](datapath_example/S-type.md) ·
[B-type](datapath_example/B-type.md) ·
[J-type](datapath_example/J-type.md) —
start at the [folder index](datapath_example/README.md).

---

## The demo program

[`tb/memfile.mem`](tb/memfile.mem) is a 28-instruction program organized into
labeled groups, one per instruction category, ending with a self-branch halt.
Each line is annotated with the operation and its expected effect, e.g.:

```
00500093   // addi x1, x0, 5     -> x1 = 5
006084B3   // add  x9,  x1, x6   -> x9  = 5 + 20 = 25
00902023   // sw   x9, 0(x0)     -> mem[0] = 25
00209463   // bne  x1, x2, +8    -> 5 != -8? YES -> TAKEN, skip next (trap)
00800AEF   // jal  x21, +8       -> jump +8, x21 = PC+4 (return addr)
```

It deliberately includes "trap" instructions (`addi ..., 99`) placed right after
taken branches/jumps — if control flow is correct they are **skipped**, so the
trap registers must remain `0`. Expected final register state:

| Reg | Value | Proves |
|-----|-------|--------|
| `x1`..`x8` | 5, -8, 1, 7, 2, 20, 2, -4 | I-type ALU (incl. signed `srai`) |
| `x9`..`x17` | 25, 15, 5, -3, 2, 160, 0, -1, 1 | R-type (incl. `sra`, signed `slt`) |
| `x18` | 25 | `sw` then `lw` round-trip via memory |
| `x19`, `x20` | 0, 0 | traps skipped by taken `bne`/`beq` |
| `x21` | `0x00000068` | `jal` linked the return address |
| `x22` | 0 | trap skipped by `jal` |

---

## Simulating in Vivado xsim

1. Create a new RTL project (or use the existing local Vivado project — the
   Vivado project directories are intentionally git-ignored).
2. Add **all** files under `rtl/` as design sources and the desired file under
   `tb/` as a simulation source.
3. Add `tb/memfile.mem` as a simulation source so `$readmemh` can find it.
4. Set the simulation top module (e.g. `single_cycle_top_tb` for the full
   program, or a per-module `*_tb`).
5. Run **Behavioral Simulation**. Each per-module testbench prints
   `=== ALL TESTS PASSED ===`; the top-level testbench prints a grouped register
   dump ending in `=== single_cycle_top TB FINISHED ===`.

> **Program image:** `rtl/instruction_memory.sv` loads the program with a bare
> filename (`$readmemh("memfile.mem", mem)`), so it is portable across machines —
> just make sure `tb/memfile.mem` is added as a **simulation source** (step 3) so
> xsim finds it in the simulation run directory.

---

## Verification

Every module has a directed testbench in `tb/`, and
[`single_cycle_top_tb.sv`](tb/single_cycle_top_tb.sv) runs the full demo program
and checks the final architectural state. Each module's doc page includes its
test table and space for the Vivado console, waveform, and RTL-schematic
screenshots (under `docs/images/<module>/`).

---

## Roadmap

- [x] Single-cycle RV32I core (this repo) — R/I-ALU, `lw`/`sw`, `beq`/`bne`,
  `jal`.
- [ ] Extend the ISA: `jalr`, `lui`, `auipc`, remaining branches, sub-word
  memory accesses.
- [ ] **5-stage pipeline** (IF/ID/EX/MEM/WB). The control bundle (`ctrl_t`) and
  reserved encodings are already in place; branch/jump resolution — currently in
  the main decoder — will move to the EX/MEM boundary.

---

## Reference

Organization and datapath follow *Digital Design and Computer Architecture, RISC-V
Edition* (Harris & Harris).
