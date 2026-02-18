#Requires -RunAsAdministrator
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# Root folder
$Root = "G:\ABS"

# FolderPath + AD Group pair list
# NOTE: Replace the group names below with your real AD security groups.
$FolderInfo = @(
    [pscustomobject]@{ Path = "Binaries\m\Microsoft\VisualStudio\2026\Community";    Group = "DOMAIN\ABS_VS2026_Community_RO" }
    [pscustomobject]@{ Path = "Binaries\m\Microsoft\VisualStudio\2026\Professional"; Group = "DOMAIN\ABS_VS2026_Professional_RO" }
    [pscustomobject]@{ Path = "Binaries\m\Microsoft\VisualStudio\2026\Enterprise";   Group = "DOMAIN\ABS_VS2026_Enterprise_RO" }
    [pscustomobject]@{ Path = "Binaries\m\Microsoft\VisualStudio\2026\BuildTools";   Group = "DOMAIN\ABS_VS2026_BuildTools_RO" }

    [pscustomobject]@{ Path = "Binaries\m\Microsoft\VisualStudio\2022\Community";    Group = "DOMAIN\ABS_VS2022_Community_RO" }
    [pscustomobject]@{ Path = "Binaries\m\Microsoft\VisualStudio\2022\Professional"; Group = "DOMAIN\ABS_VS2022_Professional_RO" }
    [pscustomobject]@{ Path = "Binaries\m\Microsoft\VisualStudio\2022\Enterprise";   Group = "DOMAIN\ABS_VS2022_Enterprise_RO" }
    [pscustomobject]@{ Path = "Binaries\m\Microsoft\VisualStudio\2022\BuildTools";   Group = "DOMAIN\ABS_VS2022_BuildTools_RO" }

    [pscustomobject]@{ Path = "Binaries\m\Microsoft\VisualStudio\2019\Professional"; Group = "DOMAIN\ABS_VS2019_Professional_RO" }
    [pscustomobject]@{ Path = "Binaries\m\Microsoft\VisualStudio\2019\Enterprise";   Group = "DOMAIN\ABS_VS2019_Enterprise_RO" }
    [pscustomobject]@{ Path = "Binaries\m\Microsoft\VisualStudio\2019\BuildTools";   Group = "DOMAIN\ABS_VS2019_BuildTools_RO" }

    [pscustomobject]@{ Path = "Binaries\m\Microsoft\VisualStudio\2017\Enterprise";   Group = "DOMAIN\ABS_VS2017_Enterprise_RO" }
)

function Add-ReadOnlyAcl {
    param(
        [Parameter(Mandatory)]
        [string]$Path,

        [Parameter(Mandatory)]
        [string]$Identity
    )

    # Read-only is typically ReadAndExecute + Synchronize
    $rights = [System.Security.AccessControl.FileSystemRights]::ReadAndExecute `
            -bor [System.Security.AccessControl.FileSystemRights]::Synchronize

    $inheritanceFlags = [System.Security.AccessControl.InheritanceFlags]::ContainerInherit `
                      -bor [System.Security.AccessControl.InheritanceFlags]::ObjectInherit

    $propagationFlags = [System.Security.AccessControl.PropagationFlags]::None
    $accessType       = [System.Security.AccessControl.AccessControlType]::Allow

    $acl = Get-Acl -LiteralPath $Path

    # Check if an equivalent allow rule already exists (avoid duplicates)
    $alreadyPresent = $false
    foreach ($ace in $acl.Access) {
        if ($ace.IdentityReference -eq $Identity -and
            $ace.AccessControlType -eq $accessType -and
            ($ace.FileSystemRights -band $rights) -eq $rights -and
            $ace.InheritanceFlags -eq $inheritanceFlags -and
            $ace.PropagationFlags -eq $propagationFlags) {

            $alreadyPresent = $true
            break
        }
    }

    if (-not $alreadyPresent) {
        $rule = New-Object System.Security.AccessControl.FileSystemAccessRule(
            $Identity,
            $rights,
            $inheritanceFlags,
            $propagationFlags,
            $accessType
        )

        $acl.AddAccessRule($rule) | Out-Null
        Set-Acl -LiteralPath $Path -AclObject $acl

        Write-Host "ACL added (ReadOnly): $Identity -> $Path" -ForegroundColor Green
    }
    else {
        Write-Host "ACL already present:     $Identity -> $Path" -ForegroundColor DarkGray
    }
}

# Ensure root exists
New-Item -Path $Root -ItemType Directory -Force | Out-Null

foreach ($item in $FolderInfo) {
    $fullPath = Join-Path $Root $item.Path

    # Create folder (and parents)
    if (-not (Test-Path -LiteralPath $fullPath)) {
        New-Item -Path $fullPath -ItemType Directory -Force | Out-Null
        Write-Host "Created: $fullPath" -ForegroundColor Cyan
    }
    else {
        Write-Host "Exists:  $fullPath" -ForegroundColor DarkGray
    }

    # Apply RO permission to the specified AD group
    if ([string]::IsNullOrWhiteSpace($item.Group)) {
        Write-Host "No group specified; skipping ACL for: $fullPath" -ForegroundColor Yellow
        continue
    }

    try {
        Add-ReadOnlyAcl -Path $fullPath -Identity $item.Group
    }
    catch {
        Write-Host "FAILED to set ACL for '$($item.Group)' on '$fullPath': $($_.Exception.Message)" -ForegroundColor Red
    }
}

Write-Host "Done." -ForegroundColor Magenta
