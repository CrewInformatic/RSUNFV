import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:logger/logger.dart';
import '../models/usuario.dart';
import '../models/evento.dart';
import '../models/registro_evento.dart';
import '../functions/pedir_eventos.dart';

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
    with SingleTickerProviderStateMixin {
  final Logger _logger = Logger();
  late TabController _tabController;
  
  Evento? evento;
  List<Usuario> participantes = [];
  bool isLoading = true;
  String? error;

  // Nueva propiedad para el FAB expandible
  bool _isFabExpanded = false;
  final _fabKey = GlobalKey<State<StatefulWidget>>();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadEventoData();
  }

  @override
  void dispose() {
    _tabController.dispose();
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
    } catch (e) {
      setState(() {
        error = e.toString();
        isLoading = false;
      });
    }
  }

  // Replace all withOpacity calls with withAlpha
  BoxShadow get _cardShadow => BoxShadow(
    color: Colors.grey.withAlpha(26),
    spreadRadius: 1,
    blurRadius: 10,
    offset: const Offset(0, 2),
  );

  Future<void> _checkAndRegister() async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final isRegistered = await EventosFunctions.verificarRegistroUsuario(widget.eventoId);
    
    if (!isRegistered) {
      try {
        final success = await EventosFunctions.registrarUsuarioEnEvento(widget.eventoId);
        
        if (!mounted) return;
        
        if (success) {
          scaffoldMessenger.showSnackBar(
            const SnackBar(
              content: Text('¡Registro exitoso!'),
              backgroundColor: Colors.green,
            ),
          );
          await _loadEventoData();
        } else {
          throw Exception('No se pudo completar el registro');
        }
      } catch (e) {
        if (!mounted) return;
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } else {
      scaffoldMessenger.showSnackBar(
        const SnackBar(
          content: Text('Ya estás registrado en este evento'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return dateString;
    }
  }

  // Método para el FAB personalizado
  Widget _buildFAB() {
    return Flow(
      key: _fabKey,
      delegate: FlowMenuDelegate(
        isFabExpanded: _isFabExpanded,
        openDuration: const Duration(milliseconds: 250),
      ),
      children: [
        // FAB principal
        FloatingActionButton.extended(
          onPressed: () {
            setState(() {
              _isFabExpanded = !_isFabExpanded;
            });
          },
          backgroundColor: Colors.orange.shade700,
          icon: AnimatedRotation(
            turns: _isFabExpanded ? 0.125 : 0,
            duration: const Duration(milliseconds: 250),
            child: const Icon(Icons.add),
          ),
          label: const Text('Donar'),
        ),
        // FAB de donación monetaria
        FloatingActionButton.extended(
          heroTag: 'money',
          onPressed: () {
            Navigator.pushNamed(context, '/donaciones/monetaria');
          },
          backgroundColor: Colors.green,
          icon: const Icon(Icons.attach_money),
          label: const Text('Dinero'),
        ),
        // FAB de donación material
        FloatingActionButton.extended(
          heroTag: 'items',
          onPressed: () {
            Navigator.pushNamed(context, '/donaciones/material');
          },
          backgroundColor: Colors.blue,
          icon: const Icon(Icons.inventory),
          label: const Text('Materiales'),
        ),
      ],
    );
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
              // Implementar favoritos
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
              : evento == null
                  ? const Center(child: Text('Evento no encontrado'))
                  : Column(
                      children: [
                        // Header con imagen del evento
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
                                // Imagen del evento
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
                                      // Overlay con contenido
                                      Container(
                                        width: double.infinity,
                                        height: double.infinity,
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: [
                                              Colors.black.withAlpha(77), // Cambio de withOpacity(0.3) a withAlpha(77)
                                              Colors.transparent,
                                            ],
                                            begin: Alignment.bottomCenter,
                                            end: Alignment.topCenter,
                                          ),
                                        ),
                                      ),
                                      // Contenido de la imagen
                                      Padding(
                                        padding: EdgeInsets.all(20),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              evento!.titulo.toUpperCase(),
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            Spacer(),
                                            Row(
                                              children: [
                                                Text(
                                                  'Fecha: ${_formatDate(evento!.fechaInicio)}',
                                                  style: TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 12,
                                                  ),
                                                ),
                                                Spacer(),
                                                Container(
                                                  width: 40,
                                                  height: 40,
                                                  decoration: BoxDecoration(
                                                    color: Colors.white,
                                                    shape: BoxShape.circle,
                                                  ),
                                                  child: Icon(
                                                    Icons.event,
                                                    color: Colors.teal,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                      // Icono de grupo
                                      Positioned(
                                        right: 20,
                                        top: 20,
                                        child: Container(
                                          width: 100,
                                          height: 100,
                                          decoration: BoxDecoration(
                                            color: Colors.white.withAlpha(51), // Cambio de withOpacity(0.2) a withAlpha(51)
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
                                // Tabs
                                Container(
                                  color: Colors.white,
                                  child: TabBar(
                                    controller: _tabController,
                                    labelColor: Colors.black,
                                    unselectedLabelColor: Colors.grey,
                                    indicatorColor: Colors.teal,
                                    tabs: [
                                      Tab(text: 'EVENTO'),
                                      Tab(text: 'PARTICIPANTES'),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        // Contenido de los tabs
                        Expanded(
                          child: Container(
                            margin: EdgeInsets.symmetric(horizontal: 16),
                            child: TabBarView(
                              controller: _tabController,
                              children: [
                                _buildEventoTab(),
                                _buildParticipantesTab(),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
      // Agregado el floatingActionButton
      floatingActionButton: _buildFAB(),
    );
  }

  Widget _buildEventoTab() {
    final eventoInfo = {
      'Fecha Inicio': _formatDate(evento!.fechaInicio),
      'Fecha Creación': _formatDate(evento!.fechaCreacion),
      'Ubicación': evento!.ubicacion,
      'Requisitos': evento!.requisitos, // <-- CORREGIDO
      'Capacidad Máxima': '${evento!.cantidadVoluntariosMax} voluntarios',
      'Inscritos': '${evento!.voluntariosInscritos.length} voluntarios',
      'Descripción': evento!.descripcion,
    };

    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withAlpha(26), // Cambio de withOpacity(0.1) a withAlpha(26)
            spreadRadius: 1,
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Información del evento
          Expanded(
            child: ListView(
              children: eventoInfo.entries.map((entry) {
                return Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 100,
                        child: Text(
                          '${entry.key}:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[700],
                          ),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          entry.value,
                          style: TextStyle(
                            color: Colors.black87,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
          // Botón de acción
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: Text('Inscripción'),
                    content: Text('¿Desea inscribirse a este evento?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text('Cancelar'),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          _checkAndRegister();
                        },
                        child: Text('Inscribirse'),
                      ),
                    ],
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.brown[400],
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
              ),
              child: Text(
                'INSCRIBIRSE',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
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
                color: Colors.grey.withAlpha(26), // Cambio de withOpacity(0.1) a withAlpha(26)
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

// Clase para el delegado de Flow
class FlowMenuDelegate extends FlowDelegate {
  final bool isFabExpanded;
  final Duration openDuration;

  FlowMenuDelegate({
    required this.isFabExpanded,
    required this.openDuration,
  }) : super(repaint: ValueNotifier<bool>(isFabExpanded));

  @override
  void paintChildren(FlowPaintingContext context) {
    final size = context.size;
    final xStart = size.width - 56.0;
    final yStart = size.height - 56.0;

    final n = context.childCount;
    for (int i = 0; i < n; i++) {
      final isLastItem = i == 0;
      final setBack = (n - 1 - i) * 70.0;
      
      final childSize = context.getChildSize(i)!;
      final dx = xStart - setBack * (isFabExpanded ? 1 : 0);
      final dy = yStart;
      
      context.paintChild(
        i,
        transform: Matrix4.translationValues(
          dx - childSize.width + 56,
          dy - childSize.height + 56,
          0.0,
        ),
        opacity: isLastItem ? 1.0 : isFabExpanded ? 1.0 : 0.0,
      );
    }
  }

  @override
  bool shouldRepaint(covariant FlowDelegate oldDelegate) => true;
}