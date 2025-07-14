# Estructura de Base de Datos Cloud Firestore para RSUNFV

## Colecciones Necesarias

### 1. usuarios
Almacena información de los usuarios registrados.
```
{
  "nombreUsuario": "string",
  "correo": "string", 
  "codigoUsuario": "string",
  "carrera": "string",
  "facultad": "string",
  "ciclo": "number",
  "talla": "string",
  "fechaRegistro": "timestamp",
  "isAdmin": "boolean",
  "activo": "boolean"
}
```

### 2. eventos
Almacena información de los eventos de voluntariado.
```
{
  "titulo": "string",
  "descripcion": "string",
  "foto": "string",
  "ubicacion": "string",
  "requisitos": "string",
  "cantidadVoluntariosMax": "number",
  "voluntariosInscritos": ["string"], // Array de IDs de usuarios
  "fechaInicio": "string",
  "horaInicio": "string", 
  "horaFin": "string",
  "estado": "string", // 'activo', 'finalizado', 'cancelado'
  "tipo": "string",
  "createdBy": "string", // ID del usuario administrador
  "fechaCreacion": "string",
  // Métricas de impacto (nuevas)
  "personasAyudadas": "number",
  "plantasPlantadas": "number", 
  "basuraRecolectadaKg": "number",
  "metricasPersonalizadas": {
    "nombreMetrica": "valor"
  }
}
```

### 3. testimonios (NUEVA - CREAR ESTA COLECCIÓN)
Almacena los testimonios de los usuarios.
```
{
  "usuarioId": "string",
  "nombre": "string",
  "carrera": "string", 
  "mensaje": "string",
  "rating": "number", // 1-5
  "aprobado": "boolean",
  "fechaCreacion": "timestamp",
  "fechaAprobacion": "timestamp",
  "adminAprobador": "string",
  "esAnonimo": "boolean",
  "avatar": "string"
}
```

### 4. asistencias (NUEVA - CREAR ESTA COLECCIÓN)
Almacena el registro de asistencia de voluntarios a eventos.
```
{
  "idEvento": "string",
  "idUsuario": "string", 
  "asistio": "boolean",
  "fechaMarcado": "timestamp",
  "marcadoPor": "string", // ID del admin que marcó la asistencia
  "observaciones": "string"
}
```

### 5. registros_eventos
Almacena las inscripciones a eventos.
```
{
  "idEvento": "string",
  "idUsuario": "string",
  "fechaRegistro": "string"
}
```

### 6. donaciones
Almacena información de las donaciones.
```
{
  "monto": "number",
  "metodo": "string",
  "estado": "string",
  "fechaCreacion": "timestamp",
  "usuarioId": "string"
}
```

### 7. notificaciones
Almacena las notificaciones del sistema.
```
{
  "userId": "string",
  "titulo": "string",
  "mensaje": "string", 
  "tipo": "string",
  "leida": "boolean",
  "fechaCreacion": "timestamp"
}
```

## Índices Necesarios

Para optimizar las consultas, crear estos índices en Cloud Firestore:

### testimonios
- `usuarioId` (ascendente) + `fechaCreacion` (descendente)
- `aprobado` (ascendente) + `fechaCreacion` (descendente)

### asistencias
- `idEvento` (ascendente) + `idUsuario` (ascendente)
- `idEvento` (ascendente) + `asistio` (ascendente)

### eventos
- `estado` (ascendente) + `fechaInicio` (ascendente)
- `createdBy` (ascendente) + `fechaCreacion` (descendente)

### registros_eventos
- `idEvento` (ascendente) + `fechaRegistro` (descendente)
- `idUsuario` (ascendente) + `fechaRegistro` (descendente)

## Configuración de Reglas de Seguridad

Las reglas están definidas en el archivo `firestore.rules`. Asegúrate de aplicarlas en la consola de Firebase.

## Pasos para Configurar

1. Ve a la consola de Firebase
2. Selecciona tu proyecto RSUNFV
3. Ve a Firestore Database
4. Crea las colecciones necesarias (si no existen)
5. Aplica las reglas de seguridad del archivo `firestore.rules`
6. Crea los índices mencionados arriba

## Notas Importantes

- La colección `eventos_impacto` ya no se usa, las métricas ahora están en `eventos`
- La colección `asistencias_voluntarios` ahora es `asistencias`
- Asegúrate de que los usuarios administradores tengan `isAdmin: true` en su documento
