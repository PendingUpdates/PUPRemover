# PUPRemover

PowerShell detection-and-removal for a family of bundled/misleading-ad PUPs
(potentially unwanted programs) that install under user-profile paths on
Windows:

| PUP | Notes |
|---|---|
| **Wave Browser** | Chromium PUP; reinstalls via a `Wavesor SWUpdater` scheduled task. Covers the co-installed sibling **WebNavigatorBrowser**. |
| **Blazer Browser** | `PUP.Optional.BlazerBrowser`; updater runs as `BlazerBrowserUpdateTask`. |
| **Crystal PDF** | A **trojanized fake PDF editor / infostealer** (2025 Microsoft/CIS/GDATA writeups), not mere adware. Its own uninstaller is fake. |
| **Shift Browser** | **Opt-in only** — see [the Shift Browser caveat](#the-shift-browser-caveat). |

It sweeps and removes, per user profile: running **processes**, **scheduled
tasks**, **install folders** (AppData / profile root), leftover
**installers** in Downloads/Desktop, **registry** persistence (Run/RunOnce
values, vendor keys, uninstall entries, browser registration,
ProgId/COM classes), **shortcuts**, and **MSIX/Store packages**. Every run
reports the artifacts found (with their paths, registry keys, and tasks) and
the per-item removal result, and writes a timestamped CSV + log.

## Two ready-to-run scripts

Both are **self-contained** (no dependencies) and live at the repo root:

### `PUPRemover-S1.ps1` — automated (SentinelOne)

Runs non-interactively as SYSTEM: scans, reports, removes everything, reports
the result, and exits with a machine-readable code. No prompts, no arguments.

```powershell
powershell.exe -ExecutionPolicy Bypass -File PUPRemover-S1.ps1
```

**Exit codes:** `0` = clean or everything removed · `2` = one or more
removals failed (reboot the endpoint and re-run). Under SentinelOne a
non-zero exit surfaces as a failed run, so `2` flags machines that need
attention — the intended signal.

Targets Wave/Blazer/Crystal by default. To include Shift Browser (e.g. on the
closed test system), set the toggle near the top of the file:

```powershell
$IncludeShiftBrowser = $true
```

### `PUPRemover-Test.ps1` — interactive (closed-system testing)

Human-in-the-loop console. Run in an **elevated** PowerShell window to cover
all profiles:

```powershell
powershell.exe -ExecutionPolicy Bypass -File PUPRemover-Test.ps1
```

Menu:

```
1. Full Scan   — scan for every PUP, list what's found, then remove
                 ALL of them or a SELECTED subset of apps.
2. Select App  — choose which app(s) to scan for, list what's found,
                 then remove just those.
3. Exit
```

Nothing is removed without an explicit confirmation, and every removal prints
per-item success/failure and writes a CSV + log.

## Reports

Both scripts write `PUPRemover_<timestamp>.csv` and `.log` to the first
writable location of:

1. `%ProgramData%\PUPRemover\Logs`
2. `%TEMP%\PUPRemover`
3. `.\PUPRemover-logs` (current directory)

The CSV columns are `PUP, Category, Status, Item, Detail`.

## The Shift Browser caveat

Shift Browser (Redbrick / **Shift Technologies, Inc.**) is **code-signed by
the same publisher as, and installs to the same paths as, a legitimate paid
workspace browser** (`%LOCALAPPDATA%\Shift\chromium\`, `shift.exe`,
`shift_pwa_launcher.exe`, uninstall name "Shift"). What AV vendors flag as
`PUP.Optional.ShiftBrowser` appears to be Redbrick's own installer, flagged
for its misleading-ad distribution — Malwarebytes has shipped false positives
on it.

**No signature or path test can separate an unwanted bundled install from one
a user chose.** So Shift is:

- **excluded from the default** S1 target (enable per-machine via the toggle);
- matched only on **hard, install-path-anchored indicators** — the exact
  path shape (`\Shift\chromium\`, `\ShiftData\`), exact process names, the
  `Shift Technologies` publisher string, and the campaign's installer/dropper
  filenames — **never a bare `shift`**. This keeps `redshift`, `openshift`,
  `ShiftN`, `shift-qt`, and Teams `Shifts` safe.

Only target Shift where you know it is unwanted. There is **no** product
called "Shift Printer" — the printer/PDF angle is just the fake-download
lure (`recipes_*.exe` / `pdf_*.exe`).

## False-positive safety

Match patterns never fire on the bare tokens `wave`, `blazer`, `crystal`,
`webnavigator`, or `shift`. Verified by `tests/test-patterns.ps1` against a
corpus of real collisions: Waves MaxxAudio (`WavesSvc*`), Wavebox, WavePad,
GoldWave, Elgato Wave Link, Adobe Shockwave, **Siemens SIMATIC WinCC
WebNavigator (SCADA)**, BlazeRush, Trailblazer, CrystalDiskInfo/Mark, SAP
Crystal Reports, Redshift, OpenShift, ShiftN, and ordinary user files.
Additional safeguards: folder names are matched **exactly** (no filesystem
wildcards); a user's own `C:\Users\<x>\Blazer` folder is never touched;
`Temp\crys` is removed only when the Crystal payload is inside it; shortcuts
are judged by their **resolved target**; and match blobs are `|`-joined so a
pattern can't span two fields.

Run elevated/SYSTEM to cover every profile and all loaded `HKEY_USERS`
hives; a non-elevated run is limited to the current user. Registry hives of
logged-off users aren't loaded, so their Run-key persistence clears the next
time they log in (the machine-visible reinstall tasks are removed regardless).

## Development

`src/PUPCore.ps1` is the single source of truth: the PUP definitions plus the
`Invoke-PUPScan` / `Invoke-PUPRemoval` / reporting engine. The two root
scripts are generated by embedding the core:

```powershell
.\build.ps1        # regenerates PUPRemover-S1.ps1 and PUPRemover-Test.ps1
```

Edit `src/PUPCore.ps1` (or the `src/driver-*.ps1` tails), re-run `build.ps1`,
and commit the regenerated root scripts. Run the pattern tests with:

```powershell
pwsh -File tests/test-patterns.ps1
```

## Repository layout

```
PUPRemover-S1.ps1        generated, self-contained — SentinelOne
PUPRemover-Test.ps1      generated, self-contained — interactive testing
build.ps1                regenerates the two root scripts from src/
src/PUPCore.ps1          definitions + scan/remove/report engine (source of truth)
src/driver-s1.ps1        auto driver tail
src/driver-test.ps1      interactive menu tail
tests/test-patterns.ps1  pattern unit tests (runs on any pwsh)
```
