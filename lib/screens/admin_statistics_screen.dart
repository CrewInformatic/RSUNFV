import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/evento.dart';

class AdminStatisticsScreen extends StatefulWidget {
  const AdminStatisticsScreen({super.key});

  @override
  State<AdminStatisticsScreen> createState() => _AdminStatisticsScreenState();
}

class _AdminStatisticsScreenState extends State<AdminStatisticsScreen> {
  bool _isLoading = true;
  bool _isAdmin = false;
  Map<String, dynamic> _stats = {};

  @override
  void initState() {
    super.initState();
    _checkAdminAndLoadStats();
  }

  Future<void> _checkAdminAndLoadStats() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      Navigator.pop(context);
      return;
    }

    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(currentUser.uid)
          .get();

      if (userDoc.exists) {
        final userData = userDoc.data()!;
        final isAdmin = userData['esAdmin'] ?? false;
        
        if (!isAdmin) {
          _showUnauthorizedDialog();
          return;
        }

        setState(() {
          _isAdmin = true;
        });

        await _loadStatistics();
      }
    } catch (e) {
      _showErrorSnackBar('Error verificando permisos: $e');
    }
  }

  void _showUnauthorizedDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.security, color: Colors.red),
              SizedBox(width: 8),
              Text('Acceso Denegado'),
            ],
          ),
          content: const Text(
            'Solo los administradores pueden acceder a esta funcionalidad.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pop(context);
              },
              child: const Text('Entendido'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _loadStatistics() async {
    try {
      final now = DateTime.now();
      final thirtyDaysAgo = now.subtract(const Duration(days: 30));
      final sevenDaysAgo = now.subtract(const Duration(days: 7));

      // Obtener todos los eventos
      final eventsQuery = await FirebaseFirestore.instance
          .collection('eventos')
          .get();

      // Obtener todas las asistencias
      final attendanceQuery = await FirebaseFirestore.instance
          .collection('asistencias_eventos')
          .get();

      // Obtener todos los usuarios
      final usersQuery = await FirebaseFirestore.instance
          .collection('usuarios')
          .get();

      final events = <Evento>[];
      for (var doc in eventsQuery.docs) {
        try {
          final evento = Evento.fromFirestore(doc);
          events.add(evento);
        } catch (e) {
          debugPrint('Error parsing event ${doc.id}: $e');
        }
      }

      // Calcular estadísticas
      int totalEvents = events.length;
      int activeEvents = events.where((e) => e.estado == 'activo').length;
      int completedEvents = events.where((e) => e.estado == 'finalizado').length;
      int totalRegistrations = events.fold(0, (total, event) => total + event.voluntariosInscritos.length);

      // Eventos recientes (últimos 30 días)
      int recentEvents = events.where((event) {
        try {
          final eventDate = DateTime.parse(event.fechaInicio);
          return eventDate.isAfter(thirtyDaysAgo);
        } catch (e) {
          return false;
        }
      }).length;

      // Eventos de esta semana
      int weekEvents = events.where((event) {
        try {
          final eventDate = DateTime.parse(event.fechaInicio);
          return eventDate.isAfter(sevenDaysAgo);
        } catch (e) {
          return false;
        }
      }).length;

      // Calcular asistencias
      int totalAttendances = 0;
      int eventsWithAttendance = 0;
      
      for (var doc in attendanceQuery.docs) {
        final data = doc.data();
        final asistencias = data['asistencias'] as Map<String, dynamic>? ?? {};
        totalAttendances += asistencias.values.where((attended) => attended == true).length;
        eventsWithAttendance++;
      }

      // Promedio de asistencia
      double averageAttendance = eventsWithAttendance > 0 
          ? (totalAttendances / totalRegistrations) * 100 
          : 0.0;

      // Categorías más populares
      Map<String, int> categoryCount = {};
      for (var event in events) {
        final category = event.idTipo;
        categoryCount[category] = (categoryCount[category] ?? 0) + 1;
      }

      setState(() {
        _stats = {
          'totalEvents': totalEvents,
          'activeEvents': activeEvents,
          'completedEvents': completedEvents,
          'totalRegistrations': totalRegistrations,
          'recentEvents': recentEvents,
          'weekEvents': weekEvents,
          'totalAttendances': totalAttendances,
          'eventsWithAttendance': eventsWithAttendance,
          'averageAttendance': averageAttendance,
          'categoryCount': categoryCount,
          'totalUsers': usersQuery.docs.length,
        };
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorSnackBar('Error cargando estadísticas: $e');
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_isAdmin || _isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Estadísticas de Administración'),
          backgroundColor: Colors.orange.shade700,
          foregroundColor: Colors.white,
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Estadísticas de Administración'),
        backgroundColor: Colors.orange.shade700,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() {
                _isLoading = true;
              });
              _loadStatistics();
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          setState(() {
            _isLoading = true;
          });
          await _loadStatistics();
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Header con resumen general
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.orange.shade700, Colors.orange.shade500],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  const Icon(
                    Icons.dashboard,
                    size: 48,
                    color: Colors.white,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Panel de Administración',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Estadísticas generales del sistema RSU',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Estadísticas principales
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: 1.2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              children: [
                _buildStatCard(
                  'Total Eventos',
                  '${_stats['totalEvents'] ?? 0}',
                  Icons.event,
                  Colors.blue.shade700,
                ),
                _buildStatCard(
                  'Eventos Activos',
                  '${_stats['activeEvents'] ?? 0}',
                  Icons.event_available,
                  Colors.green.shade700,
                ),
                _buildStatCard(
                  'Total Inscripciones',
                  '${_stats['totalRegistrations'] ?? 0}',
                  Icons.people,
                  Colors.purple.shade700,
                ),
                _buildStatCard(
                  'Total Usuarios',
                  '${_stats['totalUsers'] ?? 0}',
                  Icons.person,
                  Colors.orange.shade700,
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Estadísticas de tiempo
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Actividad Reciente',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _buildTimeStatCard(
                            'Últimos 30 días',
                            '${_stats['recentEvents'] ?? 0}',
                            'eventos',
                            Colors.blue,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildTimeStatCard(
                            'Esta semana',
                            '${_stats['weekEvents'] ?? 0}',
                            'eventos',
                            Colors.green,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Estadísticas de asistencia
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Control de Asistencia',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _buildAttendanceCard(
                            'Eventos con Asistencia',
                            '${_stats['eventsWithAttendance'] ?? 0}',
                            'de ${_stats['completedEvents'] ?? 0}',
                            Colors.blue.shade700,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildAttendanceCard(
                            'Total Asistencias',
                            '${_stats['totalAttendances'] ?? 0}',
                            'confirmadas',
                            Colors.green.shade700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.orange.shade200),
                      ),
                      child: Column(
                        children: [
                          Text(
                            'Promedio de Asistencia',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.orange.shade700,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${(_stats['averageAttendance'] ?? 0.0).toStringAsFixed(1)}%',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.orange.shade700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Categorías más populares
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Categorías de Eventos',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ..._buildCategoryList(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            colors: [color.withValues(alpha: 0.1), color.withValues(alpha: 0.05)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 32,
              color: color,
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                color: color.withValues(alpha: 0.8),
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeStatCard(String title, String value, String subtitle, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 10,
              color: color.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttendanceCard(String title, String value, String subtitle, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 10,
              color: color.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildCategoryList() {
    final categoryCount = _stats['categoryCount'] as Map<String, int>? ?? {};
    final categories = categoryCount.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    if (categories.isEmpty) {
      return [
        const Text(
          'No hay datos de categorías disponibles',
          style: TextStyle(
            color: Colors.grey,
            fontStyle: FontStyle.italic,
          ),
        ),
      ];
    }

    return categories.map((entry) {
      final categoryName = _getCategoryDisplayName(entry.key);
      final count = entry.value;
      final total = categoryCount.values.fold(0, (acc, value) => acc + value);
      final percentage = total > 0 ? (count / total * 100) : 0.0;

      return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          children: [
            Expanded(
              flex: 3,
              child: Text(
                categoryName,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Expanded(
              flex: 2,
              child: Container(
                height: 8,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: percentage / 100,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.orange.shade700,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '$count (${percentage.toStringAsFixed(1)}%)',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }).toList();
  }

  String _getCategoryDisplayName(String categoryId) {
    switch (categoryId) {
      case 'educacion':
        return 'Educación';
      case 'social':
        return 'Social';
      case 'ambiental':
        return 'Ambiental';
      case 'salud':
        return 'Salud';
      case 'deportivo':
        return 'Deportivo';
      case 'cultural':
        return 'Cultural';
      default:
        return categoryId.isNotEmpty 
            ? categoryId[0].toUpperCase() + categoryId.substring(1)
            : 'Sin categoría';
    }
  }
}
