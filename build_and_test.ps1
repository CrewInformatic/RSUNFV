# Script para construir y probar la aplicación con el nuevo icono
Write-Host "🚀 Construyendo la aplicación RSUNFV con el nuevo icono UNFV..." -ForegroundColor Green

# Verificar que existe el archivo del icono
if (-not (Test-Path "assets/app_icon.png")) {
    Write-Host "⚠️  ATENCIÓN: No se encontró assets/app_icon.png" -ForegroundColor Yellow
    Write-Host "📁 Por favor, guarda la nueva imagen como 'assets/app_icon.png'" -ForegroundColor Yellow
    Write-Host "🎨 El archivo debe ser PNG, 1024x1024 px mínimo" -ForegroundColor Cyan
    Read-Host "Presiona Enter cuando hayas guardado la imagen..."
}

# Regenerar iconos
Write-Host "🎨 Regenerando iconos de la aplicación..." -ForegroundColor Cyan
dart run flutter_launcher_icons

# Limpiar el build anterior
Write-Host "🧹 Limpiando builds anteriores..." -ForegroundColor Yellow
flutter clean

# Obtener las dependencias
Write-Host "📦 Obteniendo dependencias..." -ForegroundColor Yellow
flutter pub get

# Construir para Android (debug)
Write-Host "🤖 Construyendo para Android..." -ForegroundColor Cyan
flutter build apk --debug

Write-Host "✅ Build completado! El nuevo icono UNFV debería estar aplicado." -ForegroundColor Green
Write-Host "📱 Para instalar en dispositivo conectado, ejecuta: flutter install" -ForegroundColor Blue
Write-Host "🎯 El icono muestra: mano + planta + UNFV = RSU perfecta!" -ForegroundColor Magenta
