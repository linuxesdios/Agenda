Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Compilando Agenda (Windows + Android)" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

Get-Process -Name "agenda" -ErrorAction SilentlyContinue | Stop-Process -Force 2>$null
Start-Sleep 1

Write-Host "[1/5] Limpiando..." -ForegroundColor Yellow
& C:\flutter\bin\flutter.bat clean 2>$null
& C:\flutter\bin\flutter.bat pub get 2>$null

Write-Host "[2/5] Compilando Windows..." -ForegroundColor Yellow
& C:\flutter\bin\flutter.bat build windows --release
if ($LASTEXITCODE -ne 0) {
    Write-Host "ERROR: Fallo Windows." -ForegroundColor Red
    return
}

Write-Host "[3/5] Compilando Android..." -ForegroundColor Yellow
$env:JAVA_HOME = "C:\Program Files\Android\Android Studio\jbr"
& C:\flutter\bin\flutter.bat build apk --release
if ($LASTEXITCODE -ne 0) {
    Write-Host "ERROR: Fallo Android." -ForegroundColor Red
    return
}

Write-Host "[4/5] Copiando a compilado..." -ForegroundColor Yellow
if (Test-Path "compilado") { Remove-Item "compilado" -Recurse -Force }
New-Item -ItemType Directory -Path "compilado" -Force | Out-Null
Copy-Item "build\windows\x64\runner\Release\*" "compilado\" -Recurse -Force
Copy-Item "build\app\outputs\flutter-apk\app-release.apk" "compilado\agenda.apk" -Force

Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host "  LISTO!" -ForegroundColor Green
Write-Host "  Windows: compilado\agenda.exe" -ForegroundColor Green
Write-Host "  Android: compilado\agenda.apk" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green

Write-Host "[5/5] Abriendo app..." -ForegroundColor Yellow
Start-Process "compilado\agenda.exe" -WorkingDirectory "compilado"
