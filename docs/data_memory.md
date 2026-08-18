# Data Memory

`rtl/data_memory.sv` implements a 4 KiB data memory with 1024 32-bit words.

- `A` is a byte address. The two least-significant bits identify a byte inside
  a 32-bit word, therefore aligned word accesses use `A[11:2]`.
- `A[11:2]` selects one of 1024 aligned 32-bit words.
- `WE = 1` stores `WD` on the next rising edge of `clk`.
- `RD` is an asynchronous read of the selected word.

The module initializes word 28 to `32'h0000_0020`, so a load from byte address 112 reads 32.

## Vivado simulation

1. Add `rtl/data_memory.sv` under **Design Sources**.
2. Add `tb/data_memory_tb.sv` under **Simulation Sources**.
3. Set `data_memory_tb` as the simulation top module and run **Run Behavioral Simulation**.

The testbench checks the initialized location and a clocked store followed by a load. A successful run prints:

```
PASS: Data_Memory read and write tests completed.
```
