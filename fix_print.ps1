# Script para corregir TODOS los problemas de print
$files = Get-ChildItem -Path "lib" -Recurse -Filter "*.dart" | Select-Object -ExpandProperty FullName

foreach ($file in $files) {
    $content = Get-Content $file -Raw
    if ($content -match "\bprint\s*\(") {
        Write-Host "Corrigiendo print en: $($file.Replace((Get-Location).Path + '\', ''))"
        
        # Reemplazar print( con debugPrint(
        $content = $content -replace '\bprint\s*\(', 'debugPrint('
        
        Set-Content $file -Value $content -NoNewline
    }
}

Write-Host "Corrección de print completada"
