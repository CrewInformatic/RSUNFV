# 🎨 SISTEMA DE ICONOS RSUNFV

## ✅ Configuración Implementada

Se ha configurado exitosamente el sistema de iconos personalizados para la aplicación RSUNFV utilizando el logo oficial de RSU.

### 📋 Características

- **Icono base**: `assets/logo_rsu.png`
- **Plataformas soportadas**: Android, iOS, Web, Windows, macOS
- **Icono adaptativo**: Configurado para Android con fondo blanco
- **Optimización iOS**: Configurado para App Store (sin canal alpha)

### 🔧 Configuración en pubspec.yaml

```yaml
flutter_launcher_icons:
  android: true
  ios: true
  image_path: "assets/logo_rsu.png"
  remove_alpha_ios: true
  adaptive_icon_background: "#FFFFFF"
  adaptive_icon_foreground: "assets/logo_rsu.png"
  web:
    generate: true
    image_path: "assets/logo_rsu.png"
  windows:
    generate: true
    image_path: "assets/logo_rsu.png"
  macos:
    generate: true
    image_path: "assets/logo_rsu.png"
```

### 📁 Archivos Generados

#### Android
- `android/app/src/main/res/mipmap-*/ic_launcher.png` (múltiples resoluciones)
- `android/app/src/main/res/mipmap-anydpi-v26/ic_launcher.xml` (icono adaptativo)
- `android/app/src/main/res/values/colors.xml` (color de fondo)

#### iOS
- `ios/Runner/Assets.xcassets/AppIcon.appiconset/` (múltiples tamaños)

#### Web
- `web/icons/Icon-*.png` (múltiples tamaños)

#### Windows
- `windows/runner/resources/app_icon.ico`

#### macOS
- `macos/Runner/Assets.xcassets/AppIcon.appiconset/`

### 🚀 Comandos de Regeneración

Para regenerar los iconos después de cambiar la imagen:

```bash
# Instalar dependencias
flutter pub get

# Generar iconos
dart run flutter_launcher_icons

# Limpiar y rebuild
flutter clean
flutter pub get
```

### 📱 Pruebas

Para probar el icono en dispositivo:

```bash
# Build y install en dispositivo conectado
flutter build apk --debug
flutter install

# O usar el script automatizado
.\build_and_test.ps1
```

### 🎯 Recomendaciones

1. **Tamaño de imagen**: Use imágenes de al menos 1024x1024 px para mejor calidad
2. **Formato**: PNG con transparencia
3. **Diseño**: El logo debe verse bien en tamaños pequeños (48x48 px)
4. **Testing**: Pruebe en diferentes dispositivos y temas (claro/oscuro)

### 🔄 Actualizaciones Futuras

Para cambiar el icono:
1. Reemplace `assets/logo_rsu.png` con la nueva imagen
2. Ejecute `dart run flutter_launcher_icons`
3. Haga rebuild de la aplicación

---

**✅ Estado**: Implementado y funcional
**📅 Fecha**: $(Get-Date -Format "dd/MM/yyyy")
**🔧 Herramienta**: flutter_launcher_icons v0.14.1
