# 📋 DOCUMENTACIÓN COMPLETA - SISTEMA RSUNFV

## 🏗️ **ARQUITECTURA GENERAL**

La aplicación RSUNFV es una aplicación móvil desarrollada en **Flutter/Dart** con arquitectura **Clean Architecture**, integrada con **Firebase** para autenticación, base de datos y servicios cloud.

### **Stack Tecnológico**
- **Frontend:** Flutter/Dart
- **Backend:** Firebase (Firestore, Auth, Storage, Cloud Functions)
- **Servicios Cloud:** Cloudinary (gestión de imágenes)
- **Arquitectura:** Clean Architecture con separación de capas
- **Estado:** StatefulWidget con gestión local de estado
- **Navegación:** Navigator 2.0 con rutas nombradas

---

## 👥 **SISTEMA DE USUARIOS Y PERMISOS**

### **Roles de Usuario**

#### **1. Usuario Regular (estudiante/voluntario)**
**Permisos:** ✅ **PERMITIDO**
- ✅ Ver pantalla principal (dashboard)
- ✅ Participar en eventos
- ✅ Realizar donaciones
- ✅ Ver su perfil con estadísticas
- ✅ Recibir notificaciones
- ✅ Jugar minijuegos
- ✅ Enviar testimonios
- ✅ Actualizar información personal

**Restricciones:** ❌ **NO PERMITIDO**
- ❌ Acceder a funciones de administración
- ❌ Validar donaciones
- ❌ Marcar asistencia a eventos
- ❌ Ver estadísticas globales del sistema
- ❌ Administrar usuarios
- ❌ Crear/editar eventos

#### **2. Usuario Recolector**
**Permisos adicionales:** ✅ **PERMITIDO**
- ✅ Recibir donaciones monetarias
- ✅ Coordinar donaciones de objetos
- ✅ Gestionar métodos de pago (Yape, transferencia, efectivo)
- ✅ Aparecer en lista de recolectores disponibles

**Identificación:**
```dart
// En modelo Usuario
final bool esRecolector;
final String? numeroCuentaBancaria;
final String? numeroYape;
final bool aceptaEfectivo;
```

#### **3. Usuario Administrador**
**Permisos completos:** ✅ **PERMITIDO TODO**
- ✅ **Todas las funciones de usuario regular**
- ✅ **Control de asistencia a eventos**
- ✅ **Estadísticas administrativas**
- ✅ **Validación de donaciones**
- ✅ **Gestión de testimonios**
- ✅ **Acceso al dashboard administrativo**

**Identificación:**
```dart
// En modelo Usuario
final bool esAdmin;
bool get isAdmin => esAdmin;
```

### **Control de Acceso**

#### **Validación de Permisos en UI**
```dart
// Ejemplo en Drawer - Menú lateral
if (currentUser?.isAdmin == true) {
  // Mostrar opciones de administración
  ListTile(
    title: Text('ADMINISTRACIÓN'),
    subtitle: Text('Control de asistencia'),
    onTap: () => _navigateToAdminAttendance(),
  ),
}
```

#### **Protección de Rutas**
```dart
// En pantallas administrativas
@override
void initState() {
  super.initState();
  _checkAdminPermissions();
}

void _checkAdminPermissions() async {
  final user = await AuthService().getUserData();
  if (user?.data()?['esAdmin'] != true) {
    Navigator.pop(context);
    _showAccessDeniedDialog();
  }
}
```

---

## 📱 **MÓDULOS Y PANTALLAS**

### **🏠 MÓDULO HOME/PRINCIPAL**

#### **HomeScreen** (`lib/presentation/screens/home/home_screen.dart`)
**Funcionalidades:**
- ✅ Dashboard principal con estadísticas
- ✅ Calendario de eventos
- ✅ Carrusel de banners
- ✅ Estadísticas de impacto social
- ✅ Eventos próximos
- ✅ Navegación rápida a módulos

**Permisos requeridos:** Usuario autenticado
**Datos mostrados:**
- Eventos próximos
- Estadísticas personales
- Impacto social global
- Notificaciones recientes

---

### **🎯 MÓDULO EVENTOS**

#### **EventosScreenNew** (`lib/screens/events_screen_new.dart`)
**Funcionalidades:**
- ✅ Lista de eventos disponibles
- ✅ Filtros por categoría y fecha
- ✅ Búsqueda de eventos
- ✅ Registro a eventos
- ✅ Vista de calendario
- ✅ Detalles de eventos

**Permisos requeridos:** Usuario autenticado
**Navegación:**
```dart
AppRoutes.eventos → EventosScreenNew
AppRoutes.eventoDetalle → EventoDetailScreen (cards_screen.dart)
```

