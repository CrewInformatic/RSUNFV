import 'package:cloud_firestore/cloud_firestore.dart';

// Para obtener total de eventos del usuario
Future<int> getTotalEventos(String userId) async {
  final participaciones = await FirebaseFirestore.instance
      .collection('participaciones')
      .where('idUsuario', isEqualTo: userId)
      .get();
  return participaciones.docs.length;
}

// Para obtener eventos completados
Future<int> getEventosCompletados(String userId) async {
  final completados = await FirebaseFirestore.instance
      .collection('participaciones')
      .where('idUsuario', isEqualTo: userId)
      .where('estado', isEqualTo: 'completado')
      .get();
  return completados.docs.length;
}

// Para obtener horas totales
Future<double> getHorasTotales(String userId) async {
  final participaciones = await FirebaseFirestore.instance
      .collection('participaciones')
      .where('idUsuario', isEqualTo: userId)
      .where('estado', isEqualTo: 'completado')
      .get();
      
  return participaciones.docs.fold<double>(
    0, 
    (total, doc) => total + (doc.data()['horasCompletadas'] ?? 0)
  );
}

// Para obtener medallas del usuario
Future<List<Map<String, dynamic>>> getMedallasUsuario(String userId) async {
  final medallasUsuario = await FirebaseFirestore.instance
      .collection('usuario_medallas')
      .where('idUsuario', isEqualTo: userId)
      .get();
      
  return Future.wait(medallasUsuario.docs.map((doc) async {
    final medalla = await FirebaseFirestore.instance
        .collection('medallas')
        .doc(doc.data()['idMedalla'])
        .get();
    return {...medalla.data()!, ...doc.data()};
  }));
}