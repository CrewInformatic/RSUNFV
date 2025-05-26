import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../models/evento.dart';

// Obtener todos los eventos como una lista
Future<List<Evento>> obtenerEventos() async {
  final snapshot = await FirebaseFirestore.instance
      .collection('eventos')
      .orderBy('fechaInicio', descending: true)
      .get();

  return snapshot.docs.map((doc) => Evento.fromFirestore(doc)).toList();
}

// Obtener eventos en tiempo real (stream)
Stream<List<Evento>> streamEventos() {
  return FirebaseFirestore.instance
      .collection('eventos')
      .orderBy('fechaInicio', descending: true)
      .snapshots()
      .map((snapshot) =>
          snapshot.docs.map((doc) => Evento.fromFirestore(doc)).toList());
}

class EventosPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Eventos'),
      ),
      body: StreamBuilder<List<Evento>>(
        stream: streamEventos(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return Center(child: CircularProgressIndicator());
          final eventos = snapshot.data!;
          return ListView.builder(
            itemCount: eventos.length,
            itemBuilder: (context, index) {
              final evento = eventos[index];
              return ListTile(
                title: Text(evento.titulo),
                subtitle: Text(evento.descripcion),
                // Muestra más información del evento aquí
              );
            },
          );
        },
      ),
    );
  }
}