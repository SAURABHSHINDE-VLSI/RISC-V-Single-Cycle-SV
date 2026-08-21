# Program Counter (PC) Register

The Program Counter (PC) Register holds the byte address of the current
instruction in the single-cycle RV32I processor. On every rising clock edge it
either resets to address `0` or updates to the next address selected by the
datapath.

## Interface

| Port | Direction | Width | Description |
|------|-----------|-------|-------------|
| `clk` | input | 1 | Processor clock; the PC updates on its rising edge |
| `rst` | input | 1 | Active-high synchronous reset |
| `PC_Next` | input | 32 | Next instruction byte address, selected by the PC mux |
| `PC` | output | 32 | Current instruction byte address, sent to instruction memory |

## Operation

The PC Register is sequential logic. It changes only at the rising edge of
`clk`:

```systemverilog
always_ff @(posedge clk) begin
  if (rst)
    PC <= 32'b0;
  else
    PC <= PC_Next;
end
```

| Condition at rising clock edge | New `PC` value |
|--------------------------------|----------------|
| `rst = 1` | `32'h0000_0000` |
| `rst = 0` | `PC_Next` |

## Design notes

- **Synchronous reset:** Reset is sampled only on a rising clock edge. Changing
  `rst` between clock edges does not immediately change `PC`.
- **Normal sequential execution:** The PC-next logic normally supplies
  `PC + 4`, since every RV32I instruction is 32 bits (4 bytes).
- **Branches and jumps:** For a taken branch or jump, the PC-next mux supplies
  the target address instead of `PC + 4`.
- **Non-blocking assignment:** `<=` models a flip-flop correctly by scheduling
  the PC update after the clock edge.

## Verification

Directed testbench: `pc_register_tb.sv`.

| # | Test | Input condition | Expected `PC` |
|---|------|-----------------|---------------|
| 1 | Reset at start | `rst = 1` at a rising edge | `0x00000000` |
| 2 | First sequential step | `PC_Next = 0x00000004` | `0x00000004` |
| 3 | Continued execution | `PC_Next = 0x00000008`, then `0x0000000C` | `0x00000008`, then `0x0000000C` |
| 4 | Branch target | `PC_Next = 0x00000100` | `0x00000100` |
| 5 | Resume sequential execution | `PC_Next = 0x00000104` | `0x00000104` |
| 6 | Reset during execution | `rst = 1` at a rising edge | `0x00000000` |

A successful Vivado behavioral simulation prints:

```
=== ALL TESTS PASSED ===
```

## Vivado simulation

1. Add `pc_register.sv` to **Design Sources**.
2. Add `pc_register_tb.sv` to **Simulation Sources**.
3. Set `pc_register_tb` as the simulation top module.
4. Run **Run Behavioral Simulation**.
