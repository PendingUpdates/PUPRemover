# ===========================================================================
# Interactive testing driver (appended after PUPCore by build.ps1).
#
# Human-in-the-loop tool for the closed test system. Menu:
#   1. Full Scan  — scan for every PUP, list findings, then remove all or a
#                   chosen subset of apps.
#   2. Select App — pick which app(s) to scan for, list findings, then remove
#                   just those.
#   3. Exit
# Every scan lists the apps found with their paths, registry keys, tasks, and
# shortcuts; every removal shows per-item success/failure and writes a
# CSV + log. Run in an elevated console to cover all profiles:
#   powershell.exe -ExecutionPolicy Bypass -File PUPRemover-Test.ps1
# ===========================================================================

function Write-Banner {
    Write-Host ''
    Write-Host '  ==============================================' -ForegroundColor Cyan
    Write-Host '   PUPRemover — interactive test console' -ForegroundColor Cyan
    Write-Host '  ==============================================' -ForegroundColor Cyan
}

# Parse a "1,3" / "1 3" / "all" selection against $script:PupNames.
# Returns an array of PUP names, or $null if the input was invalid/empty.
function Read-AppSelection {
    param([string]$Prompt)
    for ($i = 0; $i -lt $script:PupNames.Count; $i++) {
        Write-Host ("    {0}. {1}" -f ($i + 1), $script:PupNames[$i])
    }
    Write-Host '    (enter numbers separated by comma/space, or "all")'
    $raw = (Read-Host $Prompt).Trim()
    if (-not $raw) { return $null }
    if ($raw -match '^(?i)all$') { return @($script:PupNames) }

    $picked = New-Object System.Collections.Generic.List[string]
    foreach ($tok in ($raw -split '[,\s]+' | Where-Object { $_ })) {
        if ($tok -notmatch '^\d+$') { Write-Host "    '$tok' is not a number." -ForegroundColor Red; return $null }
        $idx = [int]$tok
        if ($idx -lt 1 -or $idx -gt $script:PupNames.Count) {
            Write-Host "    '$tok' is out of range." -ForegroundColor Red; return $null
        }
        $name = $script:PupNames[$idx - 1]
        if ($name -notin $picked) { $picked.Add($name) }
    }
    if ($picked.Count -eq 0) { return $null }
    return @($picked)
}

# Run the removal for a set of findings and report the result + log.
function Invoke-RemovalWithReport {
    param([object[]]$Finding, [string]$Stamp)
    if (@($Finding).Count -eq 0) {
        Write-Host '  Nothing selected to remove.' -ForegroundColor Yellow
        return
    }
    Write-Host ("`n  Removing {0} artifact(s)..." -f @($Finding).Count) -ForegroundColor Cyan
    Invoke-PUPRemoval -Finding $Finding | Out-Null
    Write-PUPFindings -Finding $Finding -Title 'REMOVAL RESULT'

    foreach ($note in (Get-PUPPostRemovalNotes -Finding $Finding)) { Write-Warning $note }

    # Interactive test runs drop their report in the running user's Downloads.
    $downloads = Join-Path $env:USERPROFILE 'Downloads'
    $report = Export-PUPReport -Finding $Finding -Stamp $Stamp -Directory $downloads
    if ($report.Count -gt 0) { Write-Host ("`n  Report written: {0}" -f ($report -join '  ;  ')) -ForegroundColor DarkGray }

    $removed = @($Finding | Where-Object { $_.Status -eq 'Removed' }).Count
    $failed  = @($Finding | Where-Object { $_.Status -eq 'Failed' }).Count
    Write-Host ("  Result: {0} removed, {1} failed." -f $removed, $failed) -ForegroundColor White
    if ($failed -gt 0) {
        Write-Host '  Some removals failed — a reboot may release locked files; re-run afterward.' -ForegroundColor Red
    }
}