#### **EventoDetailScreen** (`lib/screens/cards_screen.dart`)
**Funcionalidades:**
- ✅ Información detallada del evento
- ✅ Sistema de tabs (Información/Impacto)
- ✅ Lista de participantes
- ✅ Registro/cancelación de participación
- ✅ Validación de requisitos
- ✅ Estadísticas del evento

**Permisos requeridos:** Usuario autenticado
**Restricciones:**
- Solo eventos públicos visibles
- Registro según disponibilidad
- Cancelación según políticas

---

### **💰 MÓDULO DONACIONES**

#### **Sistema Anti-Spam** (`lib/services/donation_anti_spam_service.dart`)
**Funcionalidades de seguridad:**
- 🔐 **Limitación por usuario autenticado**
- ⏰ **Tiempo mínimo entre uploads** (30 minutos)
- 📊 **Límite de donaciones pendientes** (máximo 3)
- 🛡️ **Límite diario** (máximo 5 donaciones)
- 📝 **Logging completo** de intentos

#### **DonationStartScreen** (`lib/screens/donation_start_screen.dart`)
**Funcionalidades:**
- ✅ Selección de monto de donación
- ✅ Montos rápidos predefinidos
- ✅ Validación anti-spam invisible
- ✅ Carga de datos del donador

**Permisos requeridos:** Usuario autenticado
**Validaciones:**
- Monto mínimo S/ 5.00
- Usuario debe estar autenticado
- Cumplir límites anti-spam

#### **DonationVoucherScreen** (`lib/screens/donation_voucher_screen.dart`)
**Funcionalidades:**
- ✅ Subida de comprobantes de pago
- ✅ Validación de imágenes
- ✅ Compatible con Web y Mobile
- ✅ Integración con Cloudinary

#### **DonationTypeSelectionScreen** (`lib/screens/donation_type_selection_screen.dart`)
**Funcionalidades:**
- ✅ Selección entre donación monetaria/objetos
- ✅ Flujos diferenciados
- ✅ Información detallada de cada tipo

#### **DonationObjectScreen** (`lib/screens/donation_object_screen.dart`)
**Funcionalidades:**
- ✅ Formulario para donaciones de objetos
- ✅ Categorías predefinidas
- ✅ Descripción y cantidad
- ✅ Estado de conservación
- ✅ Carga de fotos

#### **DonacionRecolectorScreen** (`lib/screen/donacion_recolector_s.dart`)
**Funcionalidades:**
- ✅ Selección de recolector certificado
- ✅ Información de métodos de pago
- ✅ Badges visuales (Yape, Banco, Efectivo)
- ✅ Verificación de disponibilidad

**Permisos requeridos:** Usuario autenticado
**Restricciones:**
- Solo recolectores activos y verificados
- Métodos de pago disponibles según recolector

---

### **👤 MÓDULO PERFIL**

#### **PerfilScreen** (`lib/screens/profile_screen.dart`)
**Funcionalidades:**
- ✅ Información personal del usuario
- ✅ Estadísticas de participación
- ✅ Historial de donaciones **validadas**
- ✅ Medallas obtenidas
- ✅ Progreso de gamificación
- ✅ Sistema de persistencia automática

**Permisos requeridos:** Usuario autenticado
**Datos mostrados:**
- Solo donaciones con `estadoValidacion: 'aprobada'`
- Eventos con asistencia confirmada
- Medallas ganadas por logros
- Estadísticas personales

#### **Sistema de Persistencia** (`lib/services/perfil_persistencia_service.dart`)
**Funcionalidades:**
- ✅ Sincronización automática con Firebase
- ✅ Cache local para performance
- ✅ Cálculo automático de estadísticas
- ✅ Sistema de medallas dinámico

---

### **🔔 MÓDULO NOTIFICACIONES**

#### **NotificationsScreen** (`lib/screens/notifications_screen.dart`)
**Funcionalidades:**
- ✅ Notificaciones de eventos
- ✅ Notificaciones de donaciones
- ✅ Mensajes del sistema
- ✅ Navegación desde notificaciones

**Servicios relacionados:**
- `LocalNotificationService`
- `NotificationTriggerService`
- `NotificationService`

---

### **🎮 MÓDULO JUEGOS**

#### **GamesHubScreen** (`lib/screens/games_hub_screen.dart`)
**Funcionalidades:**
- ✅ Hub central de minijuegos
- ✅ Quiz sobre responsabilidad social
- ✅ Sistema de puntuación
- ✅ Gamificación

#### **QuizGameScreen** (`lib/screens/quiz_game_screen.dart`)
**Funcionalidades:**
- ✅ Preguntas sobre RSU
- ✅ Sistema de puntos
- ✅ Integración con perfil

