Write-Host "Eliminando solo comentarios de linea (//) y documentacion (///) de archivos Dart..." -ForegroundColor Green

function Remove-LineCommentsFromFile {
    param([string]$FilePath)
    
    Write-Host "Procesando: $FilePath" -ForegroundColor Yellow
    
    try {
        $content = Get-Content -Path $FilePath -Raw -Encoding UTF8
        
        if (-not $content) {
            Write-Host "  Archivo vacio, saltando..." -ForegroundColor Gray
            return
        }
        
        # Dividir el contenido en líneas para procesamiento más preciso
        $lines = $content -split '\r?\n'
        $processedLines = @()
        
        foreach ($line in $lines) {
            # Verificar si la línea está dentro de un string o tiene contenido importante
            $processedLine = $line
            
            # Solo eliminar comentarios // si no están dentro de strings
            # Buscar // que no estén dentro de comillas simples o dobles
            if ($line -match '^([^"\']*?)//.*$' -and $line -notmatch '^[^"\']*["\'][^"\']*//.*["\']') {
                $processedLine = $matches[1].TrimEnd()
            }
            
            # Eliminar comentarios de documentación ///
            if ($line -match '^(\s*)///.*$') {
                # Si la línea solo tiene comentarios ///, saltarla
                if ($line.Trim() -match '^///.*$') {
                    continue
                }
                # Si hay código antes del ///, mantener solo el código
                $processedLine = $matches[1]
            }
            
            $processedLines += $processedLine
        }
        
        # Unir las líneas procesadas
        $newContent = $processedLines -join "`r`n"
        
        # Limpiar líneas vacías múltiples (más de 2 líneas consecutivas)
        $newContent = $newContent -replace '(\r?\n){3,}', "`r`n`r`n"
        
        # Limpiar espacios en blanco al final de las líneas
        $newContent = $newContent -replace '[ \t]+(?=\r?\n)', ''
        
        Set-Content -Path $FilePath -Value $newContent -Encoding UTF8 -NoNewline
        
        Write-Host "  Comentarios de linea eliminados" -ForegroundColor Green
        
    } catch {
        Write-Host "  Error procesando archivo: $_" -ForegroundColor Red
    }
}

$dartFiles = Get-ChildItem -Path "." -Recurse -Filter "*.dart" | Where-Object { 
    $_.Name -notmatch "(\.g\.dart|\.freezed\.dart|\.mocks\.dart)$" -and
    $_.FullName -notmatch "(\\build\\|\\\.dart_tool\\)"
}

Write-Host "Encontrados $($dartFiles.Count) archivos Dart para procesar" -ForegroundColor Cyan

$backupFolder = "backup_line_comments_$(Get-Date -Format 'yyyyMMdd_HHmmss')"
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
    Remove-LineCommentsFromFile -FilePath $file.FullName
    $processedCount++
    
    if ($processedCount % 10 -eq 0) {
        Write-Host "Progreso: $processedCount/$($dartFiles.Count) archivos procesados" -ForegroundColor Cyan
    }
}

Write-Host "Proceso completado!" -ForegroundColor Green
Write-Host "Archivos procesados: $processedCount" -ForegroundColor Green
Write-Host "Backup guardado en: $backupFolder" -ForegroundColor Yellow
Write-Host "Solo se eliminaron comentarios // y ///, se mantuvieron comentarios de bloque /* */" -ForegroundColor Cyan
