import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/data_migration_service.dart';

class AdminToolsScreen extends StatefulWidget {
  const AdminToolsScreen({super.key});

  @override
  State<AdminToolsScreen> createState() => _AdminToolsScreenState();
}

class _AdminToolsScreenState extends State<AdminToolsScreen> {
  bool _isRunningMigration = false;
  String _migrationStatus = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Herramientas de Administración'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Panel de Administración - Migración de Datos',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).primaryColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Herramientas para mantener la integridad y consistencia de los datos del sistema.',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 24),

            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.data_saver_on,
                          color: Colors.blue.shade700,
                          size: 28,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Migración y Corrección de Datos',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Corrige inconsistencias en los datos de donaciones y validaciones. '
                      'Esto incluye normalizar campos, corregir relaciones y verificar integridad.',
                    ),
                    const SizedBox(height: 16),
                    
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        ElevatedButton.icon(
                          onPressed: _isRunningMigration ? null : _fixDataInconsistencies,
                          icon: const Icon(Icons.cleaning_services),
                          label: const Text('Corregir Datos'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: _isRunningMigration ? null : _verifyDataIntegrity,
                          icon: const Icon(Icons.verified),
                          label: const Text('Verificar Integridad'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.purple,
                            foregroundColor: Colors.white,
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: _isRunningMigration ? null : _fixRelationships,
                          icon: const Icon(Icons.link),
                          label: const Text('Corregir Relaciones'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: _isRunningMigration ? null : _migrateVoucherUrls,
                          icon: const Icon(Icons.image),
                          label: const Text('Migrar Comprobantes'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                            foregroundColor: Colors.white,
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: _isRunningMigration ? null : _runFullMigration,
                          icon: const Icon(Icons.rocket_launch),
                          label: const Text('Migración Completa'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Configuración de Base de Datos',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.green.shade700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Crear y configurar las colecciones necesarias para nuevas funcionalidades.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        ElevatedButton.icon(
                          onPressed: _isRunningMigration ? null : _createTestimonialsCollection,
                          icon: const Icon(Icons.rate_review),
                          label: const Text('Crear Colección Testimonios'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: _isRunningMigration ? null : _createAttendanceCollection,
                          icon: const Icon(Icons.assignment_turned_in),
                          label: const Text('Crear Colección Asistencias'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.purple,
                            foregroundColor: Colors.white,
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: _isRunningMigration ? null : _createAllCollections,
                          icon: const Icon(Icons.data_object),
                          label: const Text('Crear Todas las Colecciones'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.indigo,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            if (_isRunningMigration || _migrationStatus.isNotEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          if (_isRunningMigration)
                            const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          if (_isRunningMigration) const SizedBox(width: 12),
                          Text(
                            _isRunningMigration ? 'Ejecutando migración...' : 'Estado de la migración',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      if (_migrationStatus.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: Text(
                            _migrationStatus,
                            style: const TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),

            const SizedBox(height: 24),

            Card(
              color: Colors.blue.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: Colors.blue.shade700,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Información Importante',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      '• Corregir Datos: Normaliza campos y formatos inconsistentes.\n'
                      '• Verificar Integridad: Valida relaciones entre donaciones y validaciones.\n'
                      '• Corregir Relaciones: Repara vínculos rotos entre documentos.\n'
                      '• Migrar Comprobantes: Mueve URLs de comprobantes a la colección de validación.\n'
                      '• Migración Completa: Ejecuta todas las tareas anteriores en secuencia.\n\n'
                      '⚠️ Estas operaciones pueden tomar varios minutos dependiendo del volumen de datos.',
                      style: TextStyle(height: 1.5),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _fixDataInconsistencies() async {
    await _runMigrationTask(
      'Corrección de inconsistencias de datos',
      DataMigrationService.fixDonationDataInconsistencies,
    );
  }

  Future<void> _verifyDataIntegrity() async {
    await _runMigrationTask(
      'Verificación de integridad de datos',
      DataMigrationService.verifyDataIntegrity,
    );
  }

  Future<void> _fixRelationships() async {
    await _runMigrationTask(
      'Corrección de relaciones',
      DataMigrationService.fixDonationValidationRelationship,
    );
  }

  Future<void> _migrateVoucherUrls() async {
    await _runMigrationTask(
      'Migración de URLs de comprobantes',
      DataMigrationService.migrateVoucherUrlsToValidation,
    );
  }

  Future<void> _runFullMigration() async {
    try {
      setState(() {
        _isRunningMigration = true;
        _migrationStatus = 'Iniciando migración completa...\n';
      });

      await _runMigrationTask(
        'Migración completa - Paso 1: Corrigiendo datos',
        DataMigrationService.fixDonationDataInconsistencies,
      );

      await _runMigrationTask(
        'Migración completa - Paso 2: Migrando comprobantes',
        DataMigrationService.migrateVoucherUrlsToValidation,
      );

      await _runMigrationTask(
        'Migración completa - Paso 3: Corrigiendo relaciones',
        DataMigrationService.fixDonationValidationRelationship,
      );

      await _runMigrationTask(
        'Migración completa - Paso 4: Verificando integridad',
        DataMigrationService.verifyDataIntegrity,
      );

      setState(() {
        _migrationStatus += '\n✅ Migración completa finalizada exitosamente.';
        _isRunningMigration = false;
      });

    } catch (e) {
      setState(() {
        _migrationStatus += '\n❌ Error en migración completa: $e';
        _isRunningMigration = false;
      });
    }
  }

  Future<void> _runMigrationTask(String taskName, Future<void> Function() task) async {
    try {
      setState(() {
        _isRunningMigration = true;
        _migrationStatus += '\n🔄 Iniciando: $taskName...';
      });

      await task();

      setState(() {
        _migrationStatus += '\n✅ Completado: $taskName';
      });

    } catch (e) {
      setState(() {
        _migrationStatus += '\n❌ Error en $taskName: $e';
      });
    } finally {
      setState(() {
        _isRunningMigration = false;
      });
    }
  }

  Future<void> _createTestimonialsCollection() async {
    await _runMigrationTask(
      'Crear colección de testimonios',
      () async {
        final firestore = FirebaseFirestore.instance;
        
        await firestore.collection('testimonios').doc('_config').set({
          'descripcion': 'Colección para almacenar testimonios de usuarios',
          'campos': {
            'contenido': 'string - Texto del testimonio',
            'puntuacion': 'number - Calificación de 1 a 5 estrellas',
            'usuarioId': 'string - ID del usuario que envió el testimonio',
            'nombreUsuario': 'string - Nombre para mostrar',
            'emailUsuario': 'string - Email del usuario',
            'anonimo': 'boolean - Si se envió como anónimo',
            'estado': 'string - pendiente, aprobado, rechazado',
            'fechaEnvio': 'timestamp - Cuándo se envió',
            'fechaRevision': 'timestamp - Cuándo se revisó',
            'adminRevisor': 'string - ID del admin que revisó',
            'motivoRechazo': 'string - Motivo si fue rechazado'
          },
          'creadoEn': FieldValue.serverTimestamp(),
        });
        
        setState(() {
          _migrationStatus += '\n📝 Nota: Crear índices en Firebase Console:';
          _migrationStatus += '\n   - estado (ascendente)';
          _migrationStatus += '\n   - fechaEnvio (descendente)';
          _migrationStatus += '\n   - usuarioId (ascendente)';
        });
      },
    );
  }

  Future<void> _createAttendanceCollection() async {
    await _runMigrationTask(
      'Crear colección de asistencias',
      () async {
        final firestore = FirebaseFirestore.instance;
        
        await firestore.collection('asistencias').doc('_config').set({
          'descripcion': 'Colección para registrar asistencia a eventos',
          'campos': {
            'eventoId': 'string - ID del evento',
            'usuarioId': 'string - ID del usuario',
            'nombreUsuario': 'string - Nombre del usuario',
            'emailUsuario': 'string - Email del usuario',
            'fechaRegistro': 'timestamp - Cuándo se registró la asistencia',
            'adminRegistrador': 'string - ID del admin que registró',
            'horasParticipacion': 'number - Horas de participación',
            'notas': 'string - Notas adicionales (opcional)'
          },
          'creadoEn': FieldValue.serverTimestamp(),
        });
        
        setState(() {
          _migrationStatus += '\n📝 Nota: Crear índices en Firebase Console:';
          _migrationStatus += '\n   - eventoId (ascendente)';
          _migrationStatus += '\n   - usuarioId (ascendente)';
          _migrationStatus += '\n   - fechaRegistro (descendente)';
          _migrationStatus += '\n   - eventoId + usuarioId (ascendente, ascendente)';
        });
      },
    );
  }

  Future<void> _createAllCollections() async {
    try {
      setState(() {
        _isRunningMigration = true;
        _migrationStatus = 'Iniciando creación de todas las colecciones...\n';
      });

      await _createTestimonialsCollection();
      await _createAttendanceCollection();

      setState(() {
        _migrationStatus += '\n✅ Todas las colecciones han sido creadas exitosamente.';
        _migrationStatus += '\n\n🔧 Pasos adicionales recomendados:';
        _migrationStatus += '\n1. Configurar reglas de seguridad en Firebase Console';
        _migrationStatus += '\n2. Crear los índices compuestos mencionados';
        _migrationStatus += '\n3. Configurar límites de cuota si es necesario';
        _isRunningMigration = false;
      });

    } catch (e) {
      setState(() {
        _migrationStatus += '\n❌ Error creando colecciones: $e';
        _isRunningMigration = false;
      });
    }
  }
}
