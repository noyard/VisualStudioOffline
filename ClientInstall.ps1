## Install required certificates (critical for offline installs)
$certPath = Join-Path $layoutRoot 'Certificates'
if (Test-Path $certPath) {
    Get-ChildItem $certPath -Filter *.crt | ForEach-Object {
        Execute-Process -Path 'certutil.exe' `
            -Parameters "-addstore Root `"$($_.FullName)`"" `
            -WindowStyle Hidden `
            -IgnoreExitCodes '0'
    }
}

##install
"C:\VSLayout\vs_setup.exe" --noWeb --wait --norestart--passive
