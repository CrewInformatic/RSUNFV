import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:logger/logger.dart';
import '../models/usuario.dart';
import '../models/evento.dart';
import '../models/registro_evento.dart';
import '../utils/registration_validator.dart';

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

  @override
  void initState() {
    super.initState();
    _initializeTabController();
    _loadEventoData();
  }

  void _initializeTabController() {
    _tabController?.dispose();
    _tabController = TabController(length: 2, vsync: this);
  }

  void _updateTabController() {
    if (!mounted) return;
    
    final eventStatus = _getEventStatus();
    final shouldHaveImpactTab = evento != null && eventStatus == 'finished';
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
    if (evento == null) return 'unknown';
    
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
      if (dbStatus == 'cancelado' || dbStatus == 'cancelled') {
        return 'cancelled';
      }
      if (dbStatus == 'finalizado' || dbStatus == 'finished') {
        return 'finished';
      }
      
      if (now.isBefore(eventStartDateTime)) {
        if (dbStatus == 'activo') {
          return 'upcoming';
        } else {
          return 'inactive';
        }
      } else if (now.isAfter(eventEndDateTime)) {
        return 'finished';
      } else {
        return 'ongoing';
      }
    } catch (e) {
      final dbStatus = evento!.estado.toLowerCase();
      return dbStatus == 'activo' ? 'upcoming' : dbStatus;
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
      case 'upcoming':
        return Colors.blue;
      case 'ongoing':
        return Colors.orange;
      case 'finished':
        return Colors.green;
      case 'inactive':
        return Colors.grey;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'upcoming':
        return 'DISPONIBLE';
      case 'ongoing':
        return 'EN CURSO';
      case 'finished':
        return 'FINALIZADO';
      case 'inactive':
        return 'NO DISPONIBLE';
      case 'cancelled':
        return 'CANCELADO';
      default:
        return 'DESCONOCIDO';
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'upcoming':
        return Icons.event_available;
      case 'ongoing':
        return Icons.play_circle;
      case 'finished':
        return Icons.check_circle;
      case 'inactive':
        return Icons.event_busy;
      case 'cancelled':
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

    if (evento != null && eventStatus == 'finished') {
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

    if (evento != null && eventStatus == 'finished') {
      views.add(_buildImpactoTab());
    }

    return views;
  }

  Widget _buildImpactoTab() {
    final eventStatus = _getEventStatus();
    if (evento == null || eventStatus != 'finished') {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              eventStatus == 'upcoming' ? Icons.schedule : Icons.play_circle,
              size: 64,
              color: Colors.grey,
            ),
            SizedBox(height: 16),
            Text(
              eventStatus == 'upcoming' 
                ? 'El evento aún no ha comenzado'
                : eventStatus == 'ongoing'
                  ? 'El evento está en curso. El impacto se mostrará cuando termine.'
                  : 'El evento debe estar finalizado para ver el impacto',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey, fontSize: 16),
            ),
          ],
        ),
      );
    }

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
            SizedBox(height: 20),

            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Column(
                children: [
                  Icon(Icons.construction, color: Colors.blue.shade700, size: 48),
                  SizedBox(height: 12),
                  Text(
                    'Funcionalidad en Desarrollo',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue.shade700,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'El informe de impacto detallado y la lista de asistencia estarán disponibles próximamente. Esta sección mostrará métricas específicas según el tipo de evento.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 20),

            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.green.shade50, Colors.blue.shade50],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Resumen del Evento',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.green.shade800,
                    ),
                  ),
                  SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildSummaryCard(
                        icon: Icons.people,
                        title: 'Inscritos',
                        value: '${evento!.voluntariosInscritos.length}',
                        color: Colors.blue,
                      ),
                      _buildSummaryCard(
                        icon: Icons.schedule,
                        title: 'Duración',
                        value: '${evento!.getDuracionHoras().toStringAsFixed(1)}h',
                        color: Colors.orange,
                      ),
                      _buildSummaryCard(
                        icon: Icons.check_circle,
                        title: 'Estado',
                        value: 'Completado',
                        color: Colors.green,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: color.withAlpha(51),
            spreadRadius: 1,
            blurRadius: 4,
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
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
                if (eventStatus == 'ongoing')
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
    
    if (eventStatus == 'finished') {
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
    
    if (eventStatus == 'cancelled') {
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
    
    if (eventStatus == 'inactive') {
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
              eventStatus == 'ongoing' ? 'Ya estás participando' : 'Ya estás inscrito',
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
              content: Text(eventStatus == 'ongoing' 
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
                  child: Text(eventStatus == 'ongoing' ? 'Unirse' : 'Inscribirse'),
                ),
              ],
            ),
          );
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: isRegistering ? Colors.grey : 
                         eventStatus == 'ongoing' ? Colors.orange.shade600 : Colors.brown[400],
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
              eventStatus == 'ongoing' ? 'UNIRSE AHORA' : 'INSCRIBIRSE',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
      ),
    );
  }

  Widget _buildParticipantesTab() {
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
              Text(
                'Participantes (${registros.length})',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.brown[400],
                ),
              ),
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
                              
                              return Card(
                                elevation: 0,
                                child: ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: Colors.brown[400],
                                    child: Text(
                                      (userData['nombreUsuario'] as String).isNotEmpty 
                                          ? (userData['nombreUsuario'] as String)[0].toUpperCase()
                                          : '?',
                                      style: TextStyle(color: Colors.white),
                                    ),
                                  ),
                                  title: Text(userData['nombreUsuario'] ?? 'Sin nombre'),
                                  subtitle: Text(userData['correo'] ?? 'Sin correo'),
                                  trailing: Text(userData['codigoUsuario'] ?? 'Sin código'),
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