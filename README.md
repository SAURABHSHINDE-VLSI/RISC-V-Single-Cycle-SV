# RISC-V Single-Cycle (SystemVerilog)

This repository contains a single-cycle RV32I processor project written in SystemVerilog, along with directed testbenches and module-level documentation.

## Project overview

- Target ISA: RV32I (subset under active development)
- Design style: single-cycle datapath and control
- Language: SystemVerilog
- Verification style: directed simulation testbenches

## Repository structure

```
rtl/    # Processor RTL modules
tb/     # Testbenches and memory initialization files
docs/   # Module documentation, waveforms, schematics, and simulation screenshots
```

## Implemented/available blocks

- Program Counter register (`rtl/pc_register.sv`)
- Instruction Memory (`rtl/instruction_memory.sv`)
- Register File (`rtl/register_file.sv`)
- Sign Extend unit (`rtl/sign_extend.sv`)
- ALU (`rtl/alu.sv`)
- Main Decoder / ALU Decoder / Control Unit (`rtl/main_decoder.sv`, `rtl/alu_decoder.sv`, `rtl/control_unit_top.sv`)
- Data Memory (`rtl/data_memory.sv`)
- Top-level integration module (`rtl/single_cycle_top.sv`)

## Documentation

Detailed design + verification notes are available in:

- `docs/pc_register.md`
- `docs/instruction_memory.md`
- `docs/register_file.md`
- `docs/alu.md`
- `docs/data_memory.md`

## Running module testbenches

Use Vivado xsim (Behavioral Simulation) with the relevant RTL + testbench pair:

- `tb/pc_register_tb.sv`
- `tb/instruction_memory_tb.sv`
- `tb/register_file_tb.sv`
- `tb/alu_tb.sv`
- `tb/data_memory_tb.sv`

`tb/memfile.mem` is used for instruction-memory simulation input.

## Status

This is a learning and development repository for building up a complete single-cycle RISC-V CPU from verified modules.
