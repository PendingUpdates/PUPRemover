# Unit tests for the PUP match/process patterns. Runs anywhere pwsh runs
# (no Windows required) — it dot-sources the engine and exercises the regexes
# against a corpus of real PUP artifacts (must match) and legitimate
# software / user content (must NOT match).
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot '../src/PUPCore.ps1')

Write-Host ("DEFS: loaded {0} PUP definitions" -f $PupDefinitions.Count) -ForegroundColor Green

$wave    = $PupDefinitions | Where-Object { $_.Name -eq 'WaveBrowser' }
$blazer  = $PupDefinitions | Where-Object { $_.Name -eq 'Blazer' }
$crystal = $PupDefinitions | Where-Object { $_.Name -eq 'CrystalPDF' }
$shift   = $PupDefinitions | Where-Object { $_.Name -eq 'ShiftBrowser' }

$failures = 0
function Assert-Match($def, $field, $text, $expected, $why) {
    $actual = [bool]($text -match $def.$field)
    if ($actual -ne $expected) {
        $script:failures++
        Write-Host ("  FAIL [{0}.{1}] '{2}' matched={3} expected={4}  ({5})" -f $def.Name, $field, $text, $actual, $expected, $why) -ForegroundColor Red
    }
}

# --- WaveBrowser: must match ---
Assert-Match $wave 'MatchPattern' 'WaveBrowser' $true 'install folder'
Assert-Match $wave 'MatchPattern' 'Wave Browser' $true 'uninstall DisplayName'
Assert-Match $wave 'MatchPattern' 'Wavesor Software' $true 'profile-root folder'
Assert-Match $wave 'MatchPattern' 'WavesorSWUpdaterTaskUserS-1-5-21-1234567890-1001UA' $true 'scheduled task'
Assert-Match $wave 'MatchPattern' 'Wavesor SWUpdater' $true 'Run value name'
Assert-Match $wave 'MatchPattern' 'SWUpdaterTaskUserS-1-5-21-999Core' $true 'task variant'
Assert-Match $wave 'MatchPattern' 'WaveBrowser.5QMLTPZDDJG2BQZHV26QUN4ZK4' $true 'hashed StartMenuInternet client'
Assert-Match $wave 'MatchPattern' 'WaveBrwsHTM.ABC123' $true 'ProgId class'
Assert-Match $wave 'MatchPattern' 'WebNavigatorBrowser' $true 'sibling PUP'
Assert-Match $wave 'ProcessPattern' 'wavebrowser' $true 'browser process'
Assert-Match $wave 'ProcessPattern' 'webnavigatorbrowser' $true 'sibling PUP process'
# --- WaveBrowser: must NOT match ---
Assert-Match $wave 'MatchPattern' 'WavesSvc64' $false 'Waves MaxxAudio (Dell)'
Assert-Match $wave 'MatchPattern' 'Waves Audio' $false 'Waves Audio folder'
Assert-Match $wave 'MatchPattern' 'WaveLink' $false 'Elgato Wave Link'
Assert-Match $wave 'MatchPattern' 'wavebox' $false 'Wavebox browser'
Assert-Match $wave 'MatchPattern' 'WaveboxApp' $false 'Wavebox app folder'
Assert-Match $wave 'MatchPattern' 'wavepad' $false 'NCH WavePad'
Assert-Match $wave 'MatchPattern' 'GoldWave' $false 'GoldWave'
Assert-Match $wave 'MatchPattern' 'Waveform12' $false 'Tracktion Waveform'
Assert-Match $wave 'MatchPattern' 'Shockwave 12' $false 'Adobe Shockwave'
Assert-Match $wave 'MatchPattern' 'Wave Systems Corp' $false 'Wave Systems TPM'
Assert-Match $wave 'MatchPattern' 'Heat Waves.mp3' $false 'user music'
Assert-Match $wave 'MatchPattern' 'SIMATIC WinCC/WebNavigator Client 7.5 SP2' $false 'Siemens WinCC WebNavigator (SCADA)'
Assert-Match $wave 'MatchPattern' 'C:\Program Files\Siemens\WinCC\WebNavigator\Client\bin\WinCCViewerRT.exe' $false 'WinCC path'
Assert-Match $wave 'ProcessPattern' 'WebNavigator' $false 'Siemens WebNavigator process'
Assert-Match $wave 'ProcessPattern' 'WavesSvc64' $false 'Waves process'
Assert-Match $wave 'ProcessPattern' 'wavebox' $false 'Wavebox process'
Assert-Match $wave 'MatchPattern' 'XYZ Wave | Browser Co' $false 'blob field spanning'

