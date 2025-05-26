import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../models/evento.dart';

// Obtener todos los eventos como una lista
Future<List<Evento>> obtenerEventos() async {
  try {
    final snapshot = await FirebaseFirestore.instance
        .collection('eventos')
        .orderBy('fechaInicio', descending: true)
        .get();

    return snapshot.docs.map((doc) => Evento.fromFirestore(doc)).toList();
  } catch (e) {
    print('Error al obtener eventos: $e');
    return [];
  }
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

// Obtener eventos por estado (activos, finalizados, etc.)
Future<List<Evento>> obtenerEventosPorEstado(String idEstado) async {
  try {
    final snapshot = await FirebaseFirestore.instance
        .collection('eventos')
        .where('idEstado', isEqualTo: idEstado)
        .orderBy('fechaInicio', descending: true)
        .get();

    return snapshot.docs.map((doc) => Evento.fromFirestore(doc)).toList();
  } catch (e) {
    print('Error al obtener eventos por estado: $e');
    return [];
  }
}

// Obtener eventos por tipo
Future<List<Evento>> obtenerEventosPorTipo(String idTipo) async {
  try {
    final snapshot = await FirebaseFirestore.instance
        .collection('eventos')
        .where('idTipo', isEqualTo: idTipo)
        .orderBy('fechaInicio', descending: true)
        .get();

    return snapshot.docs.map((doc) => Evento.fromFirestore(doc)).toList();
  } catch (e) {
    print('Error al obtener eventos por tipo: $e');
    return [];
  }
}

// Obtener eventos próximos (fecha de inicio futura)
Future<List<Evento>> obtenerEventosProximos() async {
  try {
    final snapshot = await FirebaseFirestore.instance
        .collection('eventos')
        .where('fechaInicio', isGreaterThan: Timestamp.now())
        .orderBy('fechaInicio', descending: false)
        .get();

    return snapshot.docs.map((doc) => Evento.fromFirestore(doc)).toList();
  } catch (e) {
    print('Error al obtener eventos próximos: $e');
    return [];
  }
}

// Obtener eventos pasados
Future<List<Evento>> obtenerEventosPasados() async {
  try {
    final snapshot = await FirebaseFirestore.instance
        .collection('eventos')
        .where('fechaInicio', isLessThan: Timestamp.now())
        .orderBy('fechaInicio', descending: true)
        .get();

    return snapshot.docs.map((doc) => Evento.fromFirestore(doc)).toList();
  } catch (e) {
    print('Error al obtener eventos pasados: $e');
    return [];
  }
}

// Buscar eventos por título o descripción
Future<List<Evento>> buscarEventos(String termino) async {
  try {
    final snapshot = await FirebaseFirestore.instance
        .collection('eventos')
        .orderBy('fechaInicio', descending: true)
        .get();

    final eventos = snapshot.docs.map((doc) => Evento.fromFirestore(doc)).toList();
    
    return eventos.where((evento) =>
        evento.titulo.toLowerCase().contains(termino.toLowerCase()) ||
        evento.descripcion.toLowerCase().contains(termino.toLowerCase()) ||
        evento.ubicacion.toLowerCase().contains(termino.toLowerCase())
    ).toList();
  } catch (e) {
    print('Error al buscar eventos: $e');
    return [];
  }
}

// Obtener evento por ID
Future<Evento?> obtenerEventoPorId(String idEvento) async {
  try {
    final doc = await FirebaseFirestore.instance
        .collection('eventos')
        .doc(idEvento)
        .get();

    if (doc.exists) {
      return Evento.fromFirestore(doc);
    }
    return null;
  } catch (e) {
    print('Error al obtener evento por ID: $e');
    return null;
  }
}

// Stream de un evento específico
Stream<Evento?> streamEventoPorId(String idEvento) {
  return FirebaseFirestore.instance
      .collection('eventos')
      .doc(idEvento)
      .snapshots()
      .map((doc) => doc.exists ? Evento.fromFirestore(doc) : null);
}

// Obtener estadísticas de eventos
Future<Map<String, int>> obtenerEstadisticasEventos() async {
  try {
    final snapshot = await FirebaseFirestore.instance
        .collection('eventos')
        .get();

    final eventos = snapshot.docs.map((doc) => Evento.fromFirestore(doc)).toList();
    final ahora = Timestamp.now();

    return {
      'total': eventos.length,
      'proximos': eventos.where((e) => e.fechaInicio.compareTo(ahora) > 0).length,
      'pasados': eventos.where((e) => e.fechaInicio.compareTo(ahora) < 0).length,
      'totalVoluntarios': eventos.fold(0, (sum, evento) => sum + evento.cantidadVoluntarios),
    };
  } catch (e) {
    print('Error al obtener estadísticas: $e');
    return {
      'total': 0,
      'proximos': 0,
      'pasados': 0,
      'totalVoluntarios': 0,
    };
  }
}