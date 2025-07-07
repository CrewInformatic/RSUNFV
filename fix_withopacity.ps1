# Script para corregir TODOS los problemas de withOpacity
$files = Get-ChildItem -Path "lib" -Recurse -Filter "*.dart" | Select-Object -ExpandProperty FullName

foreach ($file in $files) {
    $content = Get-Content $file -Raw
    if ($content -match "\.withOpacity\(") {
        Write-Host "Corrigiendo withOpacity en: $($file.Replace((Get-Location).Path + '\', ''))"
        
        # Reemplazar .withOpacity(valor) con .withValues(alpha: valor)
        $content = $content -replace '\.withOpacity\(([^)]+)\)', '.withValues(alpha: $1)'
        
        Set-Content $file -Value $content -NoNewline
    }
}

Write-Host "Corrección de withOpacity completada"
