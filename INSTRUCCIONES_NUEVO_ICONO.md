# 🎨 INSTRUCCIONES PARA ACTUALIZAR EL ICONO DE LA APP

## 📋 Pasos para cambiar al nuevo icono

### 1. 💾 Guardar la nueva imagen
- Guarda la imagen del icono (la mano con la planta y "UNFV") como: `app_icon.png`
- Ubicación: `assets/app_icon.png`
- **Recomendaciones**:
  - Tamaño mínimo: 1024x1024 píxeles
  - Formato: PNG con transparencia
  - Calidad alta para todos los tamaños

### 2. 🔄 Regenerar los iconos
Ejecuta estos comandos en la terminal:

```bash
# Instalar dependencias (si es necesario)
flutter pub get

# Generar todos los iconos de la app
dart run flutter_launcher_icons

# Limpiar y reconstruir
flutter clean
flutter pub get
```

### 3. 🚀 Probar la aplicación
```bash
# Construir para Android
flutter build apk --debug

# Instalar en dispositivo conectado
flutter install
```

## 🎯 Configuración Actual

El nuevo icono está configurado con:
- **Imagen principal**: `assets/app_icon.png`
- **Fondo adaptativo**: Color turquesa `#4ECDC4` (matching del icono)
- **Plataformas**: Android, iOS, Web, Windows, macOS
- **Optimización iOS**: Sin canal alpha para App Store

## 📱 Características del Nuevo Icono

✅ **Diseño profesional** con simbolismo de RSU
✅ **Colores vibrantes** (verde, turquesa, azul)
✅ **Identidad clara** con texto "UNFV"
✅ **Simbolismo perfecto** (mano + planta = cuidado ambiental)

## 🔧 Script Automático

También puedes usar el script automático:
```bash
.\build_and_test.ps1
```

---

⚠️ **IMPORTANTE**: 
1. Asegúrate de guardar la imagen como `assets/app_icon.png`
2. La imagen debe ser cuadrada (1:1 ratio)
3. Resolución mínima 1024x1024 px para mejor calidad

Una vez que hayas guardado la imagen, ejecuta:
`dart run flutter_launcher_icons`
