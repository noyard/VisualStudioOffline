
$destination = ".\VSLayout"
if (!(Test-Path $destination)) {
    New-Item -ItemType Directory -Path $destination | Out-Null
}

$bootstrappers = Get-Content -Path ".\bootstrappers.json" | ConvertFrom-Json

foreach ($bootstrapper in $bootstrappers) {
    if (-not $bootstrapper.Enabled) {
        continue
    }
    $bootstrapperFolder = Join-Path $destination $bootstrapper.Folder
    if (!(Test-Path $bootstrapperFolder)) {
        New-Item -ItemType Directory -Path $bootstrapperFolder | Out-Null
    }
    Invoke-WebRequest -Uri $bootstrapper.URI -OutFile (Join-Path $bootstrapperFolder "vs_setup.exe")
}

Write-Output "All bootstrappers downloaded to $destination"


