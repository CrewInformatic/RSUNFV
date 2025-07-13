# Sistema de Donaciones Completo - Responsabilidad Social UNFV

## 🎯 **Descripción General**

El sistema de donaciones ha sido completamente renovado para la aplicación de Responsabilidad Social de la UNFV, permitiendo ahora dos tipos de donaciones:

### **1. Donaciones Monetarias** 💰
- Transferencias bancarias
- Pagos con Yape y Plin  
- Pagos en efectivo
- Comprobantes digitales automáticos

### **2. Donaciones de Objetos** 📦
- Ropa y calzado
- Libros y material educativo
- Productos de higiene personal
- Alimentos no perecibles
- Juguetes y entretenimiento
- Electrodomésticos y electrónicos
- Otros artículos útiles

---

## 🚀 **Flujo de Usuario Implementado**

### **Inicio del Proceso**
```
Pantalla de Donaciones → "Nueva Donación" → Selección de Tipo
```

### **Flujo para Donaciones Monetarias**
```
1. Selección "Donación Monetaria"
2. Ingreso de monto (DonationStartScreen)
3. Selección de recolector certificado (DonacionRecolectorScreen)
4. Selección de método de pago (DonacionMetodoPagoScreen)
5. Subida de voucher (DonationVoucherScreen)
6. Confirmación final (DonacionConfirmacionScreen)
```

### **Flujo para Donaciones de Objetos**
```
1. Selección "Donación de Objetos"
2. Formulario de objetos (DonationObjectScreen)
   - Categoría de objetos
   - Descripción detallada
   - Cantidad estimada
   - Estado de conservación
   - Foto opcional
3. Selección de recolector (DonacionRecolectorScreen)
4. Coordinación de recogida
```

---

## 📱 **Pantallas Implementadas**

### **DonationTypeSelectionScreen**
- **Propósito:** Selección inicial del tipo de donación
- **Características:**
  - Diseño atractivo con gradientes
  - Información clara de cada opción
  - Lista de características de cada tipo
  - Navegación directa a flujos específicos

### **DonationObjectScreen**
- **Propósito:** Formulario para donaciones de objetos
- **Características:**
  - Grid de categorías con iconos
  - Formulario completo con validaciones
  - Contador de cantidad estimada
  - Selector de estado de conservación
  - Carga de fotos (compatible con web)
  - Campo de observaciones

### **DonationVoucherScreen (Mejorada)**
- **Propósito:** Subida de comprobantes de pago
- **Mejoras Implementadas:**
  - Compatible con Flutter Web
  - Manejo dual File/Uint8List
  - Widget UniversalImage personalizado
  - Validaciones mejoradas
  - UI más intuitiva

### **DonationStartScreen (Existente)**
- **Propósito:** Ingreso de monto para donaciones monetarias
- **Características:**
  - Botones de monto rápido
  - Validación de monto mínimo
  - Carga automática de datos del usuario

### **DonacionRecolectorScreen (Mejorada)**
- **Propósito:** Selección de recolector certificado
- **Mejoras:**
  - Badges mejorados de métodos de pago
  - Visualización de disponibilidad (Yape, Banco, Efectivo)
  - Diseño más profesional
  - Información completa del recolector

---

## 🛠 **Componentes Técnicos**

### **UniversalImage Widget**
```dart
// Widget personalizado para imágenes multiplataforma
- Soporte para File (móvil) y Uint8List (web)
- Fallback automático
- BorderRadius opcional
- Fit personalizable
```

### **CloudinaryService (Compatible)**
```dart
// Método mejorado para vouchers
uploadVoucher(Uint8List imageBytes)
- No actualiza perfil del usuario
- Específico para comprobantes
- Compatible con web y móvil
```

### **Modelo de Datos Expandido**
```dart
// Para donaciones de objetos
{
  'tipo': 'objeto',
  'categoria': string,
  'descripcion': string,
  'cantidadEstimada': int,
  'estadoObjetos': string,
  'imagenUrl': string?,
  'observaciones': string?,
  // + datos del donador y recolector
}
```

---

## 🎨 **Mejoras de UI/UX**

### **Diseño Consistente**
- Gradientes corporativos naranjas/azules
- Iconografía clara y específica
- Navegación intuitiva
- Feedback visual constante

### **Accesibilidad**
- Textos descriptivos
- Iconos complementarios
- Validaciones claras
- Mensajes de estado informativos

### **Responsividad**
- Compatible con diferentes tamaños de pantalla
- Diseño adaptativo para móvil y web
- Optimizado para touch y mouse

---

## 🔧 **Configuración y Compatibilidad**

### **Plataformas Soportadas**
- ✅ Android
- ✅ iOS  
- ✅ Web (Chrome, Safari, Firefox)
- ✅ Windows Desktop

### **Dependencias Principales**
- `flutter/material.dart`
- `cloud_firestore`
- `firebase_auth`
- `image_picker`
- `http` (para Cloudinary)

### **Servicios Integrados**
- Firebase Firestore (base de datos)
- Firebase Auth (autenticación)
- Cloudinary (almacenamiento de imágenes)
- Notificaciones locales

---

## 📊 **Estadísticas y Seguimiento**

### **Métricas Implementadas**
- Número total de donaciones
- Montos donados por mes
- Categorías de objetos más donadas
- Recolectores más activos
- Estados de donaciones

### **Reportes Disponibles**
- Dashboard de impacto en HomeScreen
- Historial personal de donaciones
- Estadísticas por recolector
- Seguimiento de vouchers

---

## 🚀 **Beneficios del Nuevo Sistema**

### **Para Donadores**
- Proceso más simple e intuitivo
- Múltiples opciones de contribución
- Comprobantes digitales automáticos
- Seguimiento del impacto

### **Para Recolectores**
- Gestión centralizada de donaciones
- Información completa de cada donación
- Coordinación eficiente de recogidas
- Herramientas de validación

### **Para la Institución**
- Mayor alcance y participación
- Datos estructurados y reportes
- Proceso transparente y auditable
- Impacto social medible

---

## 📝 **Próximas Mejoras Sugeridas**

1. **Notificaciones Push** para seguimiento de donaciones
2. **Geolocalización** para coordinar recogidas
3. **Calendario** para programar recogidas
4. **Sistema de Rating** para recolectores
5. **Certificados Digitales** de donación
6. **Integración con Redes Sociales** para compartir impacto

---

**Desarrollado para:** Universidad Nacional Federico Villarreal - Responsabilidad Social  
**Fecha:** Julio 2025  
**Estado:** ✅ Implementado y Funcional
