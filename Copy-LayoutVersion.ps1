param(
    [string]$Release = "VS2026Pro",

    [string]$ConfigPath = ".\VSLayouts.json",

    [string]$SourceRoot = ".\VSLayout",

    [string]$DestinationPath = "C:\VSLayout",

    [bool]$Mirror = $true
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

# This script writes into a locked destination and must run elevated.
$currentIdentity = [Security.Principal.WindowsIdentity]::GetCurrent()
$principal = New-Object Security.Principal.WindowsPrincipal($currentIdentity)
$isAdmin = $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    throw "This script must be run from an elevated PowerShell session (Run as Administrator)."
}

$scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path

$resolvedConfigPath = if ([System.IO.Path]::IsPathRooted($ConfigPath)) {
    $ConfigPath
}
else {
    Join-Path $scriptRoot $ConfigPath
}

$resolvedSourceRoot = if ([System.IO.Path]::IsPathRooted($SourceRoot)) {
    $SourceRoot
}
else {
    Join-Path $scriptRoot $SourceRoot
}

if (-not (Test-Path -LiteralPath $resolvedConfigPath)) {
    throw "Config file not found at '$resolvedConfigPath'."
}

$layouts = Get-Content -Raw -LiteralPath $resolvedConfigPath | ConvertFrom-Json
$selectedLayout = $layouts | Where-Object { $_.Release -ieq $Release } | Select-Object -First 1

if (-not $selectedLayout) {
    $validReleases = ($layouts | Select-Object -ExpandProperty Release) -join ", "
    throw "Release '$Release' was not found in '$resolvedConfigPath'. Valid releases: $validReleases"
}

$sourcePath = Join-Path $resolvedSourceRoot $selectedLayout.Folder
if (-not (Test-Path -LiteralPath $sourcePath)) {
    throw "Source layout folder not found at '$sourcePath'."
}

# create/initial lock
New-Item -Path $DestinationPath -ItemType Directory -Force | Out-Null
icacls $DestinationPath /inheritance:r | Out-Null
icacls $DestinationPath `
    /grant 'SYSTEM:(OI)(CI)RX' `
    /grant 'BUILTIN\Administrators:(OI)(CI)F' `
    /grant 'Authenticated Users:(OI)(CI)RX' | Out-Null
icacls $DestinationPath /remove 'Users' | Out-Null
icacls $DestinationPath /remove 'Everyone' | Out-Null


try {
    icacls $DestinationPath /grant 'BUILTIN\Administrators:(OI)(CI)F' | Out-Null
    
    $robocopyArgs = @(
        $sourcePath,
        $DestinationPath,
        "/E",
        "/COPY:DAT",
        "/DCOPY:DAT",
        "/R:2",
        "/W:2",
        "/NP"
    )

    if ($Mirror) {
        $robocopyArgs += "/MIR"
    }

    Write-Output ("Running robocopy: {0}" -f ($robocopyArgs -join " "))
    & robocopy @robocopyArgs | Out-Host
    $robocopyExitCode = $LASTEXITCODE
    Write-Output "Robocopy exit code: $robocopyExitCode"

    $robocopyStatus = switch ($robocopyExitCode) {
        0 { "No files were copied; source and destination are already in sync." }
        1 { "Files were copied successfully." }
        2 { "Extra files or directories detected in destination." }
        3 { "Files copied and extra files/directories detected." }
        4 { "Mismatched files/directories detected." }
        5 { "Files copied and mismatches detected." }
        6 { "Mismatches and extra files/directories detected." }
        7 { "Files copied with mismatches and extra files/directories detected." }
        default { "Robocopy reported a failure." }
    }
    Write-Output "Robocopy status: $robocopyStatus"

    # Robocopy uses non-zero success codes; only >7 indicates failure.
    if ($robocopyExitCode -gt 7) {
        throw "Robocopy failed with exit code $robocopyExitCode."
    }
}
finally {
    icacls $DestinationPath `
        /grant 'SYSTEM:(OI)(CI)RX' `
        /grant 'BUILTIN\Administrators:(OI)(CI)RX' `
        /grant 'Authenticated Users:(OI)(CI)RX' | Out-Null
}


Write-Output "Copied release '$($selectedLayout.Release)' from '$sourcePath' to '$DestinationPath'."
