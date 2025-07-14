# 📐 ESPECIFICACIONES DE IMÁGENES PARA EL CAROUSEL

## 🎯 Dimensiones Requeridas para el Carousel

### 📱 Dimensiones del Contenedor del Carousel
- **Móvil**: 300px de alto (ancho completo de pantalla - márgenes)
- **Tablet**: 400px de alto (ancho completo de pantalla - márgenes)
- **Márgenes**: 16px móvil, 24px tablet
- **Border radius**: 20px

### 🖼️ Dimensiones Recomendadas para las Imágenes

#### 🎖️ **CONFIGURACIÓN ACTUAL (Cloudinary)**
```
Transformación: w_1200,h_800,c_fit,q_auto,f_auto
- Ancho: 1200px
- Alto: 800px
- Ratio: 3:2 (1.5:1)
- Crop: fit (preserva proporción)
- Calidad: automática
- Formato: automático
```

#### 📏 **Especificaciones Detalladas**

**Para imágenes NUEVAS que quieras subir:**

1. **Resolución mínima recomendada**: 
   - `1920x1080px` (Full HD)
   - `2400x1600px` (para mejor calidad)

2. **Ratio de aspecto**: 
   - **Óptimo**: `3:2` (1.5:1) - como 1200x800
   - **Alternativo**: `16:9` (1.78:1) - como 1920x1080
   - **Funciona**: `4:3` (1.33:1) - como 1600x1200

3. **Formato**: 
   - PNG (con transparencia si necesario)
   - JPEG (para fotos)
   - WebP (mejor compresión)

4. **Tamaño de archivo**: 
   - Máximo recomendado: 5MB por imagen
   - Óptimo: 1-3MB por imagen

### 🎨 Cómo se Procesan las Imágenes

#### Transformación de Cloudinary:
```
w_1200,h_800,c_fit,q_auto,f_auto
```

**Explicación:**
- `w_1200`: Ancho máximo 1200px
- `h_800`: Alto máximo 800px  
- `c_fit`: Escala para que quepa sin recortar
- `q_auto`: Calidad automática optimizada
- `f_auto`: Formato automático (WebP cuando sea compatible)

#### Comportamiento en la App:
- **BoxFit.cover**: La imagen llena el contenedor
- **Positioned.fill**: Ocupa todo el espacio disponible
- **ClipRRect**: Esquinas redondeadas (20px)

### 📱 Resoluciones por Dispositivo

| Dispositivo | Ancho Aprox | Alto Carousel | Imagen Final |
|-------------|-------------|---------------|--------------|
| iPhone SE   | 375px       | 300px         | 355x300px    |
| iPhone 12   | 390px       | 300px         | 370x300px    |
| iPhone Plus | 414px       | 300px         | 394x300px    |
| iPad        | 768px       | 400px         | 720x400px    |
| Desktop     | 1200px+     | 400px         | 1152x400px   |

### 🎯 **URLS ACTUALES DEL CAROUSEL**

```javascript
// Imagen 1: Voluntarios
https://res.cloudinary.com/dupkeaqnz/image/upload/w_1200,h_800,c_fit,q_auto,f_auto/v1752457968/unfv_2_f7aqs7.jpg

// Imagen 2: Donaciones  
https://res.cloudinary.com/dupkeaqnz/image/upload/w_1200,h_800,c_fit,q_auto,f_auto/v1752457968/unfv_4_wfmsoj.jpg

// Imagen 3: Eventos
https://res.cloudinary.com/dupkeaqnz/image/upload/w_1200,h_800,c_fit,q_auto,f_auto/v1752457968/unfv_1_gx0oa2.jpg
```

### 🔧 **Para Subir Nuevas Imágenes a Cloudinary:**

1. **Tamaño óptimo**: `2400x1600px` (ratio 3:2)
2. **Formato**: JPEG o PNG
3. **Calidad**: 85-95%
4. **Contenido**: 
   - Enfoque principal en el centro
   - Evita texto importante en los bordes
   - Contraste alto para legibilidad del texto overlay

### ⚡ **Optimizaciones Aplicadas**

- ✅ **Transformación c_fit**: No recorta, preserva toda la imagen
- ✅ **Calidad automática**: Cloudinary optimiza según dispositivo
- ✅ **Formato automático**: WebP en navegadores compatibles
- ✅ **Lazy loading**: Carga cuando es necesario
- ✅ **Fallback system**: Unsplash como respaldo

### 🎨 **Tips para Mejores Resultados**

1. **Composición**: Deja espacio en la parte inferior para el texto
2. **Contraste**: Usa imágenes con áreas oscuras para el overlay de texto
3. **Enfoque**: El elemento principal debe estar centrado
4. **Colores**: Considera los gradients del overlay (negro semi-transparente)

---

**💡 Recomendación**: Para mejores resultados, usa imágenes de `2400x1600px` en formato JPEG con 90% de calidad.