# --- Blazer: must match ---
Assert-Match $blazer 'MatchPattern' 'BlazerBrowserUpdateTask' $true 'scheduled task'
Assert-Match $blazer 'MatchPattern' 'Blazer Browser' $true 'uninstall DisplayName'
Assert-Match $blazer 'MatchPattern' 'blazer.exe' $true 'main exe'
Assert-Match $blazer 'MatchPattern' 'blazer_updater.exe' $true 'updater exe'
Assert-Match $blazer 'MatchPattern' 'blazer_installer_g79NL89y.exe' $true 'installer'
Assert-Match $blazer 'MatchPattern' 'C:\Users\bob\AppData\Local\Blazer\Application\new_blazer.exe' $true 'process path'
Assert-Match $blazer 'MatchPattern' 'C:\Users\bob\AppData\Local\Blazer\Application\new_blazer_proxy.exe --auto-launch' $true 'Run data'
Assert-Match $blazer 'ProcessPattern' 'blazer' $true 'process'
Assert-Match $blazer 'ProcessPattern' 'new_blazer' $true 'new_blazer process'
Assert-Match $blazer 'ProcessPattern' 'new_blazer_proxy' $true 'proxy process'
Assert-Match $blazer 'ProcessPattern' 'blazer_updater' $true 'updater process'
# --- Blazer: must NOT match ---
Assert-Match $blazer 'MatchPattern' 'Blazer' $false 'standalone word (exact lists handle folder/keys)'
Assert-Match $blazer 'MatchPattern' 'Trailblazer' $false 'trailblazer'
Assert-Match $blazer 'MatchPattern' 'trailblazer-2.1.0' $false 'ruby gem'
Assert-Match $blazer 'MatchPattern' 'BlazeRush' $false 'steam game'
Assert-Match $blazer 'MatchPattern' 'BlazeRush.exe' $false 'steam game exe'
Assert-Match $blazer 'ProcessPattern' 'BlazeRush' $false 'steam game process'
Assert-Match $blazer 'MatchPattern' 'Blaze' $false 'different Blaze tools'
Assert-Match $blazer 'MatchPattern' 'Portland Trail Blazers wallpaper.jpg' $false 'user media'
Assert-Match $blazer 'MatchPattern' 'C:\Users\bob\Blazer\viewer.exe' $false 'user-owned Blazer folder exe'
Assert-Match $blazer 'MatchPattern' 'Chevy Blazer photos.lnk' $false 'user shortcut'

