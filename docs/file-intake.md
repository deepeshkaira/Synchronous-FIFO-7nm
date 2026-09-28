# Files to import from the Linux project

**Update, 2026-09-28:** RTL, four DC/PT scripts, the Questa `.do` file, two exported SDCs, three sets of PrimeTime reports and a waveform have now been imported. The list below is the original checklist; use [the import review](import-review.md) for the current missing-file list.

Send one archive, preserving names/subdirectories, or place the files in this local repository for review.

## Required

- Final standalone `rtl/sync_fifo.sv`; separately label the older manual gate RTL if available.
- `sync_fifo_tb.sv`, included packages/headers, test sequences, and the actual Questa run `.do` file.
- `constraints/sync_fifo.sdc`.
- Gated and ungated DC scripts and PrimeTime scripts actually used.
- Per-implementation verbose power, check_power, activity, units, timing-check, clock-gating, reference and area reports, plus logs.
- Preserve the old manual-gating reports if available; do not relabel an overwritten latest report as historical.
- SAIF collection details: sequence, random seed, clock period, timescale and collection start/end. The actual SAIF can remain local initially.

## Useful later

- Mapped gated/ungated netlists and exported SDCs for checking gate enables and reproducibility; review redistribution permissions before publishing generated/vendor-dependent files.
- Updated activity reports generated after update_power, for both recent versions.
- Selected readable waveform screenshots and the configuration associated with each.
- Optional UPF files, labeled with their simulation scope and whether loaded in implementation.

Do not send vendor `.db`, `.lib`, `.lib.gz`, cell-model source, license files or proprietary manuals for publication. Only include project code and reports you may share. Review tool logs for personal machine paths before publishing.

## Publication decisions

Confirm whether this is a standalone repository or should be merged into the existing Registered_FIFO_Low-power-7nm repository. Confirm the code license and final GitHub destination before publication. No remote, push or license has been configured in this scaffold.
