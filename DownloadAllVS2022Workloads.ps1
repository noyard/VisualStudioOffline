
param (
    [string]$bootstrapper = "VS2022Ent.exe",

    [string]$DestinationPath = "VS2022Enterprise",

    [string]$Language = "en-US"
)

# Check if bootstrapper exists in current directory
if (!(Test-Path "./$bootstrapper")) {
    Write-Error "Bootstrapper '$bootstrapper' not found in current directory. Please download it from https://visualstudio.microsoft.com/downloads/."
    exit 1
}

# Create destination folder if needed
if (!(Test-Path ./$DestinationPath)) {
    New-Item -ItemType Directory -Path ./$DestinationPath | Out-Null
}

# Build the layout command
$command = "./$bootstrapper --layout `"$DestinationPath`" --lang $Language --all --includeRecommended --includeOptional"
Write-Output "Executing: $command"
Invoke-Expression $command

Write-Output "$bootstrapper downloaded all workloads to $DestinationPath"
