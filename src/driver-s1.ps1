# ===========================================================================
# S1 auto driver (appended after PUPCore by build.ps1).
#
# SentinelOne runs this as SYSTEM, non-interactively. It scans, reports what
# it found (paths, registry keys, tasks, ...), removes everything, reports the
# per-item result, writes a CSV+log, and exits with a machine-readable code:
#   0 = clean, or everything removed successfully
#   2 = one or more removals failed (reboot the endpoint and re-run)
# Deploy via:  powershell.exe -ExecutionPolicy Bypass -File PUPRemover-S1.ps1
# ===========================================================================

# This is a fleet-wide remover: all four PUPs are removed unconditionally.
# NOTE on Shift Browser — it is code-signed by the same publisher as, and
# installs to the same paths as, a legitimate paid product, so including it
# here means a deliberately-installed Shift is also removed. That is the
# intended behaviour for this tool. Matching is still install-path-anchored,
# so unrelated software (redshift / openshift / ShiftN / Teams Shifts) is
# never touched — only actual Shift Browser installs.
$stamp   = Get-Date -Format 'yyyyMMdd_HHmmss'
$targets = @('WaveBrowser', 'Blazer', 'CrystalPDF', 'ShiftBrowser')

Write-Host "PUPRemover — SentinelOne auto mode"
Write-Host ("Run: {0}   Targets: {1}" -f $stamp, ($targets -join ', '))

$findings = @(Invoke-PUPScan -Target $targets)

if ($findings.Count -eq 0) {
    Write-Host "`nClean — no PUP artifacts found." -ForegroundColor Green
    exit 0
}

Write-PUPFindings -Finding $findings -Title 'ARTIFACTS FOUND'

Write-Host "`n=== REMOVING ===" -ForegroundColor Cyan
Invoke-PUPRemoval -Finding $findings | Out-Null
Write-PUPFindings -Finding $findings -Title 'REMOVAL RESULT'

foreach ($note in (Get-PUPPostRemovalNotes -Finding $findings)) { Write-Warning $note }

$report = Export-PUPReport -Finding $findings -Stamp $stamp
if ($report.Count -gt 0) { Write-Host ("`nReport written: {0}" -f ($report -join '  ;  ')) }

$removed = @($findings | Where-Object { $_.Status -eq 'Removed' }).Count
$failed  = @($findings | Where-Object { $_.Status -eq 'Failed' }).Count
Write-Host ("`nSummary: {0} found, {1} removed, {2} failed." -f $findings.Count, $removed, $failed)

if ($failed -gt 0) {
    Write-Warning "$failed removal(s) failed — a reboot may release locked files. Reboot the endpoint and re-run."
    exit 2
}
exit 0
