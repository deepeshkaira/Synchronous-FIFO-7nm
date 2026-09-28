# Design decisions and revision notes

## Three clock-control implementations

The ungated FIFO retains conditional state updates but receives a continuously running clock. Manual RTL gating uses a latch-and-AND structure. Tool insertion starts from enable-based sequential RTL and allows DC to select integrated clock-gating cells.

The same enable-based RTL is used for the recent gated and ungated runs. Their principal synthesis difference is `compile_ultra -gate_clock` versus `compile_ultra`. Final scripts belong in separate repository files; this document explains the decisions rather than giving a reproduction procedure.

## Why four-bit pointers address eight entries

Three lower bits address eight words. The additional bit distinguishes wraparound. Empty compares full pointer values; full compares matching address bits with opposite wrap bits. This extra bit does not increase memory depth to sixteen.

## Independent enable conditions

An accepted read requires block enable, read request and a nonempty FIFO. An accepted write requires block enable, write request and either free space or a simultaneous accepted read. Pointer updates and memory access must retain these separate conditions. Flags retain their own block-enable update rule.

## Clock-gating control point

The functional enable and the test override are different signals. For positive-edge, latch-based clock gating:

| Style | Structure |
|---|---|
| none | Latch the functional enable; AND the result with clock. |
| before | OR functional enable with test override before the latch. |
| after | OR test override with the latched functional enable after the latch. |

With before, the latch holds both controls stable during the active clock phase. With after, test override bypasses the latch and must obey safe switching timing. The available ASAP7 cells declare `latch_posedge_precontrol`.

The earlier none request was rejected with PWR-191/PWR-132, leaving the prior style in effect. The accepted before setting and minimum bank width of one allowed gating of small register groups. The earlier wrapper achieved 13 gates/241 bits; the standalone FIFO achieves 11 gates/217 bits. These are different designs.

## Tie low and tie high

A tie-low cell supplies constant logical zero; tie-high supplies logical one. A logical one is not necessarily one volt. The standalone mapped FIFO connects `TIELO U203 -> n128 -> TE -> SE` for every ICG. This disables the active-high test override; functional enable still controls clock pulses. No floating test input was found in that inspected path.

## Power categories

| Category | Meaning |
|---|---|
| Internal | Switching within cells, including register clock-pin circuitry. |
| Net switching | Charging/discharging driven pin and modeled wire capacitance. |
| Leakage | Current while powered, including when data and clocks are static. |

Clock-network, register and combinational groups partition where power is consumed. They are not extra terms to add to internal + switching + leakage. The reported clock-network subtotal includes register clock-pin internal power.

## Wider project history

The project also explored a register plus FIFO wrapper, UVM verification, UPF domain shutdown, isolation and X propagation. Original power-aware simulation used 0.7/0.6 V domains. A later exploratory synthesis used NanGate 15 nm at 0.8 V for the register and ASAP7 at 0.7 V for FIFO/wrapper. It reported 24 mapped isolation cells through standard-cell isolation eligibility, but missing level shifters and conflicting UPF strategies remained. That experiment is not a demonstrated manufacturable mixed-node implementation.

The active comparison here is exclusively the standalone ASAP7 FIFO. The original 18.54 uW result belongs to manual FIFO gating, not wrapper power. In this standalone comparison no UPF was loaded in DC/PT.

## Characterization versus power-aware simulation

UPF simulation can model an ON voltage, power-off corruption and boundary clamping without demonstrating physical cell timing/power characterization at that voltage. A supply label does not create a new library corner. Inspected RVT AND2 views are FF 0.77 V/0 C, TT 0.70 V/25 C and SS 0.63 V/100 C; these are complete combinations, not freely interchangeable voltage/temperature choices.

## Remaining evidence for final claims

Archive exact current sources, constraints, tool scripts, SAIF provenance and post-update activity reports. Investigate table-range warnings and establish matching area evidence. Preserve the distinction between reported power estimates and validated post-layout measurements.
