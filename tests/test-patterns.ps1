# Unit tests for the PUP match/process patterns. Runs anywhere pwsh runs
# (no Windows required) — it dot-sources the engine and exercises the regexes
# against a corpus of real PUP artifacts (must match) and legitimate
# software / user content (must NOT match).
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot '../src/PUPCore.ps1')

Write-Host ("DEFS: loaded {0} PUP definitions" -f $PupDefinitions.Count) -ForegroundColor Green

$wave    = $PupDefinitions | Where-Object { $_.Name -eq 'WaveBrowser' }
$blazer  = $PupDefinitions | Where-Object { $_.Name -eq 'Blazer' }
$shift   = $PupDefinitions | Where-Object { $_.Name -eq 'ShiftBrowser' }
$ace     = $PupDefinitions | Where-Object { $_.Name -eq 'AceAIBrowser' }

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

# --- ShiftBrowser InstallerPattern (Downloads/Desktop .exe/.msi only) ---
Assert-Match $shift 'InstallerPattern' 'Shift_qf3xyw.exe' $true 'Shift_<hash> installer'
Assert-Match $shift 'InstallerPattern' 'Shift-127.4.0-Production.Web.exe' $true 'versioned installer'
Assert-Match $shift 'InstallerPattern' 'shift-v127.0.0-web.exe' $true 'versioned installer variant'
Assert-Match $shift 'InstallerPattern' 'redshift-setup.exe' $false 'Redshift installer'
Assert-Match $shift 'InstallerPattern' 'ShiftN-1.0-setup.exe' $false 'ShiftN installer'
Assert-Match $shift 'InstallerPattern' 'my-shift-notes.exe' $false 'shift not at start'

# --- RegNamePattern: browser-registration key names (from RegShot data) ---
# Blazer registration keys that MatchPattern misses (bare 'Blazer' + hash):
Assert-Match $blazer 'RegNamePattern' 'Blazer.VT36H75ACA5P33DTFPY7PHK46Q' $true 'StartMenuInternet\Blazer.<hash>'
Assert-Match $blazer 'RegNamePattern' 'BlazerHTM.VT36H75ACA5P33DTFPY7PHK46Q' $true 'Classes\BlazerHTM.<hash>'
Assert-Match $blazer 'RegNamePattern' 'BlazerPDF.VT36H75ACA5P33DTFPY7PHK46Q' $true 'Classes\BlazerPDF.<hash>'
Assert-Match $blazer 'RegNamePattern' 'W~Blazer.VT36H75ACA5P33DTFPY7PHK46Q' $true 'Start tile W~Blazer.<hash>'
Assert-Match $blazer 'RegNamePattern' 'Blazer' $true 'bare Blazer registration key'
Assert-Match $blazer 'RegNamePattern' 'Trailblazer' $false 'Trailblazer'
Assert-Match $blazer 'RegNamePattern' 'BlazeRush' $false 'BlazeRush'
Assert-Match $blazer 'RegNamePattern' 'blazerush' $false 'blazerush lowercase'
# Shift registration key names:
Assert-Match $shift 'RegNamePattern' 'Shift' $true 'StartMenuInternet\Shift'
Assert-Match $shift 'RegNamePattern' 'W~Shift.abc12345def' $true 'Start tile W~Shift.<hash>'
Assert-Match $shift 'RegNamePattern' 'redshift' $false 'redshift'
Assert-Match $shift 'RegNamePattern' 'openshift' $false 'openshift'
Assert-Match $shift 'RegNamePattern' 'ShiftN' $false 'ShiftN'
Assert-Match $shift 'RegNamePattern' 'Shifty' $false 'Shifty'

