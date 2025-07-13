# Script para eliminar comentarios de archivos Dart
# Elimina comentarios de línea (//) y comentarios de bloque (/* */)

Write-Host "Iniciando eliminación de comentarios de archivos Dart..." -ForegroundColor Green

# Función para eliminar comentarios de un archivo
function Remove-CommentsFromFile {
    param(
        [string]$FilePath
    )
    
    Write-Host "Procesando: $FilePath" -ForegroundColor Yellow
    
    try {
        # Leer el contenido del archivo
        $content = Get-Content -Path $FilePath -Raw -Encoding UTF8
        
        if (-not $content) {
            Write-Host "  Archivo vacío, saltando..." -ForegroundColor Gray
            return
        }
        
        # Eliminar comentarios de línea simple (//) pero preservar URLs y strings
        # Esta expresión regular es más cuidadosa para no afectar strings
        $content = $content -replace '(?<!["''].*?)//(?!.*["'']).*?(?=\r?\n|$)', ''
        
        # Eliminar comentarios de bloque (/* ... */) incluyendo multilínea
        # Cuidado con los strings que contengan /* */
        $content = $content -replace '/\*[\s\S]*?\*/', ''
        
        # Eliminar comentarios de documentación (/// ...)
        $content = $content -replace '(?<!["''].*?)///(?!.*["'']).*?(?=\r?\n|$)', ''
        
        # Limpiar líneas vacías múltiples (más de 2 líneas consecutivas)
        $content = $content -replace '(\r?\n){3,}', "`r`n`r`n"
        
        # Limpiar espacios en blanco al final de las líneas
        $content = $content -replace '[ \t]+(?=\r?\n)', ''
        
        # Guardar el archivo modificado
        Set-Content -Path $FilePath -Value $content -Encoding UTF8 -NoNewline
        
        Write-Host "  ✓ Comentarios eliminados" -ForegroundColor Green
        
    } catch {
        Write-Host "  ✗ Error procesando archivo: $_" -ForegroundColor Red
    }
}
}

# Obtener todos los archivos .dart del proyecto
$dartFiles = Get-ChildItem -Path "." -Recurse -Filter "*.dart" | Where-Object { 
    # Excluir archivos generados automáticamente
    $_.Name -notmatch "(\.g\.dart|\.freezed\.dart|\.mocks\.dart)$" -and
    # Excluir carpetas build y cache
    $_.FullName -notmatch "(\\build\\|\\\.dart_tool\\)"
}

Write-Host "Encontrados $($dartFiles.Count) archivos Dart para procesar" -ForegroundColor Cyan

# Crear backup antes de procesar
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
    
    Write-Host "✓ Backup creado exitosamente" -ForegroundColor Green
    
} catch {
    Write-Host "✗ Error creando backup: $_" -ForegroundColor Red
    Write-Host "Abortando operación por seguridad..." -ForegroundColor Red
    exit 1
}

# Procesar cada archivo
$processedCount = 0
foreach ($file in $dartFiles) {
    Remove-CommentsFromFile -FilePath $file.FullName
    $processedCount++
    
    # Mostrar progreso cada 10 archivos
    if ($processedCount % 10 -eq 0) {
        Write-Host "Progreso: $processedCount/$($dartFiles.Count) archivos procesados" -ForegroundColor Cyan
    }
}

Write-Host "`nProceso completado!" -ForegroundColor Green
Write-Host "Archivos procesados: $processedCount" -ForegroundColor Green
Write-Host "Backup guardado en: $backupFolder" -ForegroundColor Yellow
Write-Host "`nRecomendación: Revisar los archivos y ejecutar 'flutter analyze' para verificar que no hay errores de sintaxis." -ForegroundColor Yellow
