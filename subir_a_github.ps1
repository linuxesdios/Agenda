# Sube el proyecto a https://github.com/linuxesdios/agenda
# Requiere que el repo ya exista (vacio) en GitHub - ver instrucciones en el chat.
# Uso: desde D:\agenda, ejecutar:  .\subir_a_github.ps1

$ErrorActionPreference = "Stop"
$usuario = "linuxesdios"
$repo    = "agenda"
$url     = "https://github.com/$usuario/$repo.git"

Write-Host ""
Write-Host "=== Subiendo Agenda a $url ===" -ForegroundColor Cyan
Write-Host ""

# 1. Reemplazar el placeholder <OWNER> en el README por el usuario real
if (Test-Path "README.md") {
    Write-Host "[1/6] Ajustando README.md..." -ForegroundColor Yellow
    (Get-Content "README.md") -replace '<OWNER>', $usuario | Set-Content "README.md"
}

# 2. Inicializar git si hace falta
if (-not (Test-Path ".git")) {
    Write-Host "[2/6] Inicializando repositorio git..." -ForegroundColor Yellow
    git init
} else {
    Write-Host "[2/6] Ya existe un repositorio git, salteo git init." -ForegroundColor Yellow
}

# 3. Configurar la rama principal como 'main'
git branch -M main

# 4. Agregar archivos y mostrar qué se va a comitear (para revisar antes de confirmar)
Write-Host "[3/6] Agregando archivos (respetando .gitignore)..." -ForegroundColor Yellow
git add -A
Write-Host ""
Write-Host "--- Archivos que se van a comitear: ---" -ForegroundColor Cyan
git status --short
Write-Host ""

$confirmar = Read-Host "¿Seguimos con el commit? (s/n)"
if ($confirmar -ne "s") {
    Write-Host "Cancelado. No se hizo commit ni push." -ForegroundColor Red
    exit 0
}

# 5. Commit (solo si hay algo para comitear)
Write-Host "[4/6] Creando commit..." -ForegroundColor Yellow
git diff --cached --quiet
if ($LASTEXITCODE -eq 0) {
    Write-Host "No hay cambios nuevos para comitear, sigo con el push por si falta." -ForegroundColor Yellow
} else {
    git commit -m "Initial commit: agenda Flutter app con soporte multi-idioma"
}

# 6. Conectar el remoto (si no existe ya) y pushear
Write-Host "[5/6] Configurando remoto 'origin'..." -ForegroundColor Yellow
$remotoActual = git remote get-url origin 2>$null
if (-not $remotoActual) {
    git remote add origin $url
} elseif ($remotoActual -ne $url) {
    Write-Host "El remoto 'origin' ya apunta a $remotoActual, lo actualizo." -ForegroundColor Yellow
    git remote set-url origin $url
}

Write-Host "[6/6] Pusheando a GitHub..." -ForegroundColor Yellow
git push -u origin main

Write-Host ""
Write-Host "=== Listo! Repo disponible en: https://github.com/$usuario/$repo ===" -ForegroundColor Green
