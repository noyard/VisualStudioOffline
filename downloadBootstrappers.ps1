
$destination = "."
if (!(Test-Path $destination)) {
    New-Item -ItemType Directory -Path $destination | Out-Null
}
Invoke-WebRequest -Uri "https://aka.ms/vs/17/release/vs_community.exe" -OutFile "$destination\VS2022Com.exe"
Invoke-WebRequest -Uri "https://aka.ms/vs/17/release/vs_professional.exe" -OutFile "$destination\VS2022Pro.exe"
Invoke-WebRequest -Uri "https://aka.ms/vs/17/release/vs_enterprise.exe" -OutFile "$destination\VS2022Ent.exe"
Invoke-WebRequest -Uri "https://aka.ms/vs/16/release/vs_community.exe" -OutFile "$destination\VS2019Com.exe"
Invoke-WebRequest -Uri "https://aka.ms/vs/16/release/vs_professional.exe" -OutFile "$destination\VS2019Pro.exe"
Invoke-WebRequest -Uri "https://aka.ms/vs/16/release/vs_enterprise.exe" -OutFile "$destination\VS2019Ent.exe"
Invoke-WebRequest -Uri "https://aka.ms/vs/15/release/vs_community.exe" -OutFile "$destination\VS2017Com.exe"
Invoke-WebRequest -Uri "https://aka.ms/vs/15/release/vs_professional.exe" -OutFile "$destination\VS2017Pro.exe"
Invoke-WebRequest -Uri "https://aka.ms/vs/15/release/vs_enterprise.exe" -OutFile "$destination\VS2017Ent.exe"
Write-Output "All bootstrappers downloaded to $destination"
