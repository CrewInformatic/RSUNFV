import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:rsunfv_app/services/medals_service.dart';
import 'package:rsunfv_app/firebase_options.dart';

/// Script para inicializar las medallas y rangos en Firestore
/// Ejecutar este script una sola vez para configurar la base de datos
void main() async {
  // Inicializar Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  print('Iniciando configuración de la base de datos...');

  try {
    // 1. Inicializar medallas base
    await MedalsService.inicializarMedallasBase();
    print('✅ Medallas base inicializadas');

    // 2. Crear rangos de estadísticas
    await _crearRangosEstadisticas();
    print('✅ Rangos de estadísticas creados');

    // 3. Crear colecciones índice
    await _crearColeccionesIndice();
    print('✅ Colecciones índice creadas');

    print('\n🎉 Base de datos configurada exitosamente!');
    print('\nEstructura creada:');
    print('- medallas/: Medallas disponibles del sistema');
    print('- usuarios_medallas/: Medallas obtenidas por cada usuario');
    print('- rangos_estadisticas/: Niveles y rangos del sistema');
    print('- usuarios_estadisticas/: Estadísticas calculadas de cada usuario');

  } catch (e) {
    print('❌ Error configurando la base de datos: $e');
  }
}

Future<void> _crearRangosEstadisticas() async {
  final firestore = FirebaseFirestore.instance;
  final batch = firestore.batch();

  final rangos = [
    {
      'nombre': 'Principiante',
      'descripcion': 'Está empezando su camino en el voluntariado',
      'puntosRequeridos': 0,
      'icono': '🌱',
      'color': '#8BC34A',
      'beneficios': ['Acceso básico a eventos', 'Perfil personalizable'],
    },
    {
      'nombre': 'Voluntario',
      'descripcion': 'Ya tiene experiencia en voluntariado',
      'puntosRequeridos': 50,
      'icono': '🙋‍♂️',
      'color': '#2196F3',
      'beneficios': [
        'Acceso a eventos especiales',
        'Certificados de participación',
        'Notificaciones prioritarias',
      ],
    },
    {
      'nombre': 'Colaborador',
      'descripcion': 'Contribuye activamente a la comunidad',
      'puntosRequeridos': 150,
      'icono': '🤝',
      'color': '#FF9800',
      'beneficios': [
        'Acceso a eventos exclusivos',
        'Participación en decisiones',
        'Descuentos en eventos pagos',
      ],
    },
    {
      'nombre': 'Activista',
      'descripcion': 'Defiende causas importantes',
      'puntosRequeridos': 300,
      'icono': '✊',
      'color': '#9C27B0',
      'beneficios': [
        'Creación de eventos propios',
        'Rol de moderador en foros',
        'Acceso a recursos premium',
      ],
    },
    {
      'nombre': 'Héroe',
      'descripcion': 'Un verdadero héroe de la comunidad',
      'puntosRequeridos': 500,
      'icono': '🦸‍♂️',
      'color': '#FF5722',
      'beneficios': [
        'Acceso total a la plataforma',
        'Reconocimientos públicos',
        'Eventos VIP exclusivos',
        'Mentoría a nuevos usuarios',
      ],
    },
    {
      'nombre': 'Leyenda',
      'descripcion': 'Una leyenda viviente del voluntariado',
      'puntosRequeridos': 1000,
      'icono': '👑',
      'color': '#FFD700',
      'beneficios': [
        'Privilegios de administrador',
        'Reconocimiento permanente',
        'Eventos únicos y exclusivos',
        'Impacto en decisiones estratégicas',
      ],
    },
  ];

  for (int i = 0; i < rangos.length; i++) {
    final rango = rangos[i];
    final docRef = firestore.collection('rangos_estadisticas').doc('rango_$i');
    batch.set(docRef, rango);
  }

  await batch.commit();
}

Future<void> _crearColeccionesIndice() async {
  final firestore = FirebaseFirestore.instance;

  // Crear documento de ejemplo para usuarios_medallas
  await firestore.collection('usuarios_medallas').doc('_ejemplo').set({
    'userId': 'ejemplo_usuario_id',
    'medallaId': 'ejemplo_medalla_id',
    'fechaObtencion': FieldValue.serverTimestamp(),
    'tipo': 'eventos',
    'categoria': 'bronce',
    '_isExample': true,
  });

  // Crear documento de ejemplo para usuarios_estadisticas
  await firestore.collection('usuarios_estadisticas').doc('_ejemplo').set({
    'eventosInscritos': 0,
    'eventosCompletados': 0,
    'eventosPendientes': 0,
    'eventosEnProceso': 0,
    'horasTotales': 0.0,
    'rachaActual': 0,
    'mejorRacha': 0,
    'donacionesRealizadas': 0,
    'montoTotalDonado': 0.0,
    'puntosTotales': 0,
    'nivelActual': 'Principiante',
    'progresoNivelSiguiente': 0.0,
    'fechaActualizacion': FieldValue.serverTimestamp(),
    '_isExample': true,
  });

  print('📝 Documentos de ejemplo creados para definir estructura');
}