# --- CrystalPDF: must match ---
Assert-Match $crystal 'MatchPattern' 'CrystalPDF' $true 'product name'
Assert-Match $crystal 'MatchPattern' 'Crystal PDF' $true 'display name'
Assert-Match $crystal 'MatchPattern' 'Crystal_updater' $true 'persistence task'
Assert-Match $crystal 'MatchPattern' 'CrystalPDF.exe update' $true 'task action'
Assert-Match $crystal 'ProcessPattern' 'CrystalPDF' $true 'process'
Assert-Match $crystal 'ProcessPattern' 'Crystal PDF' $true 'decoy process'
# --- CrystalPDF: must NOT match ---
Assert-Match $crystal 'MatchPattern' 'CrystalDiskInfo' $false 'disk tool'
Assert-Match $crystal 'MatchPattern' 'CrystalDiskMark' $false 'benchmark'
Assert-Match $crystal 'MatchPattern' 'SAP Crystal Reports runtime engine' $false 'SAP runtime'
Assert-Match $crystal 'MatchPattern' 'Crystal Reports Cache Server' $false 'SAP service'
Assert-Match $crystal 'MatchPattern' 'Pokemon Crystal.gbc' $false 'user ROM'
Assert-Match $crystal 'MatchPattern' 'crystal.exe' $false 'Crystal language'
Assert-Match $crystal 'MatchPattern' 'MyCrystal_updater_backup' $false 'user backup task'
Assert-Match $crystal 'MatchPattern' 'SuperCrystal | PDF Tools AG' $false 'blob field spanning'

# --- ShiftBrowser: must match (install-path anchored) ---
Assert-Match $shift 'ProcessPattern' 'shift' $true 'shift.exe'
Assert-Match $shift 'ProcessPattern' 'shift_pwa_launcher' $true 'pwa launcher'
Assert-Match $shift 'MatchPattern' 'C:\Users\bob\AppData\Local\Shift\chromium\shift.exe' $true 'install path'
Assert-Match $shift 'MatchPattern' 'C:\Users\bob\AppData\Local\ShiftData' $true 'data dir'
Assert-Match $shift 'MatchPattern' 'GUID | Shift | Shift Technologies, Inc. | C:\Users\bob\AppData\Local\Shift\chromium' $true 'uninstall blob'
Assert-Match $shift 'MatchPattern' 'Shift-127.4.0-Production.Web.exe' $true 'installer'
Assert-Match $shift 'MatchPattern' 'shift-v127.0.0-web.exe' $true 'installer variant'
Assert-Match $shift 'MatchPattern' 'recipes_7uqpm.exe' $true 'dropper recipes'
Assert-Match $shift 'MatchPattern' 'Recipes.exe' $true 'dropper bare recipes'
Assert-Match $shift 'MatchPattern' 'pdf_co9mi.exe' $true 'dropper pdf'
# --- ShiftBrowser: must NOT match ---
Assert-Match $shift 'ProcessPattern' 'redshift' $false 'Redshift renderer'
Assert-Match $shift 'ProcessPattern' 'shiftn' $false 'ShiftN'
Assert-Match $shift 'ProcessPattern' 'shift-qt' $false 'SHIFT wallet'
Assert-Match $shift 'MatchPattern' 'C:\Program Files\Redshift\redshift.exe' $false 'Redshift path'
Assert-Match $shift 'MatchPattern' 'C:\Users\bob\openshift-install.exe' $false 'OpenShift'
Assert-Match $shift 'MatchPattern' 'C:\Program Files\ShiftN\ShiftN.exe' $false 'ShiftN path'
Assert-Match $shift 'MatchPattern' 'C:\Users\bob\AppData\Roaming\Microsoft\Teams\Shifts' $false 'Teams Shifts'
Assert-Match $shift 'MatchPattern' 'shift roster.xlsx' $false 'user schedule'
Assert-Match $shift 'MatchPattern' 'night shift.mp3' $false 'user media'
Assert-Match $shift 'MatchPattern' 'makeshift.exe' $false 'unrelated exe'
Assert-Match $shift 'MatchPattern' 'pdf.exe' $false 'bare pdf.exe'
Assert-Match $shift 'MatchPattern' 'RedshiftODBC | Amazon | C:\redshift' $false 'Amazon Redshift blob'

if ($failures -eq 0) {
    Write-Host "PATTERNS: all assertions passed" -ForegroundColor Green
    exit 0
} else {
    Write-Host ("PATTERNS: {0} assertion(s) FAILED" -f $failures) -ForegroundColor Red
    exit 1
}