---

### **⚙️ MÓDULO CONFIGURACIÓN**

#### **Pantallas de Setup**
- `CycleScreen` - Selección de ciclo académico
- `CodeAgeScreen` - Código de estudiante y edad
- `FacultySchoolScreen` - Facultad y escuela
- `SizeScreen` - Talla para eventos

**Permisos requeridos:** Usuario en proceso de registro
**Flujo:** Obligatorio para nuevos usuarios

---

### **🛡️ MÓDULO ADMINISTRACIÓN**

#### **AdminEventAttendanceScreen** (`lib/screens/admin_event_attendance_screen.dart`)
**Funcionalidades:**
- ✅ Control de asistencia a eventos finalizados
- ✅ Marcado individual y masivo
- ✅ Validación de participantes registrados
- ✅ Persistencia en Firebase

**Permisos requeridos:** `esAdmin = true`
**Restricciones:**
- Solo eventos con estado "finalizado"
- Solo participantes previamente registrados

#### **AdminStatisticsScreen** (`lib/screens/admin_statistics_screen.dart`)
**Funcionalidades:**
- ✅ Estadísticas globales del sistema
- ✅ Métricas de eventos
- ✅ Análisis de donaciones
- ✅ Dashboard administrativo

**Permisos requeridos:** `esAdmin = true`

#### **ValidationScreen** (`lib/screens/validation_screen.dart`)
**Funcionalidades:**
- ✅ Validación de donaciones pendientes
- ✅ Aprobación/rechazo de vouchers
- ✅ Gestión de estados

**Permisos requeridos:** `esAdmin = true`

---

## 🗄️ **MODELOS DE DATOS**

### **Usuario** (`lib/models/usuario.dart`)
```dart
class Usuario {
  final String idUsuario;
  final String nombreUsuario;
  final String apellidoUsuario;
  final String correo;
  final String codigo;
  final int edad;
  final String idFacultad;
  final String idEscuela;
  final String idTalla;
  final int ciclo;
  final bool esAdmin;           // Control de permisos administrativos
  final bool esRecolector;      // Puede recibir donaciones
  final String? numeroCuentaBancaria;
  final String? numeroYape;
  final bool aceptaEfectivo;
  // ... otros campos
}
```

### **Evento** (`lib/models/evento.dart`)
```dart
class Evento {
  final String idEvento;
  final String nombreEvento;
  final String descripcionEvento;
  final String fechaEvento;
  final String horaEvento;
  final String lugarEvento;
  final String estadoEvento;    // 'programado', 'en_curso', 'finalizado'
  final int capacidadMaxima;
  final List<String> participantesRegistrados;
  // ... otros campos
}
```

### **Donaciones** (`lib/models/donaciones.dart`)
```dart
class Donaciones {
  final String idDonacion;
  final String idUsuarioDonador;
  final double monto;
  final String tipoDonacion;    // 'dinero', 'objetos'
  final String estadoValidacion; // 'pendiente', 'aprobada', 'rechazada'
  final String fechaDonacion;
  final String? comprobantePago;
  final String? idRecolector;
  // ... otros campos
}
```

### **PerfilUsuario** (`lib/models/perfil_usuario.dart`)
```dart
class PerfilUsuario {
  final String idUsuario;
  final EstadisticasUsuario estadisticas;
  final List<MedallaObtenida> medallasObtenidas;
  final List<RegistroEvento> historialEventos;
  final List<RegistroDonacion> historialDonaciones;
  final ProgresoGamificacion progresoGamificacion;
  // ... otros campos
}
```

---

## 🔒 **SERVICIOS DE SEGURIDAD**

### **DonationAntiSpamService** (`lib/services/donation_anti_spam_service.dart`)
**Funcionalidades:**
- 🔐 Validación de usuario autenticado
- ⏰ Control de tiempo entre donaciones (30 min)
- 📊 Límite de donaciones pendientes (3 máx)
- 🛡️ Límite diario (5 máx)
- 📝 Logging de intentos
- 🚫 Prevención de spam automático

**Métodos principales:**
```dart
static Future<ValidationResult> canUserUploadVoucher();
static Future<void> logUploadAttempt({required String userId, required bool success});
```

### **AuthService** (`lib/services/firebase_auth_services.dart`)
**Funcionalidades:**
- 🔐 Autenticación con Firebase
- 👤 Gestión de sesiones
- 📊 Obtención de datos de usuario
- 🔄 Renovación de tokens

---

## 🚀 **SERVICIOS PRINCIPALES**

