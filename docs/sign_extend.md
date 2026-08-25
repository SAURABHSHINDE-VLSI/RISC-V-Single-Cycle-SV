# Sign Extend (Immediate Generator)

RISC-V packs the immediate constant into **different bit positions** depending on
the instruction format, and always stores only the upper bits (the sign lives in
bit 31). The Sign Extend module reassembles those scattered bits into a full,
sign-extended 32-bit immediate that the datapath can use directly.

> **In plain words:** the immediate is like a word whose letters got shuffled
> and scattered across the instruction. This module knows the unshuffling recipe
> for each format and rebuilds the original number — then copies the sign bit
> across the top so negative numbers stay negative.

## Interface

| Port      | Direction | Type        | Description |
|-----------|-----------|-------------|-------------|
| `In`      | input     | `logic[31:0]` | The full 32-bit instruction |
| `ImmSrc`  | input     | `imm_sel_t` | Which format to decode (from the Control Unit) |
| `Imm_Ext` | output    | `logic[31:0]` | The reconstructed, sign-extended immediate |

`imm_sel_t` is defined in [riscv_pkg](riscv_pkg.md).

## The formats it builds

```
   ImmSrc = IMM_I ─►  {sext(In[31]), In[31:20]}                          (addi, lw, jalr)
   ImmSrc = IMM_S ─►  {sext(In[31]), In[31:25], In[11:7]}                (sw)
   ImmSrc = IMM_B ─►  {sext, In[31], In[7], In[30:25], In[11:8], 1'b0}   (beq, bne)
   ImmSrc = IMM_J ─►  {sext, In[31], In[19:12], In[20], In[30:21], 1'b0} (jal)
   ImmSrc = IMM_U ─►  x  (not implemented in the single-cycle subset)
                       │
                       └─ every format copies In[31] (the sign bit) into the top
```

| `ImmSrc` | Format | Bit width of constant | Note |
|----------|--------|-----------------------|------|
| `IMM_I`  | I-type | 12 bits               | plain right-justified immediate |
| `IMM_S`  | S-type | 12 bits               | split across `[31:25]` and `[11:7]` |
| `IMM_B`  | B-type | 13 bits (LSB = 0)     | byte offset is always even |
| `IMM_J`  | J-type | 21 bits (LSB = 0)     | byte offset is always even |
| `IMM_U`  | U-type | —                     | reserved; outputs `x` for now |

> **Why the trailing `1'b0` for B and J?** Branch and jump targets are measured
> in bytes, and instructions are 4-byte aligned, so the offset is always even.
> RISC-V doesn't waste an instruction bit encoding a `0` that must always be `0`,
> so hardware appends it. That is why B/J immediates are one bit "wider" than
> their stored fields.

## Worked example — I-type

Take `addi x1, x0, 5` = `0x00500093`.

```
   In[31:20] = 0000 0000 0101  = decimal 5
   In[31]    = 0                (sign bit — positive)

   Imm_Ext = {20 copies of 0} , 0000_0000_0101
           = 0x00000005 = 5      ✓
```

And a negative one, `addi x2, x0, -8` = `0xFF800113`:

```
   In[31:20] = 1111 1111 1000  = -8 in 12-bit two's complement
   In[31]    = 1                (sign bit — negative)

   Imm_Ext = {20 copies of 1} , 1111_1111_1000
           = 0xFFFFFFF8 = -8     ✓  (sign preserved)
```

## Design notes

- **Sign extension, not zero extension.** Every implemented case replicates
  `In[31]` into the upper bits so negative immediates stay negative in 32 bits.
- **Purely combinational.** A single `always_comb` `case` on `ImmSrc`; the
  output tracks the inputs with no clock.
- **`IMM_U` deliberately outputs `x`.** `lui`/`auipc` are out of the current
  subset. The `x` makes an accidental use obvious in simulation instead of
  silently producing a wrong-but-plausible value.
- **Driven by the Control Unit.** `ImmSrc` comes from the Main Decoder's
  `ImmSrc` output (via `ctrl.imm_sel`), so the format always matches the opcode.

## Verification

Directed testbench: `tb/sign_extend_tb.sv`. Each case feeds a real instruction
word and the expected format, then checks `Imm_Ext`.

| # | Format | Example instruction | Expected `Imm_Ext` |
|---|--------|---------------------|--------------------|
| 1 | I-type (positive) | `addi x1,x0,5`   | `0x00000005` |
| 2 | I-type (negative) | `addi x2,x0,-8`  | `0xFFFFFFF8` |
| 3 | S-type | `sw x9,0(x0)`               | `0x00000000` |
| 4 | B-type | `beq x1,x2,+8`             | `0x00000008` |
| 5 | J-type | `jal x21,+8`               | `0x00000008` |

All checks pass in Vivado xsim (Behavioral Simulation):

```
=== ALL TESTS PASSED ===
```

### Console output

![Console output showing all sign-extend tests passing](images/sign_extend/console_pass.png)

### Waveform

The waveform drives one instruction per format and shows `Imm_Ext` reassembling
the correct constant, including sign extension for negatives.

![Sign extend waveform across all test cases](images/sign_extend/waveform.png)

### Synthesized hardware view

Vivado's RTL schematic — the format mux selecting among the I/S/B/J bit
re-orderings.

![Synthesized sign extend schematic](images/sign_extend/schematic.png)

## Related documentation

- Driven by: [Control Unit (top)](control_unit_top.md) via `imm_sel`
- Types: [riscv_pkg](riscv_pkg.md)
- Formats in action: [I-type](../instructions_type/I-type.md),
  [S-type](../instructions_type/S-type.md),
  [B-type](../instructions_type/B-type.md),
  [J-type](../instructions_type/J-type.md)
