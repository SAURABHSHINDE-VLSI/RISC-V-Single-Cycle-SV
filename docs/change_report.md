# RISC-V Single-Cycle Project Change Report

## Summary

This report records the RTL, simulation, testbench, and Vivado implementation changes made during the project debugging and verification work.

## RTL Changes

### Control unit and decoders

- Fixed the misspelled `loigc` declaration for `ALUControl` in `control_unit_top.sv`.
- Reworked `Control_Unit_Top` with an explicit typed SystemVerilog port interface.
- Connected `Zero` from the ALU into `Control_Unit_Top` and then into `Main_Decoder`.
- Added the `PCSrc` output to `Control_Unit_Top`.
- Connected `PCSrc` from `Main_Decoder` through the control unit.
- Fixed the signal-name typo in `main_decoder.sv` by changing `branch` to the declared `Branch` signal.

### Top-level processor

- Corrected register-file write-back wiring so `Result` is connected to `WD3`.
- Corrected the data-memory port syntax and connected `ReadData` to the memory read-data port.
- Connected the ALU `Zero` flag to the control unit.
- Added branch target calculation using `PC + immediate`.
- Changed the PC next-address selection to use `PCSrc`:

```systemverilog
PCSrc ? PCBranch : PCPlus4
```

- Added the top-level `debug_pc` output driven by `PC_Top`. This prevents Vivado from optimizing the entire processor away as an unobservable empty design during implementation.

### Simulation initialization

- Initialized instruction memory to zero before loading the program.
- Updated instruction-memory initialization to load the project program file from `tb/memfile.mem`.
- Initialized all register-file entries to zero so unused registers do not begin simulation as `X` values.

## Testbench Changes

Added directed testbenches for RTL modules that previously had no dedicated testbench:

- `tb/sign_extend_tb.sv`
- `tb/alu_decoder_tb.sv`
- `tb/main_decoder_tb.sv`
- `tb/control_unit_top_tb.sv`

The control-unit testbench includes checks for:

- R-type add control
- R-type subtract control
- Load control
- Store control
- Branch not taken
- Branch taken
- `PCSrc` behavior based on the `Zero` flag

The existing top-level testbench was also used to observe PC, instruction, register, ALU, and control signals in Vivado waveforms.


## Verification Results

### Vivado XSim

The following directed testbenches were compiled and run with Vivado XSim:

- Sign extension: passed after correcting the expected value for the S-type test vector.
- ALU decoder: passed.
- Main decoder: passed.
- Control unit: passed, including branch taken and branch not-taken cases.

Representative control-unit result:

```text
PASS [add control]
PASS [sub control]
PASS [load control]
PASS [store control]
PASS [branch not taken]
PASS [branch taken]
=== CONTROL UNIT TESTS PASSED ===
```

### Source diagnostics

VS Code diagnostics reported no errors in the affected RTL and testbench files after the fixes.

### Vivado implementation

The first implementation attempt failed with:

```text
[Place 30-494] The design is empty
```

This occurred because the processor had no observable output beyond clock and reset, allowing synthesis to remove the design. Adding `debug_pc` made the processor observable, and a subsequent implementation completed successfully.

Vivado also reported methodology warnings because no user timing constraints or board pin assignments were present. The implementation completed, but accurate hardware timing analysis requires an XDC constraint file containing the actual board-specific clock and I/O pin constraints.

## Current Follow-up Items

- Add the correct board-specific XDC file with the real `clk` pin, `rst` pin, `debug_pc` pins, and a clock constraint such as:

```tcl
create_clock -name clk -period 10.000 [get_ports clk]
```

- Rerun synthesis and implementation after adding the XDC constraints.
- Add the new testbenches to Vivado Simulation Sources if they are not already visible in the project.
- Review the project Git status, then commit and push the intended files to GitHub.