### **Servicios de Firebase**
- `FirebaseService` - Operaciones generales de Firestore
- `FirebaseAuthServices` - Autenticación
- `CloudinaryServices` - Gestión de imágenes

### **Servicios de Datos**
- `DonationsService` - Gestión de donaciones
- `StatisticsService` - Cálculo de estadísticas
- `ProfileService` - Gestión de perfiles
- `PerfilPersistenciaService` - Persistencia automática

### **Servicios de Notificaciones**
- `LocalNotificationService` - Notificaciones locales
- `NotificationTriggerService` - Disparadores automáticos
- `NotificationService` - Gestión centralizada

### **Servicios de Utilidad**
- `ExcelServices` - Exportación de datos
- `ValidationService` - Validaciones generales
- `SetupService` - Configuración inicial

---

## 📱 **FLUJOS DE USUARIO**

### **Flujo de Registro**
```
1. SplashScreen
2. LoginScreen
3. RegisterScreen
4. SetupScreens (Ciclo → Código → Facultad → Talla)
5. HomeScreen
```

### **Flujo de Donación Monetaria**
```
1. DonacionesScreen
2. DonationStartScreen (monto)
3. DonacionRecolectorScreen (selección)
4. DonationVoucherScreen (comprobante)
5. Confirmación
```

### **Flujo de Donación de Objetos**
```
1. DonacionesScreen
2. DonationTypeSelectionScreen
3. DonationObjectScreen (detalles)
4. DonacionRecolectorScreen
5. DonacionCoordinacionScreen
```

### **Flujo de Eventos**
```
1. HomeScreen/EventosScreenNew
2. EventoDetailScreen (información)
3. Registro en evento
4. Asistencia (marcada por admin)
5. Actualización automática de perfil
```

---

## 🔧 **CONFIGURACIÓN Y DEPLOYMENT**

### **Rutas de la Aplicación** (`lib/core/constants/app_routes.dart`)
```dart
static const String home = '/home';
static const String eventos = '/eventos';
static const String donaciones = '/donaciones';
static const String perfil = '/perfil';
static const String notificaciones = '/notificaciones';
// ... más rutas
```

### **Estructura de Firebase Firestore**
```
/usuarios/{userId}
/eventos/{eventoId}
/donaciones/{donacionId}
/notification_logs/{logId}
/donation_upload_logs/{logId}
/testimonios/{testimonioId}
```

---

## 📊 **MÉTRICAS Y ANALÍTICAS**

### **Sistema de Estadísticas**
- ✅ Estadísticas personales de usuario
- ✅ Métricas globales del sistema
- ✅ Análisis de participación en eventos
- ✅ Tracking de donaciones por estado
- ✅ Sistema de medallas automático

### **Dashboard Administrativo**
- ✅ Total de usuarios registrados
- ✅ Eventos realizados y próximos
- ✅ Donaciones por validar
- ✅ Estadísticas de impacto social

---

## 🎯 **GAMIFICACIÓN**

### **Sistema de Medallas**
- 🥉 Primera donación
- 🥈 Donador frecuente (5+ donaciones)
- 🥇 Participante activo (10+ eventos)
- 🏆 Embajador RSU (logros combinados)

### **Progreso de Usuario**
- 📊 Puntos por actividades
- 🎮 Niveles de gamificación
- 🏅 Logros desbloqueables
- 📈 Ranking social

---

## 🛠️ **HERRAMIENTAS DE DESARROLLO**

### **Scripts de Mantenimiento**
- `clean_comments.ps1` - Limpieza de comentarios
- `fix_print.ps1` - Corrección de prints
- `fix_withopacity.ps1` - Actualización de widgets

### **Análisis de Código**
- `analysis_options.yaml` - Configuración de análisis estático
- Informes de calidad de código generados
- Cumplimiento con Effective Dart

---

## 📋 **RESUMEN DE PERMISOS**

| Funcionalidad | Usuario Regular | Recolector | Administrador |
|---------------|----------------|------------|---------------|
| Ver eventos | ✅ | ✅ | ✅ |
| Registrarse en eventos | ✅ | ✅ | ✅ |
| Realizar donaciones | ✅ | ✅ | ✅ |
| Recibir donaciones | ❌ | ✅ | ✅ |
| Ver perfil personal | ✅ | ✅ | ✅ |
| Marcar asistencia | ❌ | ❌ | ✅ |
| Validar donaciones | ❌ | ❌ | ✅ |
| Ver estadísticas globales | ❌ | ❌ | ✅ |
| Administrar testimonios | ❌ | ❌ | ✅ |

---

*Este documento representa el estado actual del sistema RSUNFV con todas sus funcionalidades, permisos y arquitectura implementada.*
