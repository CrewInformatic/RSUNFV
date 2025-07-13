import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/evento.dart';

class AdminEventAttendanceScreen extends StatefulWidget {
  const AdminEventAttendanceScreen({super.key});

  @override
  State<AdminEventAttendanceScreen> createState() => _AdminEventAttendanceScreenState();
}

class _AdminEventAttendanceScreenState extends State<AdminEventAttendanceScreen> {
  bool _isLoading = true;
  bool _isAdmin = false;
  List<Evento> _completedEvents = [];
  Evento? _selectedEvent;
  List<Map<String, dynamic>> _eventVolunteers = [];
  Map<String, bool> _attendanceMap = {};

  @override
  void initState() {
    super.initState();
    _checkAdminStatus();
  }

  Future<void> _checkAdminStatus() async {
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

        await _loadCompletedEvents();
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

  Future<void> _loadCompletedEvents() async {
    try {
      // Cargar eventos finalizados (simplificado para evitar problemas de índices)
      final eventsQuery = await FirebaseFirestore.instance
          .collection('eventos')
          .where('estado', isEqualTo: 'finalizado')
          .orderBy('fechaInicio', descending: true)
          .limit(20) // Limitar a los últimos 20 eventos finalizados
          .get();

      final events = <Evento>[];
      final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
      
      for (var doc in eventsQuery.docs) {
        try {
          final evento = Evento.fromFirestore(doc);
          // Filtrar en el cliente los eventos de los últimos 30 días
          final eventDate = DateTime.tryParse(evento.fechaInicio);
          if (eventDate != null && eventDate.isAfter(thirtyDaysAgo)) {
            events.add(evento);
          }
        } catch (e) {
          debugPrint('Error parsing event ${doc.id}: $e');
        }
      }

      setState(() {
        _completedEvents = events;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorSnackBar('Error cargando eventos: $e');
    }
  }

  Future<void> _loadEventVolunteers(Evento event) async {
    setState(() {
      _isLoading = true;
      _selectedEvent = event;
      _eventVolunteers.clear();
      _attendanceMap.clear();
    });

    try {
      final volunteers = <Map<String, dynamic>>[];

      // Cargar información de cada voluntario inscrito
      for (String userId in event.voluntariosInscritos) {
        try {
          final userDoc = await FirebaseFirestore.instance
              .collection('usuarios')
              .doc(userId)
              .get();

          if (userDoc.exists) {
            final userData = userDoc.data()!;
            volunteers.add({
              'id': userId,
              'nombre': '${userData['nombreUsuario'] ?? ''} ${userData['apellidoUsuario'] ?? ''}'.trim(),
              'codigo': userData['codigoUsuario'] ?? 'Sin código',
              'correo': userData['correo'] ?? 'Sin correo',
              'fotoPerfil': userData['fotoPerfil'] ?? '',
            });
          }
        } catch (e) {
          debugPrint('Error loading user $userId: $e');
        }
      }

      // Cargar asistencia existente si ya fue marcada
      final attendanceDoc = await FirebaseFirestore.instance
          .collection('asistencias_eventos')
          .doc(event.idEvento)
          .get();

      final existingAttendance = <String, bool>{};
      if (attendanceDoc.exists) {
        final attendanceData = attendanceDoc.data()!;
        final asistencias = attendanceData['asistencias'] as Map<String, dynamic>? ?? {};
        for (var entry in asistencias.entries) {
          existingAttendance[entry.key] = entry.value as bool? ?? false;
        }
      }

      setState(() {
        _eventVolunteers = volunteers;
        _attendanceMap = existingAttendance;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorSnackBar('Error cargando voluntarios: $e');
    }
  }

  Future<void> _saveAttendance() async {
    if (_selectedEvent == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final attendanceData = {
        'eventoId': _selectedEvent!.idEvento,
        'eventoTitulo': _selectedEvent!.titulo,
        'fechaEvento': _selectedEvent!.fechaInicio,
        'fechaRegistro': DateTime.now().toIso8601String(),
        'registradoPor': FirebaseAuth.instance.currentUser!.uid,
        'asistencias': _attendanceMap,
        'totalInscritos': _selectedEvent!.voluntariosInscritos.length,
        'totalAsistentes': _attendanceMap.values.where((attended) => attended).length,
      };

      await FirebaseFirestore.instance
          .collection('asistencias_eventos')
          .doc(_selectedEvent!.idEvento)
          .set(attendanceData);

      // Actualizar estadísticas de los voluntarios
      await _updateVolunteerStats();

      setState(() {
        _isLoading = false;
      });

      _showSuccessSnackBar('Asistencia guardada correctamente');
      
      // Volver a la lista de eventos
      setState(() {
        _selectedEvent = null;
        _eventVolunteers.clear();
        _attendanceMap.clear();
      });

    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorSnackBar('Error guardando asistencia: $e');
    }
  }

  Future<void> _updateVolunteerStats() async {
    final batch = FirebaseFirestore.instance.batch();

    for (var volunteer in _eventVolunteers) {
      final userId = volunteer['id'] as String;
      final attended = _attendanceMap[userId] ?? false;

      if (attended) {
        // Incrementar contador de eventos asistidos
        final userRef = FirebaseFirestore.instance.collection('usuarios').doc(userId);
        batch.update(userRef, {
          'eventosAsistidos': FieldValue.increment(1),
          'horasVoluntariado': FieldValue.increment(4), // Asumir 4 horas por evento
          'ultimaActividad': DateTime.now().toIso8601String(),
        });

        // Registrar en historial de asistencias
        final historialRef = FirebaseFirestore.instance
            .collection('historial_asistencias')
            .doc('${_selectedEvent!.idEvento}_$userId');
        
        batch.set(historialRef, {
          'eventoId': _selectedEvent!.idEvento,
          'eventoTitulo': _selectedEvent!.titulo,
          'usuarioId': userId,
          'asistio': true,
          'fechaEvento': _selectedEvent!.fechaInicio,
          'fechaRegistro': DateTime.now().toIso8601String(),
          'horasAcreditadas': 4,
        });
      }
    }

    await batch.commit();
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_isAdmin) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_selectedEvent == null 
            ? 'Control de Asistencia' 
            : 'Asistencia - ${_selectedEvent!.titulo}'),
        backgroundColor: Colors.orange.shade700,
        foregroundColor: Colors.white,
        actions: [
          if (_selectedEvent != null)
            IconButton(
              icon: const Icon(Icons.save),
              onPressed: _isLoading ? null : _saveAttendance,
              tooltip: 'Guardar Asistencia',
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _selectedEvent == null
              ? _buildEventsList()
              : _buildAttendanceList(),
    );
  }

  Widget _buildEventsList() {
    if (_completedEvents.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.event_busy,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No hay eventos finalizados recientes',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Los eventos aparecerán aquí una vez finalizados',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _completedEvents.length,
      itemBuilder: (context, index) {
        final event = _completedEvents[index];
        return _buildEventCard(event);
      },
    );
  }

  Widget _buildEventCard(Evento event) {
    final eventDate = DateTime.tryParse(event.fechaInicio);
    final formattedDate = eventDate != null
        ? '${eventDate.day}/${eventDate.month}/${eventDate.year}'
        : 'Fecha no disponible';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _loadEventVolunteers(event),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: Colors.green,
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      event.titulo,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Icon(
                    Icons.chevron_right,
                    color: Colors.grey[400],
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                event.descripcion,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    Icons.calendar_today,
                    size: 16,
                    color: Colors.orange.shade700,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    formattedDate,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.orange.shade700,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Icon(
                    Icons.people,
                    size: 16,
                    color: Colors.blue.shade700,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${event.voluntariosInscritos.length} voluntarios',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.blue.shade700,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAttendanceList() {
    if (_eventVolunteers.isEmpty) {
      return const Center(
        child: Text('No hay voluntarios inscritos en este evento'),
      );
    }

    return Column(
      children: [
        // Header con estadísticas
        Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.orange.shade700, Colors.orange.shade500],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    Text(
                      '${_eventVolunteers.length}',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const Text(
                      'Inscritos',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 1,
                height: 40,
                color: Colors.white.withValues(alpha: 0.5),
              ),
              Expanded(
                child: Column(
                  children: [
                    Text(
                      '${_attendanceMap.values.where((attended) => attended).length}',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const Text(
                      'Asistieron',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Botones de acción rápida
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    setState(() {
                      for (var volunteer in _eventVolunteers) {
                        _attendanceMap[volunteer['id']] = true;
                      }
                    });
                  },
                  icon: const Icon(Icons.check_circle),
                  label: const Text('Marcar Todos'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.green,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    setState(() {
                      for (var volunteer in _eventVolunteers) {
                        _attendanceMap[volunteer['id']] = false;
                      }
                    });
                  },
                  icon: const Icon(Icons.cancel),
                  label: const Text('Desmarcar Todos'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Lista de voluntarios
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _eventVolunteers.length,
            itemBuilder: (context, index) {
              final volunteer = _eventVolunteers[index];
              return _buildVolunteerAttendanceCard(volunteer);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildVolunteerAttendanceCard(Map<String, dynamic> volunteer) {
    final userId = volunteer['id'] as String;
    final isPresent = _attendanceMap[userId] ?? false;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isPresent ? Colors.green : Colors.grey[300],
          child: volunteer['fotoPerfil'] != null && volunteer['fotoPerfil'].isNotEmpty
              ? ClipOval(
                  child: Image.network(
                    volunteer['fotoPerfil'],
                    width: 40,
                    height: 40,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Icon(
                        Icons.person,
                        color: isPresent ? Colors.white : Colors.grey[600],
                      );
                    },
                  ),
                )
              : Icon(
                  Icons.person,
                  color: isPresent ? Colors.white : Colors.grey[600],
                ),
        ),
        title: Text(
          volunteer['nombre'],
          style: TextStyle(
            fontWeight: FontWeight.w500,
            color: isPresent ? Colors.green.shade700 : Colors.black87,
          ),
        ),
        subtitle: Text(volunteer['codigo']),
        trailing: Switch(
          value: isPresent,
          onChanged: (value) {
            setState(() {
              _attendanceMap[userId] = value;
            });
          },
          activeColor: Colors.green,
        ),
        onTap: () {
          setState(() {
            _attendanceMap[userId] = !isPresent;
          });
        },
      ),
    );
  }
}
