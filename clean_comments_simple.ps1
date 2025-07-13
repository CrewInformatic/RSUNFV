Write-Host "Iniciando eliminacion de comentarios de archivos Dart..." -ForegroundColor Green

function Remove-CommentsFromFile {
    param([string]$FilePath)
    
    Write-Host "Procesando: $FilePath" -ForegroundColor Yellow
    
    try {
        $content = Get-Content -Path $FilePath -Raw -Encoding UTF8
        
        if (-not $content) {
            Write-Host "  Archivo vacio, saltando..." -ForegroundColor Gray
            return
        }
        
        $content = $content -replace '//.*?(?=\r?\n|$)', ''
        $content = $content -replace '/\*[\s\S]*?\*/', ''
        $content = $content -replace '///.*?(?=\r?\n|$)', ''
        $content = $content -replace '(\r?\n){3,}', "`r`n`r`n"
        $content = $content -replace '[ \t]+(?=\r?\n)', ''
        
        Set-Content -Path $FilePath -Value $content -Encoding UTF8 -NoNewline
        
        Write-Host "  Comentarios eliminados" -ForegroundColor Green
        
    } catch {
        Write-Host "  Error procesando archivo: $_" -ForegroundColor Red
    }
}

$dartFiles = Get-ChildItem -Path "." -Recurse -Filter "*.dart" | Where-Object { 
    $_.Name -notmatch "(\.g\.dart|\.freezed\.dart|\.mocks\.dart)$" -and
    $_.FullName -notmatch "(\\build\\|\\\.dart_tool\\)"
}

Write-Host "Encontrados $($dartFiles.Count) archivos Dart para procesar" -ForegroundColor Cyan

$backupFolder = "backup_$(Get-Date -Format 'yyyyMMdd_HHmmss')"
Write-Host "Creando backup en carpeta: $backupFolder" -ForegroundColor Cyan

try {
    New-Item -ItemType Directory -Path $backupFolder -Force | Out-Null
    
    foreach ($file in $dartFiles) {
        $relativePath = $file.FullName.Substring((Get-Location).Path.Length + 1)
        $backupPath = Join-Path $backupFolder $relativePath
        $backupDir = Split-Path $backupPath -Parent
        
        if (!(Test-Path $backupDir)) {
            New-Item -ItemType Directory -Path $backupDir -Force | Out-Null
        }
        
        Copy-Item -Path $file.FullName -Destination $backupPath -Force
    }
    
    Write-Host "Backup creado exitosamente" -ForegroundColor Green
    
} catch {
    Write-Host "Error creando backup: $_" -ForegroundColor Red
    Write-Host "Abortando operacion por seguridad..." -ForegroundColor Red
    exit 1
}

$processedCount = 0
foreach ($file in $dartFiles) {
    Remove-CommentsFromFile -FilePath $file.FullName
    $processedCount++
    
    if ($processedCount % 10 -eq 0) {
        Write-Host "Progreso: $processedCount/$($dartFiles.Count) archivos procesados" -ForegroundColor Cyan
    }
}

Write-Host "Proceso completado!" -ForegroundColor Green
Write-Host "Archivos procesados: $processedCount" -ForegroundColor Green
Write-Host "Backup guardado en: $backupFolder" -ForegroundColor Yellow
