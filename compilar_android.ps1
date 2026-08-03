Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Compilando Agenda Flutter (Android)" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

$env:JAVA_HOME = "C:\Program Files\Android\Android Studio\jbr"

Write-Host "Compilando APK..." -ForegroundColor Yellow
& C:\flutter\bin\flutter.bat build apk --release
if ($LASTEXITCODE -ne 0) {
    Write-Host "ERROR: La compilacion fallo." -ForegroundColor Red
    Read-Host "Pulsa Enter para salir"
    exit 1
}

$destino = "compilado"
if (-not (Test-Path $destino)) { New-Item -ItemType Directory -Path $destino -Force | Out-Null }
Copy-Item "build\app\outputs\flutter-apk\app-release.apk" "$destino\agenda.apk" -Force

$apk = Get-Item "$destino\agenda.apk"
Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host "  APK listo: compilado\agenda.apk" -ForegroundColor Green
Write-Host "  Tamano: $([math]::Round($apk.Length / 1MB, 1)) MB" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""
Write-Host "Pasa agenda.apk al movil e instalalo." -ForegroundColor Cyan
