import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../functions/funciones_eventos.dart';

class EventoDetalleScreen extends StatefulWidget {
  final String eventoId;
  final String eventoNombre;
  final String eventoDescripcion;
  final String eventoFecha;
  final String eventoHora;
  final String eventoLugar;

  const EventoDetalleScreen({
    super.key,
    required this.eventoId,
    required this.eventoNombre,
    required this.eventoDescripcion,
    required this.eventoFecha,
    required this.eventoHora,
    required this.eventoLugar,
  });

  @override
  State<EventoDetalleScreen> createState() => _EventoDetalleScreenState();
}

class _EventoDetalleScreenState extends State<EventoDetalleScreen> {
  bool isRegistered = false;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _checkRegistration();
  }

  Future<void> _checkRegistration() async {
    setState(() => isLoading = true);
    final registered = await EventFunctions.isUserRegistered(widget.eventoId);
    if (mounted) {
      setState(() {
        isRegistered = registered;
        isLoading = false;
      });
    }
  }

  Widget _buildParticipantsList() {
    return StreamBuilder<QuerySnapshot>(
      stream: EventFunctions.getEventParticipantsStream(widget.eventoId),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Text('Error al cargar participantes');
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const CircularProgressIndicator();
        }

        return ListView.builder(
          shrinkWrap: true,
          itemCount: snapshot.data?.docs.length ?? 0,
          itemBuilder: (context, index) {
            final participant = snapshot.data!.docs[index].data() as Map<String, dynamic>;
            return ListTile(
              title: Text('${participant['nombreUsuario']} ${participant['apellidoUsuario']}'),
              subtitle: Text('Estado: ${participant['estado']}'),
              trailing: Text(participant['asistio'] ? 'Asistió' : 'Pendiente'),
            );
          },
        );
      },
    );
  }

  Future<bool> registerUserForEvent(String eventId, String userId) async {
    try {
      // Check if user is already registered
      final eventRef = FirebaseFirestore.instance.collection('events').doc(eventId);
      final eventDoc = await eventRef.get();
      
      if (!eventDoc.exists) {
        return false;
      }

      final List<dynamic> participants = eventDoc.data()?['participants'] ?? [];
      
      // If user is already registered, return false
      if (participants.contains(userId)) {
        return false;
      }

      // Add user to participants list
      await eventRef.update({
        'participants': FieldValue.arrayUnion([userId])
      });

      return true;
    } catch (e) {
      print('Error registering user for event: $e');
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.eventoNombre),
        backgroundColor: Colors.orange.shade700,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Detalles del evento
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.eventoNombre,
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(widget.eventoDescripcion),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Icon(Icons.calendar_today),
                      const SizedBox(width: 8),
                      Text(widget.eventoFecha),
                      const SizedBox(width: 16),
                      const Icon(Icons.access_time),
                      const SizedBox(width: 8),
                      Text(widget.eventoHora),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.location_on),
                      const SizedBox(width: 8),
                      Text(widget.eventoLugar),
                    ],
                  ),
                ],
              ),
            ),

            // Botón de registro
            if (isLoading)
              const Center(child: CircularProgressIndicator())
            else
              Center(
                child: ElevatedButton(
                  onPressed: isRegistered ? null : () async {
                    setState(() => isLoading = true);
                    try {
                      final success = await EventFunctions.registerUserForEvent(widget.eventoId);
                      if (mounted) {
                        setState(() {
                          isLoading = false;
                          isRegistered = success;
                        });
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(success 
                              ? 'Registro exitoso' 
                              : 'Ya estás registrado en este evento'),
                            backgroundColor: success ? Colors.green : Colors.orange,
                          ),
                        );
                      }
                    } catch (e) {
                      if (mounted) {
                        setState(() => isLoading = false);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Error: ${e.toString()}'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange.shade700,
                  ),
                  child: Text(isRegistered ? 'Ya estás registrado' : 'Registrarse'),
                ),
              ),

            // Lista de participantes
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                'Participantes',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            _buildParticipantsList(),
          ],
        ),
      ),
    );
  }
}