# --- Full Scan flow -------------------------------------------------------
function Invoke-FullScanFlow {
    $stamp = Get-Date -Format 'yyyyMMdd_HHmmss'
    Write-Host "`n  Scanning for all PUPs..." -ForegroundColor Cyan
    $findings = @(Invoke-PUPScan -Target $script:PupNames)

    if ($findings.Count -eq 0) {
        Write-Host "`n  Clean — no PUP artifacts found." -ForegroundColor Green
        return
    }
    Write-PUPFindings -Finding $findings -Title 'ARTIFACTS FOUND'

    $foundPups = @($findings | Select-Object -ExpandProperty PUP -Unique | Sort-Object)
    Write-Host ("`n  Found: {0}" -f ($foundPups -join ', ')) -ForegroundColor White
    Write-Host '  Remove:  [A]ll found   [S]elect apps   [C]ancel'
    $choice = (Read-Host '  Choice').Trim()

    switch -Regex ($choice) {
        '^(?i)a' { Invoke-RemovalWithReport -Finding $findings -Stamp $stamp }
        '^(?i)s' {
            Write-Host '  Which apps to remove?'
            # Restrict the selectable list to apps that actually had findings.
            $savedNames = $script:PupNames
            try {
                $script:PupNames = $foundPups
                $chosen = Read-AppSelection -Prompt '  Apps'
            }
            finally { $script:PupNames = $savedNames }
            if (-not $chosen) { Write-Host '  No valid selection — nothing removed.' -ForegroundColor Yellow; return }
            $subset = @($findings | Where-Object { $_.PUP -in $chosen })
            Invoke-RemovalWithReport -Finding $subset -Stamp $stamp
        }
        default { Write-Host '  Cancelled — nothing removed.' -ForegroundColor Yellow }
    }
}

# --- Select App flow ------------------------------------------------------
function Invoke-SelectAppFlow {
    $stamp = Get-Date -Format 'yyyyMMdd_HHmmss'
    Write-Host "`n  Select app(s) to scan for:"
    $chosen = Read-AppSelection -Prompt '  Apps'
    if (-not $chosen) { Write-Host '  No valid selection.' -ForegroundColor Yellow; return }

    Write-Host ("`n  Scanning for: {0}" -f ($chosen -join ', ')) -ForegroundColor Cyan
    $findings = @(Invoke-PUPScan -Target $chosen)

    if ($findings.Count -eq 0) {
        Write-Host "`n  Clean — no artifacts found for the selected app(s)." -ForegroundColor Green
        return
    }
    Write-PUPFindings -Finding $findings -Title 'ARTIFACTS FOUND'

    $ans = (Read-Host "`n  Remove these artifact(s)? [Y]es / [N]o").Trim()
    if ($ans -match '^(?i)y') { Invoke-RemovalWithReport -Finding $findings -Stamp $stamp }
    else { Write-Host '  Cancelled — nothing removed.' -ForegroundColor Yellow }
}

# --- Main menu loop -------------------------------------------------------
Write-Banner
$ctx = Get-PUPContext
if (-not $ctx.IsAdmin) {
    Write-Host '  NOTE: not elevated — only the current user profile/hive is covered.' -ForegroundColor Yellow
    Write-Host '        Re-launch as administrator to scan all profiles.' -ForegroundColor Yellow
}

$running = $true
while ($running) {
    Write-Host ''
    Write-Host '  Menu:' -ForegroundColor Cyan
    Write-Host '    1. Full Scan'
    Write-Host '    2. Select App'
    Write-Host '    3. Exit'
    $sel = (Read-Host '  Select 1-3').Trim()
    switch ($sel) {
        '1' { Invoke-FullScanFlow }
        '2' { Invoke-SelectAppFlow }
        '3' { $running = $false }
        default { Write-Host '  Enter 1, 2, or 3.' -ForegroundColor Red }
    }
}
Write-Host "`n  Done." -ForegroundColor Green
