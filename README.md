# Synchronous FIFO: ASAP7 clock-gating power comparison

A depth-8, 23-bit synchronous FIFO evaluated with three clock-control implementations: no clock gating, manual RTL clock gating, and synthesis-inserted integrated clock gates (ICGs).

## Design and verification

- 184 memory bits, 23 read-output bits, two 4-bit pointers, and two status flags: **217 functional register bits**.
- Independent accepted-read and accepted-write enables, registered read output, full/empty flags, and wraparound pointer tracking.
- SystemVerilog/UVM testbench includes active, boundary, control and random sequences. The supplied test selects the random sequence; regression transcripts are pending.
- ASIC synthesis: Synopsys Design Compiler. Power analysis: PrimeTime/PrimePower using SAIF activity.

## Reported power results

**ASAP7 7 nm, RVT TT, 0.7 V, 25 C.** Values are averaged, pre-layout power estimates; no wire-load model was set.

| Metric | Ungated | Manual RTL gating | Tool-inserted ICG |
|---|---:|---:|---:|
| Internal power | 25.790 uW | 13.530 uW | 8.915 uW |
| Net switching power | 2.665 uW | 4.927 uW | 3.484 uW |
| Leakage power | 0.07795 uW | 0.07626 uW | 0.06930 uW |
| **Total power** | **28.54 uW** | **18.54 uW** | **12.47 uW** |
| **Reported reduction versus ungated** | **Baseline** | **35.0%** | **56.3%** |
| Clock-network subtotal (included above) | 22.740 uW | 12.180 uW | 3.879 uW |

The ICG estimate is **16.07 uW below ungated** and **32.7% below the historical manual-gating result**. The two recent runs read the same `sync_fifo.saif`. The manual-gating run is an earlier reference, not a fully revalidated matched experiment.

## Clock-gating implementation

| Result | Ungated | Tool-inserted ICG |
|---|---:|---:|
| Tool-inserted clock gates | 0 | 11 |
| Gated register bits | 0 | 217 |
| Ungated register bits | 217 | 0 |

The mapped gates are `ICGx1_ASAP7_75t_R`. Inspected connections show separate `write_enable` and `read_enable` gates, an `en_i` gate for flags, and eight memory-word gates. All ICG test-enable inputs are tied low through `TIELOx1_ASAP7_75t_R`, so test override is inactive. Register coverage is not a percentage power saving.

## Interpretation and evidence status

- Internal power is energy used inside cells; net switching charges driven capacitance; leakage remains while cells are powered.
- FIFO storage is implemented as registers, explaining the zero memory-macro power group.
- Gated and ungated SAIF reports were captured before `update_power`; final activity propagation, especially ICG clock activity, still needs inspection.
- Out-of-range ramp/load counts: ungated **33/23**, manual **34/27**, ICG **44/207**. These limit confidence in the comparison.
- Area savings are not claimed: matching area reports have not been archived here.

The results above are verified against the imported reports: [manual RTL](results/reports/manual_rtl/sync_fifo_power_verbose.rpt), [ICG](results/reports/icg/sync_fifo_power_verbose.rpt), and [ungated](results/reports/ungated/sync_fifo_power_verbose.rpt). The supplied RTL, four DC/PT scripts, Questa run script, exported SDCs and 27 reports are archived unchanged. [Import manifest](results/import_manifest.csv) records their original archive paths and SHA-256 hashes.

The testbench, simulation UPF and original synthesis SDC have also been added. Mapped netlists and matching SAIF are still needed for the archived PrimeTime flow. See the [import review](docs/import-review.md) for two corrections made to the newly supplied files.

## Simulation waveform

![Standalone FIFO simulation](docs/images/sync-fifo-simulation.png)

User-supplied waveform showing enable, read/write requests, data and status outputs. A waveform alone does not establish scoreboard pass status or activity coverage; the simulation transcript is still pending.

## Repository layout

| Directory | Intended contents |
|---|---|
| `rtl/` | Final standalone FIFO RTL and historical manual-gate version |
| `tb/` | UVM testbench, packages and sequences |
| `constraints/` | SDC used for both comparisons |
| `scripts/` | Actual DC, PrimeTime and Questa scripts |
| `netlist/` | Exported gated and ungated SDCs; mapped Verilog pending |
| `upf/` | Optional standalone simulation power intent, clearly labeled |
| `results/` | Summary data and original result reports |
| `docs/` | Theory, design decisions, evidence notes and waveform figures |

Current standalone synthesis and PrimeTime scripts do **not** load UPF. The separate mixed-library registered-wrapper experiment is documented in project history, but its results are not these standalone FIFO numbers.

The supplied `run_sync_fifo.do` is stored at the repository root and loads `upf/sync_fifo_upf.upf` for simulation.

See [design notes](docs/design-notes.md), [results data](results/power_summary.csv), and the [file intake checklist](docs/file-intake.md).

Technology libraries and vendor tools are not bundled. Use appropriately licensed local installations. No license for publishing third-party library content is implied.
