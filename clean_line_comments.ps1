Write-Host "Eliminando comentarios // y /// de archivos Dart..." -ForegroundColor Green

function Remove-LineCommentsFromFile {
    param([string]$FilePath)
    
    Write-Host "Procesando: $FilePath" -ForegroundColor Yellow
    
    try {
        $content = Get-Content -Path $FilePath -Raw -Encoding UTF8
        
        if (-not $content) {
            Write-Host "  Archivo vacio, saltando..." -ForegroundColor Gray
            return
        }
        
        $lines = $content -split "`r?`n"
        $processedLines = @()
        
        foreach ($line in $lines) {
            $processedLine = $line
            
            # Eliminar líneas que solo tienen comentarios ///
            if ($line.Trim() -match '^///.*$') {
                continue
            }
            
            # Eliminar líneas que solo tienen comentarios //
            if ($line.Trim() -match '^//.*$') {
                continue
            }
            
            # Para comentarios al final de línea, necesitamos ser más cuidadosos
            # No tocar líneas que contengan URLs (http://, https://, ftp://)
            if ($line -notmatch '(https?://|ftp://|file://)') {
                # Eliminar comentarios // al final de la línea (solo si no es parte de una URL)
                if ($line -match '^(.*?)\s+//(?!\s*/).*$') {
                    $beforeComment = $matches[1].TrimEnd()
                    if ($beforeComment.Trim() -ne '') {
                        $processedLine = $beforeComment
                    } else {
                        continue
                    }
                }
                
                # Eliminar comentarios /// al final de la línea
                if ($line -match '^(.*?)\s+///.*$') {
                    $beforeComment = $matches[1].TrimEnd()
                    if ($beforeComment.Trim() -ne '') {
                        $processedLine = $beforeComment
                    } else {
                        continue
                    }
                }
            }
            
            $processedLines += $processedLine
        }
        
        $newContent = $processedLines -join "`r`n"
        
        # Limpiar líneas vacías múltiples
        $newContent = $newContent -replace '(\r?\n){3,}', "`r`n`r`n"
        
        Set-Content -Path $FilePath -Value $newContent -Encoding UTF8 -NoNewline
        
        Write-Host "  Comentarios eliminados" -ForegroundColor Green
        
    } catch {
        Write-Host "  Error: $_" -ForegroundColor Red
    }
}

$dartFiles = Get-ChildItem -Path "." -Recurse -Filter "*.dart" | Where-Object { 
    $_.Name -notmatch "(\.g\.dart|\.freezed\.dart|\.mocks\.dart)$" -and
    $_.FullName -notmatch "(\\build\\|\\\.dart_tool\\)"
}

Write-Host "Encontrados $($dartFiles.Count) archivos Dart" -ForegroundColor Cyan

$backupFolder = "backup_line_only_$(Get-Date -Format 'yyyyMMdd_HHmmss')"
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

Write-Host "Backup creado en: $backupFolder" -ForegroundColor Green

$processedCount = 0
foreach ($file in $dartFiles) {
    Remove-LineCommentsFromFile -FilePath $file.FullName
    $processedCount++
    
    if ($processedCount % 20 -eq 0) {
        Write-Host "Progreso: $processedCount/$($dartFiles.Count)" -ForegroundColor Cyan
    }
}

Write-Host "Completado! Procesados $processedCount archivos" -ForegroundColor Green
