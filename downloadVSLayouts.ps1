$Language = "en-US"
$destination = ".\VSLayout"
if (!(Test-Path $destination)) {
    New-Item -ItemType Directory -Path $destination | Out-Null
}

$bootstrappers = Get-Content -Path ".\vslayouts.json" | ConvertFrom-Json

foreach ($bootstrapper in $bootstrappers) {
    if (-not $bootstrapper.Enabled) {
        continue
    }
    $bootstrapperFolder = Join-Path $destination $bootstrapper.Folder
    $bootstrapperFolder = [System.IO.Path]::GetFullPath("$bootstrapperFolder")
    $drive = ([System.IO.Path]::GetPathRoot($bootstrapperFolder)).TrimEnd('\', ':')
    $requiredSpace = 100GB
    
    #check to see if the drive has enough free space for the layout
    $freeSpace = (Get-PSDrive -Name $drive).Free
    if ($freeSpace -lt $requiredSpace) {
        Write-Error "Not enough free space on drive $drive for $($bootstrapper.Folder). Required: $($requiredSpace) bytes, Available: $freeSpace bytes."
        continue
    }

    #if length of $bootstrapperFolder > 79 characters, skip it because the layout installer will fail with a long path error
    if ($bootstrapperFolder.Length -gt 79) {
        Write-Output "Bootstrapper folder path '$bootstrapperFolder' is too long. Layout installer may fail with a long path error. Switching to '$drive' location."
        $bootstrapperFolder = "$($drive):\VSLayout\$($bootstrapper.Folder)"
        $bootstrapperFolder = [System.IO.Path]::GetFullPath("$bootstrapperFolder")
    }

    if (!(Test-Path $bootstrapperFolder)) {
        New-Item -ItemType Directory -Path $bootstrapperFolder | Out-Null
    }
    Invoke-WebRequest -Uri $bootstrapper.URI -OutFile (Join-Path $bootstrapperFolder "vs_setup.exe")

    # Build the layout command
    $command = ". $(Join-Path $bootstrapperFolder "vs_setup.exe") --layout `"$bootstrapperFolder`" --lang $Language --all --includeRecommended --includeOptional --wait"
    Write-Output "Executing: $command"
    Invoke-Expression $command

    # Copy the default install files to the bootstrapper folder
    Copy-Item -Path .\Default\* -Destination $bootstrapperFolder -Recurse -Force
    
    Write-Output "$bootstrapper downloaded all workloads to $bootstrapperFolder"
}

Write-Output "All bootstrappers downloaded to $destination"


