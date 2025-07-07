# Script para eliminar comentarios de modelos
$files = @(
    "lib\models\medalla.dart",
    "lib\models\usuario.dart",
    "lib\models\evento.dart"
)

foreach($file in $files) {
    if(Test-Path $file) {
        Write-Host "Limpiando comentarios de $file"
        $content = Get-Content $file -Raw
        $content = $content -replace '(?m)^\s*//.*\r?\n', ''
        $content = $content -replace '\s*//[^''"\r\n]*(?=[\r\n])', ''
        $content = $content -replace '(?m)^\s*\r?\n\s*\r?\n', "`r`n"
        Set-Content $file -Value $content -NoNewline
    }
}

# También limpiar algunos servicios y funciones
$serviceFiles = @(
    "lib\functions\funciones_eventos.dart",
    "lib\functions\pedir_eventos.dart", 
    "lib\services\firebase_auth_services.dart"
)

foreach($file in $serviceFiles) {
    if(Test-Path $file) {
        Write-Host "Limpiando comentarios de $file"
        $content = Get-Content $file -Raw
        $content = $content -replace '(?m)^\s*//.*\r?\n', ''
        $content = $content -replace '\s*//[^''"\r\n]*(?=[\r\n])', ''
        $content = $content -replace '(?m)^\s*\r?\n\s*\r?\n', "`r`n"
        Set-Content $file -Value $content -NoNewline
    }
}

Write-Host "Limpieza de archivos adicionales completada"