# --- ACE AI Browser: must match (install-path / compound anchored) ---
Assert-Match $ace 'MatchPattern' 'C:\Users\bob\AppData\Local\Ace\Ace\Application\ace.exe' $true 'browser install path'
Assert-Match $ace 'MatchPattern' 'C:\Users\bob\AppData\Local\Ace\AceUpdater\143.0\updater.exe' $true 'updater path'
Assert-Match $ace 'MatchPattern' '"C:\Program Files (x86)\Ace\AceUpdater\1.0\updater.exe" --wake --system' $true 'AceUpdater service binary path'
Assert-Match $ace 'MatchPattern' 'C:\Users\bob\AppData\Local\AceLauncher\Application\AceLauncher.exe' $true 'AceLauncher path'
Assert-Match $ace 'MatchPattern' 'Ace Browser' $true 'uninstall DisplayName'
Assert-Match $ace 'MatchPattern' 'Ace AI Browser' $true 'brand compound'
Assert-Match $ace 'MatchPattern' 'com.acelauncher.dock' $true 'Run value name'
Assert-Match $ace 'MatchPattern' 'Ace Browser Shield' $true 'bundled extension'
Assert-Match $ace 'MatchPattern' 'AceSetup.exe' $true 'installer'
Assert-Match $ace 'ProcessPattern' 'AceLauncher' $true 'launcher process'
Assert-Match $ace 'ProcessPattern' 'AceLauncherUpdater' $true 'launcher updater process'
Assert-Match $ace 'InstallerPattern' 'AceSetup.exe' $true 'AceSetup installer'
Assert-Match $ace 'InstallerPattern' 'Templates_AceLauncher.exe' $true 'lure dropper'
Assert-Match $ace 'InstallerPattern' 'AceLauncherInstaller.exe' $true 'launcher installer'
Assert-Match $ace 'RegNamePattern' 'AceHTM.VT36H75ACA5P33DTFPY7PHK46Q' $true 'Classes AceHTM.<hash>'
Assert-Match $ace 'RegNamePattern' 'AcePDF.VT36H75ACA5P33DTFPY7PHK46Q' $true 'Classes AcePDF.<hash>'
Assert-Match $ace 'RegNamePattern' 'Ace.VT36H75ACA5P33DTFPY7PHK46Q' $true 'StartMenuInternet Ace.<hash>'
Assert-Match $ace 'RegNamePattern' 'W~Ace.VT36H75ACA5P33DTFPY7PHK46Q' $true 'Start tile W~Ace.<hash>'
# --- ACE AI Browser: must NOT match (the dangerous collisions) ---
Assert-Match $ace 'MatchPattern' 'Microsoft.ACE.OLEDB.12.0' $false 'Access Database Engine ProgID'
Assert-Match $ace 'MatchPattern' 'Microsoft.ACE.OLEDB.16.0' $false 'Access DB Engine 16'
Assert-Match $ace 'MatchPattern' 'C:\Program Files\Common Files\Microsoft Shared\OFFICE16\ACEDAO\ACEOLEDB.DLL' $false 'ACE*.DLL office path'
Assert-Match $ace 'MatchPattern' 'C:\Program Files\Acer\Acer Care Center\AcerCCTMon.exe' $false 'Acer OEM'
Assert-Match $ace 'MatchPattern' 'C:\Program Files\Surface\SurfaceDTX.exe' $false 'Microsoft Surface'
Assert-Match $ace 'MatchPattern' 'C:\Users\bob\AppData\Local\ACEStream\ace_engine.exe' $false 'ACEStream'
Assert-Match $ace 'MatchPattern' 'C:\Program Files\AceReader Pro\ace.exe' $false 'AceReader Pro'
Assert-Match $ace 'MatchPattern' 'C:\WINDOWS\system32\svchost.exe -k netsvcs -p' $false 'legit service binary path'
Assert-Match $ace 'MatchPattern' '"C:\Program Files\Acer\Care Center\ACCSvc.exe"' $false 'Acer service binary path'
Assert-Match $ace 'MatchPattern' 'HKLM\SOFTWARE\Microsoft\Tracing\Interfaces' $false 'interface/tracing substring'
Assert-Match $ace 'MatchPattern' 'race results.xlsx' $false 'user file substring'
Assert-Match $ace 'ProcessPattern' 'Acer' $false 'Acer process'
Assert-Match $ace 'ProcessPattern' 'ace' $false 'bare ace (AceReader) — path-matched only'
Assert-Match $ace 'ProcessPattern' 'ace_engine' $false 'ACEStream process'
Assert-Match $ace 'RegNamePattern' 'Acer' $false 'Acer key'
Assert-Match $ace 'RegNamePattern' 'AceStream' $false 'AceStream ProgID'
Assert-Match $ace 'RegNamePattern' 'Microsoft.ACE.OLEDB.12.0' $false 'Access DB Engine ProgID (RegName)'
Assert-Match $ace 'RegNamePattern' 'AceText.Document' $false 'AceText ProgID'
Assert-Match $ace 'InstallerPattern' 'AceReaderProSetup.exe' $false 'AceReader installer'
Assert-Match $ace 'InstallerPattern' 'spacelauncher.exe' $false 'spacelauncher substring'

