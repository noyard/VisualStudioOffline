param(
    [ValidateSet("InitialLock", "Lock", "Unlock")]
    [string]$Mode = "Lock",

    [string]$LayoutPath = "C:\VSLayout"
)

if (-not (Test-Path -LiteralPath $LayoutPath)) {
    if ($Mode -eq "InitialLock") {
        New-Item -Path $LayoutPath -ItemType Directory -Force | Out-Null
    }
    else {
        Write-Error "Layout path '$LayoutPath' does not exist. Use -Mode InitialLock to create it first."
        exit 1
    }
}

switch ($Mode) {
    "InitialLock" {
        icacls $LayoutPath /inheritance:r | Out-Null
        icacls $LayoutPath `
            /grant 'SYSTEM:(OI)(CI)RX' `
            /grant 'BUILTIN\Administrators:(OI)(CI)F' `
            /grant 'Authenticated Users:(OI)(CI)RX' | Out-Null
        icacls $LayoutPath /remove 'Users' | Out-Null
        icacls $LayoutPath /remove 'Everyone' | Out-Null
    }
    "Lock" {
        icacls $LayoutPath `
            /grant 'SYSTEM:(OI)(CI)RX' `
            /grant 'BUILTIN\Administrators:(OI)(CI)RX' `
            /grant 'Authenticated Users:(OI)(CI)RX' | Out-Null
    }
    "Unlock" {
        icacls $LayoutPath /grant 'BUILTIN\Administrators:(OI)(CI)F' | Out-Null
    }
}

icacls $LayoutPath
