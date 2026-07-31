# ===========================================================================
# S1 auto driver (appended after PUPCore by build.ps1).
#
# SentinelOne runs this as SYSTEM, non-interactively, and captures the script's
# console as the run output. So this prints context first (notes, report path,
# warnings) and the REMOVAL RESULTS block LAST — the last thing in the console
# is always "what was removed", which is what shows in the S1 run output.
# Exit code: 0 = clean or everything removed; 2 = one or more removals failed
# (reboot the endpoint and re-run).
# Deploy via:  powershell.exe -ExecutionPolicy Bypass -File PUPRemover-S1.ps1
# ===========================================================================

# This is a fleet-wide remover: all targeted PUPs are removed unconditionally.
# NOTE on Shift Browser — it is code-signed by the same publisher as, and
# installs to the same paths as, a legitimate paid product, so including it
# here means a deliberately-installed Shift is also removed. That is the
# intended behaviour for this tool. Matching is install-path-anchored (and a
# protected-locations backstop refuses to touch Windows/Office/browser paths),
# so unrelated software is never removed — only actual PUP installs.
$stamp   = Get-Date -Format 'yyyyMMdd_HHmmss'
$targets = @('WaveBrowser', 'Blazer', 'ShiftBrowser', 'AceAIBrowser', 'PulseBrowser')

Write-Host "PUPRemover — SentinelOne auto mode"
Write-Host ("Run: {0}   Targets: {1}" -f $stamp, ($targets -join ', '))

$findings = @(Invoke-PUPScan -Target $targets)

if ($findings.Count -eq 0) {
    Write-Host "`n===== PUPRemover RESULTS ====="
    Write-Host "Clean — no PUP artifacts found. 0 removed, 0 failed."
    exit 0
}

Write-Host ("`nFound {0} artifact(s) — removing..." -f $findings.Count)
Invoke-PUPRemoval -Finding $findings | Out-Null

# --- Context first, so the results block below is the LAST thing printed ---
foreach ($note in (Get-PUPPostRemovalNotes -Finding $findings)) { Write-Host "NOTE: $note" }

$report = Export-PUPReport -Finding $findings -Stamp $stamp
if ($report.Count -gt 0) { Write-Host ("Report written: {0}" -f ($report -join '  ;  ')) }

$removed = @($findings | Where-Object { $_.Status -eq 'Removed' }).Count
$failed  = @($findings | Where-Object { $_.Status -eq 'Failed'  }).Count
$skipped = @($findings | Where-Object { $_.Status -eq 'Skipped' }).Count
if ($failed -gt 0) {
    Write-Host "WARNING: $failed removal(s) failed — a reboot may release locked files; reboot the endpoint and re-run."
}
if ($skipped -gt 0) {
    Write-Host "NOTE: $skipped item(s) matched a protected location and were left untouched — review the patterns."
}

# --- FINAL BLOCK: the removal results (last thing in the S1 console) ---
Write-PUPFindings -Finding $findings -Title 'PUPRemover RESULTS'
Write-Host ("`n===== PUPRemover: {0} removed, {1} failed, {2} skipped ({3} found) =====" -f `
    $removed, $failed, $skipped, $findings.Count)

if ($failed -gt 0) { exit 2 }
exit 0