# --- Crystal PDF fully removed from the project ---
if ($PupDefinitions | Where-Object { $_.Name -eq 'CrystalPDF' }) {
    $failures++; Write-Host "  FAIL: CrystalPDF should no longer be a definition" -ForegroundColor Red
}
if ((Get-Command Invoke-PUPScan).Parameters['Target'].Attributes |
        Where-Object { $_ -is [System.Management.Automation.ValidateSetAttribute] -and 'CrystalPDF' -in $_.ValidValues }) {
    $failures++; Write-Host "  FAIL: CrystalPDF still in the -Target ValidateSet" -ForegroundColor Red
}

# --- ConvertTo-CanonicalRegPath: vendor-key path and PSPath collapse to one ---
$c1 = ConvertTo-CanonicalRegPath 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\WaveBrowser'
$c2 = ConvertTo-CanonicalRegPath 'Microsoft.PowerShell.Core\Registry::HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Uninstall\WaveBrowser'
if ($c1 -ne $c2) { $failures++; Write-Host "  FAIL: canonical reg paths differ: '$c1' vs '$c2'" -ForegroundColor Red }
$h1 = ConvertTo-CanonicalRegPath 'Registry::HKEY_USERS\S-1-5-21-1\Software\Shift'
$h2 = ConvertTo-CanonicalRegPath 'Microsoft.PowerShell.Core\Registry::HKEY_USERS\S-1-5-21-1\Software\Shift'
if ($h1 -ne $h2) { $failures++; Write-Host "  FAIL: canonical HKU paths differ: '$h1' vs '$h2'" -ForegroundColor Red }

# --- Invoke-PUPRemoval: 'already gone' (ObjectNotFound) counts as Removed ---
$missing = Join-Path ([IO.Path]::GetTempPath()) '__pup_no_such_target__.tmp'
$gone = [PSCustomObject]@{ PUP='X'; Category='RegistryKey'; Item='k'; Status='Detected'; Detail=''; Phase=3;
    RemoveAction = { Remove-Item -LiteralPath $missing -ErrorAction Stop }.GetNewClosure() }
$locked = [PSCustomObject]@{ PUP='X'; Category='Folder'; Item='f'; Status='Detected'; Detail=''; Phase=3;
    RemoveAction = { throw (New-Object System.Management.Automation.RuntimeException 'Access to the path is denied.') } }
Invoke-PUPRemoval -Finding @($gone, $locked) | Out-Null
if ($gone.Status -ne 'Removed') { $failures++; Write-Host "  FAIL: not-found removal should be 'Removed', got '$($gone.Status)'" -ForegroundColor Red }
if ($locked.Status -ne 'Failed') { $failures++; Write-Host "  FAIL: genuine error should stay 'Failed', got '$($locked.Status)'" -ForegroundColor Red }

if ($failures -eq 0) {
    Write-Host "PATTERNS: all assertions passed" -ForegroundColor Green
    exit 0
} else {
    Write-Host ("PATTERNS: {0} assertion(s) FAILED" -f $failures) -ForegroundColor Red
    exit 1
}
