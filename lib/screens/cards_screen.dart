import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:logger/logger.dart';
import '../models/usuario.dart';
import '../models/evento.dart';
import '../models/registro_evento.dart';
import '../models/asistencia_voluntario.dart';
import '../utils/registration_validator.dart';
import '../services/firebase_auth_services.dart';

class EventoDetailScreen extends StatefulWidget {
  final String eventoId;

  const EventoDetailScreen({
    super.key,
    required this.eventoId,
  });

  @override
  State<EventoDetailScreen> createState() => _EventoDetailScreenState();
}

class _EventoDetailScreenState extends State<EventoDetailScreen>
    with TickerProviderStateMixin {
  final Logger _logger = Logger();
  TabController? _tabController;
  
  Evento? evento;
  List<Usuario> participantes = [];
  bool isLoading = true;
  bool isRegistering = false;
  String? error;
  
  // Variables para administración
  Usuario? currentUser;
  Map<String, AsistenciaVoluntario> asistencias = {};
  bool isLoadingAsistencias = false;
  bool _asistenciasLoaded = false; // Flag para evitar cargas múltiples

  @override
  void initState() {
    super.initState();
    _initializeTabController();
    _loadEventoData();
    _loadCurrentUser();
  }

  void _initializeTabController() {
    _tabController?.dispose();
    _tabController = TabController(length: 2, vsync: this);
  }

  void _updateTabController() {
    if (!mounted) return;
    
    final eventStatus = _getEventStatus();
    final shouldHaveImpactTab = evento != null && eventStatus == 'finalizado';
    int expectedLength = 2;
    
    if (shouldHaveImpactTab) expectedLength++;
    
    if (_tabController?.length != expectedLength) {
      final currentIndex = _tabController?.index ?? 0;
      _tabController?.dispose();
      _tabController = TabController(
        length: expectedLength, 
        vsync: this,
        initialIndex: currentIndex < expectedLength ? currentIndex : 0,
      );
      
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {});
        }
      });
    }
  }

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }

  Future<void> _loadEventoData() async {
    try {
      setState(() {
        isLoading = true;
        error = null;
      });

      final eventoDoc = await FirebaseFirestore.instance
          .collection('eventos')
          .doc(widget.eventoId)
          .get();

      if (!eventoDoc.exists) {
        throw Exception('Evento no encontrado');
      }

      final eventoData = Evento.fromFirestore(eventoDoc);
      

      List<Usuario> participantesList = [];
      
      if (eventoData.voluntariosInscritos.isNotEmpty) {

        const chunkSize = 10;
        for (int i = 0; i < eventoData.voluntariosInscritos.length; i += chunkSize) {
          final chunk = eventoData.voluntariosInscritos
              .skip(i)
              .take(chunkSize)
              .toList();
          
          final participantesQuery = await FirebaseFirestore.instance
              .collection('usuarios')
              .where(FieldPath.documentId, whereIn: chunk)
              .get();
          
          participantesList.addAll(
            participantesQuery.docs.map((doc) => Usuario.fromFirestore(doc.data(), doc.id)),
          );
        }
      }

      setState(() {
        evento = eventoData;
        participantes = participantesList;
        isLoading = false;
      });
      
      _updateTabController();
    } catch (e) {
      setState(() {
        error = e.toString();
        isLoading = false;
      });
    }
  }

  Future<void> _loadCurrentUser() async {
    try {
      final authService = AuthService();
      final userData = await authService.getUserData();
      if (userData != null && mounted) {
        setState(() {
          currentUser = Usuario.fromMap(userData.data() as Map<String, dynamic>);
        });
      }
    } catch (e) {
      _logger.e('Error cargando usuario actual: $e');
    }
  }

  Future<void> _loadAsistenciasSafe() async {
    if (isLoadingAsistencias || _asistenciasLoaded) return;
    
    setState(() {
      isLoadingAsistencias = true;
    });

    try {
      final asistenciasQuery = await FirebaseFirestore.instance
          .collection('asistencias')
          .where('idEvento', isEqualTo: widget.eventoId)
          .get();

      final asistenciasMap = <String, AsistenciaVoluntario>{};
      for (final doc in asistenciasQuery.docs) {
        final asistencia = AsistenciaVoluntario.fromFirestore(doc.data());
        asistenciasMap[asistencia.idUsuario] = asistencia;
      }

      if (mounted) {
        setState(() {
          asistencias = asistenciasMap;
        });
      }
    } catch (e) {
      _logger.e('Error cargando asistencias: $e');
    } finally {
      if (mounted) {
        setState(() {
          isLoadingAsistencias = false;
        });
      }
    }
  }

  Future<void> _marcarAsistencia(String userId, bool asistio) async {
    if (currentUser?.isAdmin != true) return;

    try {
      final asistencia = AsistenciaVoluntario(
        idEvento: widget.eventoId,
        idUsuario: userId,
        asistio: asistio,
        fechaMarcado: DateTime.now(),
        marcadoPor: currentUser!.idUsuario,
      );

      await FirebaseFirestore.instance
          .collection('asistencias')
          .doc('${widget.eventoId}_$userId')
          .set(asistencia.toFirestore());

      setState(() {
        asistencias[userId] = asistencia;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(asistio ? 'Asistencia marcada' : 'Asistencia removida'),
            backgroundColor: asistio ? Colors.green : Colors.orange,
          ),
        );
      }
    } catch (e) {
      _logger.e('Error marcando asistencia: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al marcar asistencia'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _guardarImpacto(int personasAyudadas, int plantasPlantadas, double basuraRecolectadaKg, Map<String, dynamic> metricasPersonalizadas) async {
    if (currentUser?.isAdmin != true) return;

    try {
      // Actualizar las métricas directamente en el documento del evento
      await FirebaseFirestore.instance
          .collection('eventos')
          .doc(widget.eventoId)
          .update({
            'personasAyudadas': personasAyudadas,
            'plantasPlantadas': plantasPlantadas,
            'basuraRecolectadaKg': basuraRecolectadaKg,
            'metricasPersonalizadas': metricasPersonalizadas,
          });

      // Actualizar el evento local
      setState(() {
        evento = evento?.copyWith(
          personasAyudadas: personasAyudadas,
          plantasPlantadas: plantasPlantadas,
          basuraRecolectadaKg: basuraRecolectadaKg,
          metricasPersonalizadas: metricasPersonalizadas,
        );
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Métricas de impacto guardadas exitosamente'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      _logger.e('Error guardando impacto: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al guardar métricas de impacto'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  BoxShadow get _cardShadow => BoxShadow(
    color: Colors.grey.withAlpha(26),
    spreadRadius: 1,
    blurRadius: 10,
    offset: const Offset(0, 2),
  );

  Future<void> _checkAndRegister() async {
    if (isRegistering) {
      return;
    }
    
    setState(() {
      isRegistering = true;
    });
    
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    
    try {
      final result = await RegistrationValidator.attemptRegistration(widget.eventoId);
      
      if (!mounted) return;
      
      if (result.isSuccess) {
        scaffoldMessenger.showSnackBar(
          const SnackBar(
            content: Text('¡Registro exitoso! Bienvenido al evento'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
        await _loadEventoData();
      } else if (result.isAlreadyRegistered) {
        scaffoldMessenger.showSnackBar(
          const SnackBar(
            content: Text('Ya estás registrado en este evento'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 3),
          ),
        );
      } else {
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text(result.message),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      
      _logger.e('Error inesperado en registro: $e');
      
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: const Text('Error inesperado. Por favor, inténtalo de nuevo.'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
          action: SnackBarAction(
            label: 'Reintentar',
            textColor: Colors.white,
            onPressed: () => _checkAndRegister(),
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          isRegistering = false;
        });
      }
    }
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      final months = ['Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun', 
                     'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'];
      return '${date.day} ${months[date.month - 1]} ${date.year}';
    } catch (e) {
      return dateString;
    }
  }

  String _formatTime12Hour(String timeString) {
    try {
      final parts = timeString.split(':');
      if (parts.length != 2) return timeString;
      
      int hour = int.parse(parts[0]);
      int minute = int.parse(parts[1]);
      
      String period = hour >= 12 ? 'PM' : 'AM';
      
      if (hour == 0) {
        hour = 12;
      } else if (hour > 12) {
        hour = hour - 12;
      }
      
      String minuteStr = minute.toString().padLeft(2, '0');
      return '$hour:$minuteStr $period';
    } catch (e) {
      return timeString;
    }
  }

  String _getEventStatus() {
    if (evento == null) return 'desconocido';
    
    try {
      final now = DateTime.now();
      
      final eventStartDate = DateTime.parse(evento!.fechaInicio);
      
      final startTimeParts = evento!.horaInicio.split(':');
      final eventStartDateTime = DateTime(
        eventStartDate.year,
        eventStartDate.month,
        eventStartDate.day,
        startTimeParts.length >= 2 ? int.parse(startTimeParts[0]) : 0,
        startTimeParts.length >= 2 ? int.parse(startTimeParts[1]) : 0,
      );
      
      final eventEndDateTime = _parseEventEndDateTime();
      
      final dbStatus = evento!.estado.toLowerCase();
      if (dbStatus == 'cancelado') {
        return 'cancelado';
      }
      if (dbStatus == 'finalizado') {
        return 'finalizado';
      }
      
      if (now.isBefore(eventStartDateTime)) {
        if (dbStatus == 'activo') {
          return 'proximo';
        } else {
          return 'inactivo';
        }
      } else if (now.isAfter(eventEndDateTime)) {
        return 'finalizado';
      } else {
        return 'en_curso';
      }
    } catch (e) {
      final dbStatus = evento!.estado.toLowerCase();
      return dbStatus == 'activo' ? 'proximo' : dbStatus;
    }
  }

  DateTime _parseEventEndDateTime() {
    try {
      final eventDate = DateTime.parse(evento!.fechaInicio);
      final endTimeParts = evento!.horaFin.split(':');
      
      if (endTimeParts.length >= 2) {
        final endHour = int.parse(endTimeParts[0]);
        final endMinute = int.parse(endTimeParts[1]);
        
        return DateTime(
          eventDate.year,
          eventDate.month,
          eventDate.day,
          endHour,
          endMinute,
        );
      }
      
      return DateTime(eventDate.year, eventDate.month, eventDate.day, 23, 59);
    } catch (e) {
      final eventDate = DateTime.parse(evento!.fechaInicio);
      return eventDate.add(Duration(days: 1));
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'proximo':
        return Colors.blue;
      case 'en_curso':
        return Colors.orange;
      case 'finalizado':
        return Colors.green;
      case 'inactivo':
        return Colors.grey;
      case 'cancelado':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'proximo':
        return 'DISPONIBLE';
      case 'en_curso':
        return 'EN CURSO';
      case 'finalizado':
        return 'FINALIZADO';
      case 'inactivo':
        return 'NO DISPONIBLE';
      case 'cancelado':
        return 'CANCELADO';
      default:
        return 'DESCONOCIDO';
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'proximo':
        return Icons.event_available;
      case 'en_curso':
        return Icons.play_circle;
      case 'finalizado':
        return Icons.check_circle;
      case 'inactivo':
        return Icons.event_busy;
      case 'cancelado':
        return Icons.cancel;
      default:
        return Icons.help;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.favorite_border, color: Colors.black),
            onPressed: () {
            },
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error, size: 48, color: Colors.red),
                      const SizedBox(height: 16),
                      Text('Error: $error'),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadEventoData,
                        child: const Text('Reintentar'),
                      ),
                    ],
                  ),
                )
              : evento == null || _tabController == null
                  ? const Center(child: Text('Cargando evento...'))
                  : _buildEventContent(),
    );
  }

  Widget _buildEventContent() {
    return Column(
      children: [
        Container(
          margin: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [_cardShadow],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Column(
              children: [
                Container(
                  height: 200,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.teal, Colors.blue],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Stack(
                    children: [
                      if (evento!.foto.isNotEmpty)
                        SizedBox(
                          width: double.infinity,
                          height: double.infinity,
                          child: Image.network(
                            evento!.foto,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(); 
                            },
                          ),
                        ),
                      Container(
                        width: double.infinity,
                        height: double.infinity,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.black.withAlpha(77),
                              Colors.transparent,
                            ],
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                          ),
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: _getStatusColor(_getEventStatus()),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    _getStatusIcon(_getEventStatus()),
                                    color: Colors.white,
                                    size: 14,
                                  ),
                                  SizedBox(width: 4),
                                  Text(
                                    _getStatusText(_getEventStatus()),
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              evento!.titulo.toUpperCase(),
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Spacer(),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.calendar_today, color: Colors.white, size: 14),
                                    SizedBox(width: 4),
                                    Text(
                                      '${_formatDate(evento!.fechaInicio)}',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 4),
                                Row(
                                  children: [
                                    Icon(Icons.access_time, color: Colors.white, size: 14),
                                    SizedBox(width: 4),
                                    Text(
                                      '${_formatTime12Hour(evento!.horaInicio)} - ${_formatTime12Hour(evento!.horaFin)}',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Positioned(
                        right: 20,
                        top: 20,
                        child: Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            color: Colors.white.withAlpha(51),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.groups,
                            size: 50,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  color: Colors.white,
                  child: TabBar(
                    controller: _tabController!,
                    labelColor: Colors.black,
                    unselectedLabelColor: Colors.grey,
                    indicatorColor: Colors.teal,
                    tabs: _buildTabs(),
                  ),
                ),
              ],
            ),
          ),
        ),
        Expanded(
          child: Container(
            margin: EdgeInsets.symmetric(horizontal: 16),
            child: TabBarView(
              controller: _tabController!,
              children: _buildTabViews(),
            ),
          ),
        ),
      ],
    );
  }

  List<Tab> _buildTabs() {
    List<Tab> tabs = [
      Tab(text: 'EVENTO'),
      Tab(text: 'PARTICIPANTES'),
    ];

    final eventStatus = _getEventStatus();

    if (evento != null && eventStatus == 'finalizado') {
      tabs.add(Tab(text: 'IMPACTO'));
    }

    return tabs;
  }

  List<Widget> _buildTabViews() {
    List<Widget> views = [
      _buildEventoTab(),
      _buildParticipantesTab(),
    ];

    final eventStatus = _getEventStatus();

    if (evento != null && eventStatus == 'finalizado') {
      views.add(_buildImpactoTab());
    }

    return views;
  }

  Widget _buildImpactoTab() {
    final eventStatus = _getEventStatus();
    if (evento == null || eventStatus != 'finalizado') {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              eventStatus == 'proximo' ? Icons.schedule : Icons.play_circle,
              size: 64,
              color: Colors.grey,
            ),
            SizedBox(height: 16),
            Text(
              eventStatus == 'proximo' 
                ? 'El evento aún no ha comenzado'
                : eventStatus == 'en_curso'
                  ? 'El evento está en curso. El impacto se mostrará cuando termine.'
                  : 'El evento debe estar finalizado para ver el impacto',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey, fontSize: 16),
            ),
          ],
        ),
      );
    }

    // Las métricas ahora están directamente en el evento, no necesitamos cargar nada adicional

    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withAlpha(26),
            spreadRadius: 1,
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.analytics, color: Colors.green.shade700),
                    SizedBox(width: 8),
                    Text(
                      'Impacto del Evento',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.green.shade700,
                      ),
                    ),
                  ],
                ),
                if (currentUser?.isAdmin == true)
                  ElevatedButton.icon(
                    onPressed: _showImpactoDialog,
                    icon: Icon(Icons.edit, size: 16),
                    label: Text('Editar'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange.shade600,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                  ),
              ],
            ),
            SizedBox(height: 20),

            // Verificar si el evento tiene métricas
            if (evento?.personasAyudadas == null && 
                evento?.plantasPlantadas == null && 
                evento?.basuraRecolectadaKg == null &&
                (evento?.metricasPersonalizadas?.isEmpty ?? true))
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  children: [
                    Icon(Icons.bar_chart, color: Colors.grey.shade400, size: 48),
                    SizedBox(height: 12),
                    Text(
                      currentUser?.isAdmin == true 
                          ? 'No hay métricas registradas'
                          : 'Métricas de impacto no disponibles',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      currentUser?.isAdmin == true 
                          ? 'Haz clic en "Editar" para registrar las métricas de impacto de este evento.'
                          : 'Las métricas de impacto serán publicadas por los administradores.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              )
            else
              Column(
                children: [
                  // Métricas principales
                  Row(
                    children: [
                      Expanded(
                        child: _buildMetricCard(
                          icon: Icons.people,
                          title: 'Personas Ayudadas',
                          value: '${evento!.personasAyudadas ?? 0}',
                          color: Colors.blue,
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: _buildMetricCard(
                          icon: Icons.eco,
                          title: 'Plantas Plantadas',
                          value: '${evento!.plantasPlantadas ?? 0}',
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildMetricCard(
                          icon: Icons.delete_sweep,
                          title: 'Basura Recolectada',
                          value: '${(evento!.basuraRecolectadaKg ?? 0.0).toStringAsFixed(1)} kg',
                          color: Colors.orange,
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: _buildMetricCard(
                          icon: Icons.group,
                          title: 'Voluntarios',
                          value: '${evento!.voluntariosInscritos.length}',
                          color: Colors.purple,
                        ),
                      ),
                    ],
                  ),
                  
                  // Métricas personalizadas
                  if (evento!.metricasPersonalizadas?.isNotEmpty ?? false) ...[
                    SizedBox(height: 20),
                    Text(
                      'Métricas Adicionales',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    SizedBox(height: 12),
                    ...evento!.metricasPersonalizadas!.entries.map((entry) =>
                      Container(
                        margin: EdgeInsets.only(bottom: 8),
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              entry.key,
                              style: TextStyle(fontWeight: FontWeight.w500),
                            ),
                            Text(
                              entry.value.toString(),
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.blue.shade700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                  
                  SizedBox(height: 20),
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.green.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.green.shade700, size: 20),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Métricas registradas para este evento',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.green.shade700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withAlpha(25),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withAlpha(76)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[700],
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _showImpactoDialog() {
    if (currentUser?.isAdmin != true) return;

    final personasController = TextEditingController(
      text: evento?.personasAyudadas?.toString() ?? '0'
    );
    final plantasController = TextEditingController(
      text: evento?.plantasPlantadas?.toString() ?? '0'
    );
    final basuraController = TextEditingController(
      text: evento?.basuraRecolectadaKg?.toString() ?? '0.0'
    );
    
    Map<String, dynamic> metricasPersonalizadas = Map.from(evento?.metricasPersonalizadas ?? {});

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('Métricas de Impacto'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: personasController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Personas ayudadas',
                    prefixIcon: Icon(Icons.people, color: Colors.blue),
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: 12),
                TextFormField(
                  controller: plantasController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Plantas plantadas',
                    prefixIcon: Icon(Icons.eco, color: Colors.green),
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: 12),
                TextFormField(
                  controller: basuraController,
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: 'Basura recolectada (kg)',
                    prefixIcon: Icon(Icons.delete_sweep, color: Colors.orange),
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: 16),
                Text(
                  'Métricas Personalizadas',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                ...metricasPersonalizadas.entries.map((entry) =>
                  Card(
                    child: ListTile(
                      title: Text(entry.key),
                      subtitle: Text(entry.value.toString()),
                      trailing: IconButton(
                        icon: Icon(Icons.delete, color: Colors.red),
                        onPressed: () {
                          setDialogState(() {
                            metricasPersonalizadas.remove(entry.key);
                          });
                        },
                      ),
                    ),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () => _showAddMetricDialog(setDialogState, metricasPersonalizadas),
                  icon: Icon(Icons.add),
                  label: Text('Agregar Métrica'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                final personasAyudadas = int.tryParse(personasController.text) ?? 0;
                final plantasPlantadas = int.tryParse(plantasController.text) ?? 0;
                final basuraRecolectadaKg = double.tryParse(basuraController.text) ?? 0.0;
                
                _guardarImpacto(personasAyudadas, plantasPlantadas, basuraRecolectadaKg, metricasPersonalizadas);
                Navigator.pop(context);
              },
              child: Text('Guardar'),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddMetricDialog(StateSetter setDialogState, Map<String, dynamic> metricas) {
    final nombreController = TextEditingController();
    final valorController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Agregar Métrica'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: nombreController,
              decoration: InputDecoration(
                labelText: 'Nombre de la métrica',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 12),
            TextFormField(
              controller: valorController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Valor',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              if (nombreController.text.isNotEmpty && valorController.text.isNotEmpty) {
                setDialogState(() {
                  metricas[nombreController.text] = valorController.text;
                });
                Navigator.pop(context);
              }
            },
            child: Text('Agregar'),
          ),
        ],
      ),
    );
  }

  Widget _buildEventoTab() {
    final eventStatus = _getEventStatus();
    final statusColor = _getStatusColor(eventStatus);
    
    final eventoInfo = {
      'Estado': _getStatusText(eventStatus),
      'Fecha': _formatDate(evento!.fechaInicio),
      'Hora Inicio': _formatTime12Hour(evento!.horaInicio),
      'Hora Fin': _formatTime12Hour(evento!.horaFin),
      'Duración': '${evento!.getDuracionHoras().toStringAsFixed(1)} horas',
      'Ubicación': evento!.ubicacion,
      'Requisitos': evento!.requisitos,
      'Capacidad Máxima': '${evento!.cantidadVoluntariosMax} voluntarios',
      'Inscritos': '${evento!.voluntariosInscritos.length} voluntarios',
      'Disponibles': '${evento!.cantidadVoluntariosMax - evento!.voluntariosInscritos.length} cupos',
      'Descripción': evento!.descripcion,
    };

    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withAlpha(26),
            spreadRadius: 1,
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [statusColor.withAlpha(26), statusColor.withAlpha(13)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: statusColor.withAlpha(77)),
            ),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: statusColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    _getStatusIcon(eventStatus),
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Estado del Evento',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        _getStatusText(eventStatus),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: statusColor,
                        ),
                      ),
                    ],
                  ),
                ),
                if (eventStatus == 'en_curso')
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.orange,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'LIVE',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          SizedBox(height: 16),
          
          Expanded(
            child: ListView(
              children: eventoInfo.entries.map((entry) {
                Color? textColor;
                IconData? icon;
                
                switch (entry.key) {
                  case 'Estado':
                    textColor = statusColor;
                    icon = _getStatusIcon(eventStatus);
                    break;
                  case 'Fecha':
                    icon = Icons.calendar_today;
                    break;
                  case 'Hora Inicio':
                  case 'Hora Fin':
                  case 'Duración':
                    icon = Icons.access_time;
                    break;
                  case 'Ubicación':
                    icon = Icons.location_on;
                    break;
                  case 'Capacidad Máxima':
                  case 'Inscritos':
                    icon = Icons.people;
                    break;
                  case 'Disponibles':
                    icon = Icons.person_add;
                    textColor = entry.value.contains('0 cupos') ? Colors.red : Colors.green;
                    break;
                  case 'Requisitos':
                    icon = Icons.assignment;
                    break;
                  case 'Descripción':
                    icon = Icons.description;
                    break;
                }

                return Padding(
                  padding: EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (icon != null) ...[
                        Icon(
                          icon,
                          size: 16,
                          color: textColor ?? Colors.grey[600],
                        ),
                        SizedBox(width: 8),
                      ],
                      SizedBox(
                        width: 90,
                        child: Text(
                          '${entry.key}:',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[700],
                            fontSize: 13,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          entry.value,
                          style: TextStyle(
                            color: textColor ?? Colors.black87,
                            fontSize: 13,
                            fontWeight: entry.key == 'Estado' ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
          
          SizedBox(height: 16),
          _buildActionButton(),
        ],
      ),
    );
  }

  Widget _buildActionButton() {
    final eventStatus = _getEventStatus();
    
    if (eventStatus == 'finalizado') {
      return Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.green.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.green.shade200),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle, color: Colors.green.shade700),
            SizedBox(width: 8),
            Text(
              'Evento Finalizado',
              style: TextStyle(
                color: Colors.green.shade700,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      );
    }
    
    if (eventStatus == 'cancelado') {
      return Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.red.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.red.shade200),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.cancel, color: Colors.red.shade700),
            SizedBox(width: 8),
            Text(
              'Evento Cancelado',
              style: TextStyle(
                color: Colors.red.shade700,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      );
    }
    
    if (eventStatus == 'inactivo') {
      return Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event_busy, color: Colors.grey.shade600),
            SizedBox(width: 8),
            Text(
              'Inscripciones Cerradas',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      );
    }

    final currentUser = FirebaseAuth.instance.currentUser;
    final isUserRegistered = currentUser != null && 
        evento!.voluntariosInscritos.contains(currentUser.uid);
    
    if (isUserRegistered) {
      return Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.blue.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.blue.shade200),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle_outline, color: Colors.blue.shade700),
            SizedBox(width: 8),
            Text(
              eventStatus == 'en_curso' ? 'Ya estás participando' : 'Ya estás inscrito',
              style: TextStyle(
                color: Colors.blue.shade700,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      );
    }

    if (evento!.voluntariosInscritos.length >= evento!.cantidadVoluntariosMax) {
      return Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.orange.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.orange.shade200),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people, color: Colors.orange.shade700),
            SizedBox(width: 8),
            Text(
              'Evento Completo',
              style: TextStyle(
                color: Colors.orange.shade700,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      );
    }

    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: isRegistering ? null : () {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: Text('Inscripción'),
              content: Text(eventStatus == 'en_curso' 
                  ? '¿Deseas unirte a este evento que está en curso?'
                  : '¿Deseas inscribirte a este evento?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: isRegistering ? null : () {
                    Navigator.pop(context);
                    _checkAndRegister();
                  },
                  child: Text(eventStatus == 'en_curso' ? 'Unirse' : 'Inscribirse'),
                ),
              ],
            ),
          );
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: isRegistering ? Colors.grey : 
                         eventStatus == 'en_curso' ? Colors.orange.shade600 : Colors.brown[400],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25),
          ),
        ),
        child: isRegistering 
          ? Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
                SizedBox(width: 8),
                Text(
                  'REGISTRANDO...',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            )
          : Text(
              eventStatus == 'en_curso' ? 'UNIRSE AHORA' : 'INSCRIBIRSE',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
      ),
    );
  }

  Widget _buildParticipantesTab() {
    // Cargar asistencias si es admin y el evento está finalizado - solo una vez
    if (currentUser?.isAdmin == true && 
        _getEventStatus() == 'finalizado' && 
        !_asistenciasLoaded && 
        !isLoadingAsistencias) {
      _asistenciasLoaded = true;
      // No llamar setState aquí, usar Future.microtask para evitar el bucle
      Future.microtask(() => _loadAsistenciasSafe());
    }

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('registros_eventos')
          .where('idEvento', isEqualTo: widget.eventoId)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error al cargar registros'));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        final registros = snapshot.data?.docs ?? [];
        final isEventFinished = _getEventStatus() == 'finalizado';
        final isAdmin = currentUser?.isAdmin == true;

        return Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withAlpha(26),
                spreadRadius: 1,
                blurRadius: 10,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Participantes (${registros.length})',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.brown[400],
                    ),
                  ),
                  if (isAdmin && isEventFinished) 
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Administrador',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.orange.shade700,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
              
              if (isAdmin && isEventFinished) ...[
                SizedBox(height: 12),
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.blue.shade700, size: 20),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Marca la asistencia de los voluntarios que participaron en el evento',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.blue.shade700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              
              SizedBox(height: 16),
              Expanded(
                child: registros.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.group_off, size: 48, color: Colors.grey),
                            SizedBox(height: 16),
                            Text(
                              'No hay participantes inscritos',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: registros.length,
                        itemBuilder: (context, index) {
                          final data = registros[index].data() as Map<String, dynamic>;
                          final registro = RegistroEvento(
                            idRegistro: registros[index].id,
                            idEvento: data['idEvento'] ?? '',
                            idUsuario: data['idUsuario'] ?? '',
                            fechaRegistro: data['fechaRegistro'] ?? '',
                          );
                          
                          return FutureBuilder<DocumentSnapshot>(
                            future: FirebaseFirestore.instance
                                .collection('usuarios')
                                .doc(registro.idUsuario)
                                .get(),
                            builder: (context, userSnapshot) {
                              if (!userSnapshot.hasData) {
                                return ListTile(
                                  leading: CircleAvatar(
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  ),
                                  title: Text('Cargando...'),
                                );
                              }

                              final userData = userSnapshot.data!.data() as Map<String, dynamic>;
                              final asistencia = asistencias[registro.idUsuario];
                              final asistio = asistencia?.asistio ?? false;
                              
                              return Card(
                                elevation: 0,
                                margin: EdgeInsets.only(bottom: 8),
                                child: ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: asistio 
                                        ? Colors.green.shade400 
                                        : Colors.brown[400],
                                    child: asistio 
                                        ? Icon(Icons.check, color: Colors.white, size: 20)
                                        : Text(
                                            (userData['nombreUsuario'] as String).isNotEmpty 
                                                ? (userData['nombreUsuario'] as String)[0].toUpperCase()
                                                : '?',
                                            style: TextStyle(color: Colors.white),
                                          ),
                                  ),
                                  title: Text(userData['nombreUsuario'] ?? 'Sin nombre'),
                                  subtitle: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(userData['correo'] ?? 'Sin correo'),
                                      if (asistencia?.fechaMarcado != null)
                                        Text(
                                          'Marcado: ${_formatDateTime(asistencia!.fechaMarcado!)}',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                    ],
                                  ),
                                  trailing: isAdmin && isEventFinished
                                      ? Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            IconButton(
                                              onPressed: () => _marcarAsistencia(registro.idUsuario, !asistio),
                                              icon: Icon(
                                                asistio ? Icons.person_remove : Icons.person_add,
                                                color: asistio ? Colors.red : Colors.green,
                                              ),
                                              tooltip: asistio ? 'Marcar como ausente' : 'Marcar como presente',
                                            ),
                                          ],
                                        )
                                      : Text(userData['codigoUsuario'] ?? 'Sin código'),
                                ),
                              );
                            },
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  Future<void> registrarUsuario(String idUsuario) async {
    if (evento == null) return;

    try {
      if (evento!.voluntariosInscritos.contains(idUsuario)) {
        throw Exception('El usuario ya está registrado en este evento');
      }

      if (evento!.voluntariosInscritos.length >= evento!.cantidadVoluntariosMax) {
        throw Exception('El evento ha alcanzado el máximo de participantes');
      }

      final eventoRef = FirebaseFirestore.instance
          .collection('eventos')
          .doc(widget.eventoId);

      final registroEvento = RegistroEvento(
        idRegistro: FirebaseFirestore.instance.collection('registros_eventos').doc().id,
        idEvento: widget.eventoId,
        idUsuario: idUsuario,
        fechaRegistro: DateTime.now().toIso8601String(),
      );

      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final eventoSnapshot = await transaction.get(eventoRef);
        
        if (!eventoSnapshot.exists) {
          throw Exception('El evento no existe');
        }

        transaction.update(eventoRef, {
          'voluntariosInscritos': FieldValue.arrayUnion([idUsuario])
        });

        transaction.set(
          FirebaseFirestore.instance
              .collection('registros_eventos')
              .doc(registroEvento.idRegistro),
          registroEvento.toMap()
        );
      });

      setState(() {
        evento = evento!.copyWith(
          voluntariosInscritos: [...evento!.voluntariosInscritos, idUsuario],
        );
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('¡Registro exitoso!'),
          backgroundColor: Colors.green,
        ),
      );

    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
      _logger.e('Error al registrar usuario: $e');
    }
  }
}

class EventFunctions {
  static final Logger _logger = Logger();
  
  static Future<bool> registrarUsuario(String eventoId) async {
    try {
      final userRef = FirebaseFirestore.instance.collection('usuarios').doc(FirebaseAuth.instance.currentUser?.uid);
      final eventoRef = FirebaseFirestore.instance.collection('eventos').doc(eventoId);

      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final eventoSnapshot = await transaction.get(eventoRef);
        if (!eventoSnapshot.exists) {
          throw Exception('El evento no existe');
        }

        transaction.update(eventoRef, {
          'voluntariosInscritos': FieldValue.arrayUnion([userRef.id])
        });

        final registroEvento = {
          'idEvento': eventoId,
          'idUsuario': userRef.id,
          'fechaRegistro': DateTime.now().toIso8601String(),
        };

        transaction.set(
          FirebaseFirestore.instance.collection('registros_eventos').doc(),
          registroEvento
        );
      });

      return true;
    } catch (e) {
      _logger.e('Error al registrar usuario: $e');
      return false;
    }
  }
}