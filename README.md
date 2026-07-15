# PUPRemover

PowerShell detection-and-removal for a family of bundled/misleading-ad PUPs
(potentially unwanted programs) that install under user-profile paths on
Windows:

| PUP | Notes |
|---|---|
| **Wave Browser** | Chromium PUP; reinstalls via a `Wavesor SWUpdater` scheduled task. Covers the co-installed sibling **WebNavigatorBrowser**. |
| **Blazer Browser** | `PUP.Optional.BlazerBrowser`; updater runs as `BlazerBrowserUpdateTask`. |
| **Shift Browser** | Chromium PUP. Removed by default like the others — read [the Shift Browser note](#the-shift-browser-note) for the one caveat you should know. |
| **ACE AI Browser** | `PUP.Optional.AceBrowser` (TamperedChef cluster). Covers both the `Ace` Chromium browser and its `AceLauncher` dock. Anchored so it never touches Microsoft Access Database Engine (`Microsoft.ACE.OLEDB`), Acer, Surface, or AceReader. Some browser artifacts are inferred — **RegShot-validate before fleet use.** |

It sweeps and removes, per user profile: running **processes**, **scheduled
tasks**, **install folders** (AppData / profile root), leftover
**installers** in Downloads/Desktop, **registry** persistence (Run/RunOnce
values, vendor keys, uninstall entries, browser registration,
ProgId/COM classes), and **shortcuts** (removed only when their resolved
target points at a PUP path). Every run reports the artifacts found (with
their paths, registry keys, and tasks) and the per-item removal result, and
writes a timestamped CSV + log.

The tool deletes PUP files, tasks, and registry entries. The one thing it
does **not** do by default is uninstall MSIX/Store apps: `Remove-AppxPackage`
is gated behind an explicit per-PUP package identity (none set today) and
hard-excludes Microsoft / first-party / OS packages, so it can never remove a
browser such as **Microsoft Edge** or any Store/system app.

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

Removes **all four** PUPs unconditionally — this is a fleet-wide remover, no
arguments or toggles. (That includes Shift Browser; see
[the Shift Browser note](#the-shift-browser-note).)

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

Both scripts write `PUPRemover_<timestamp>.csv` and `.log`. The CSV columns
are `PUP, Category, Status, Item, Detail`.

- **`PUPRemover-Test.ps1`** writes to the **running user's `Downloads`**
  folder (easy to grab during testing).
- **`PUPRemover-S1.ps1`** writes to the first writable of
  `%ProgramData%\PUPRemover\Logs`, then `%TEMP%\PUPRemover`, then
  `.\PUPRemover-logs` — because under SYSTEM there is no user Downloads
  folder, and SentinelOne collects the console output regardless.

## The Shift Browser note

Shift Browser is removed by default alongside the other three. One thing to
know going in: Shift Browser (Redbrick / **Shift Technologies, Inc.**) is
**code-signed by the same publisher as, and installs to the same paths as, a
legitimate paid workspace browser** (`%LOCALAPPDATA%\Shift\chromium\`,
`shift.exe`, `shift_pwa_launcher.exe`, uninstall name "Shift"). What AV
vendors flag as `PUP.Optional.ShiftBrowser` appears to be Redbrick's own
installer, flagged for its misleading-ad distribution — Malwarebytes has
shipped false positives on it.

**No signature or path test can separate an unwanted bundled install from one
a user chose**, so removing Shift by default means a *purposely-installed*
Shift is removed too. That's the accepted trade-off for a fleet-wide remover —
just be aware of it, and if any machine in scope might run the paid Shift on
purpose, test there first.

What this does **not** put at risk is unrelated software: matching uses only
**hard, install-path-anchored indicators** — the exact path shape
(`\Shift\chromium\`, `\ShiftData\`), exact process names, the
`Shift Technologies` publisher string, and the campaign's installer/dropper
filenames — **never a bare `shift`**. So `redshift`, `openshift`, `ShiftN`,
`shift-qt`, and Teams `Shifts` are never touched; only real Shift Browser
installs are. There is **no** product called "Shift Printer" — the printer/PDF
angle is just the fake-download lure (`recipes_*.exe` / `pdf_*.exe`).

## False-positive safety

Match patterns never fire on the bare tokens `wave`, `blazer`,
`webnavigator`, or `shift`. Verified by `tests/test-patterns.ps1` against a
corpus of real collisions: Waves MaxxAudio (`WavesSvc*`), Wavebox, WavePad,
GoldWave, Elgato Wave Link, Adobe Shockwave, **Siemens SIMATIC WinCC
WebNavigator (SCADA)**, BlazeRush, Trailblazer, Redshift, OpenShift, ShiftN,
`shift-qt`, and ordinary user files.
Additional safeguards: folder names are matched **exactly** (no filesystem
wildcards); a user's own `C:\Users\<x>\Blazer` folder is never touched;
shortcuts are removed **only** when their resolved target points at a PUP path
(never on name alone); MSIX/Store uninstall is disabled by default and can
never touch Microsoft/first-party packages; and match blobs are `|`-joined so
a pattern can't span two fields.

**Removal reporting.** A removal that finds its target *already gone* — a key
caught by two sweeps, a parent folder that took a child with it, or a process
that exited before we killed it — is reported as removed, not failed. Only
genuine errors (a **locked/in-use file**, access denied) count as failures and
drive the exit-2 "reboot and re-run" signal. Registry keys found by more than
one sweep are de-duplicated so each is listed once.

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
