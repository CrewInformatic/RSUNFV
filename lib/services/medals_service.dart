import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/medalla.dart';

class MedalsService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  static Future<List<Medalla>> checkAndAwardQuizMedals({
    required int currentScore,
    required int totalQuestions,
    required int totalQuizzesCompleted,
    required int totalGamePoints,
    required List<String> currentMedalsIDs,
  }) async {
    final List<Medalla> newMedals = [];
    final allMedals = Medalla.getMedallasBase();
    
    if (totalQuizzesCompleted >= 1 && !currentMedalsIDs.contains('quiz_primer_juego')) {
      final medal = allMedals.firstWhere((m) => m.id == 'quiz_primer_juego');
      newMedals.add(medal);
    }

    if (currentScore == totalQuestions && currentScore > 0 && !currentMedalsIDs.contains('quiz_puntuacion_perfecta')) {
      final medal = allMedals.firstWhere((m) => m.id == 'quiz_puntuacion_perfecta');
      newMedals.add(medal);
    }

    if (totalQuizzesCompleted >= 5 && !currentMedalsIDs.contains('quiz_5_completados')) {
      final medal = allMedals.firstWhere((m) => m.id == 'quiz_5_completados');
      newMedals.add(medal);
    }

    if (totalQuizzesCompleted >= 10 && !currentMedalsIDs.contains('quiz_10_completados')) {
      final medal = allMedals.firstWhere((m) => m.id == 'quiz_10_completados');
      newMedals.add(medal);
    }

    if (totalGamePoints >= 100 && !currentMedalsIDs.contains('quiz_puntos_100')) {
      final medal = allMedals.firstWhere((m) => m.id == 'quiz_puntos_100');
      newMedals.add(medal);
    }

    if (totalGamePoints >= 500 && !currentMedalsIDs.contains('quiz_puntos_500')) {
      final medal = allMedals.firstWhere((m) => m.id == 'quiz_puntos_500');
      newMedals.add(medal);
    }

    if (newMedals.isNotEmpty) {
      await _awardMedalsToUser(newMedals);
    }

    return newMedals;
  }

  static Future<void> _awardMedalsToUser(List<Medalla> medals) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;

    try {
      final userRef = _firestore.collection('usuarios').doc(userId);
      final medalIds = medals.map((m) => m.id).toList();

      await userRef.update({
        'medallasIDs': FieldValue.arrayUnion(medalIds),
      });

      for (final medal in medals) {
        await _firestore.collection('user_medals').add({
          'userId': userId,
          'medalId': medal.id,
          'medalName': medal.nombre,
          'medalDescription': medal.descripcion,
          'medalIcon': medal.icono,
          'medalColor': medal.color,
          'medalCategory': medal.categoria,
          'dateEarned': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      debugPrint('Error otorgando medallas: $e');
    }
  }

  static Future<int> getTotalQuizzesCompleted() async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return 0;

    try {
      final scores = await _firestore
          .collection('quiz_scores')
          .where('userId', isEqualTo: userId)
          .get();
      
      return scores.docs.length;
    } catch (e) {
      debugPrint('Error obteniendo quizzes completados: $e');
      return 0;
    }
  }

  static Future<List<Medalla>> getUserMedals() async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return [];

    try {
      final userDoc = await _firestore.collection('usuarios').doc(userId).get();
      if (!userDoc.exists) return [];

      final userData = userDoc.data() ?? {};
      final medalIds = List<String>.from(userData['medallasIDs'] ?? []);
      
      final allMedals = Medalla.getMedallasBase();
      final userMedals = allMedals.where((medal) => medalIds.contains(medal.id)).toList();
      
      return userMedals;
    } catch (e) {
      debugPrint('Error obteniendo medallas del usuario: $e');
      return [];
    }
  }

  static Future<Map<String, dynamic>> getUserGameStats() async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return {};

    try {
      final userDoc = await _firestore.collection('usuarios').doc(userId).get();
      final userData = userDoc.data() ?? {};

      final totalQuizzes = await getTotalQuizzesCompleted();

      final scoresQuery = await _firestore
          .collection('quiz_scores')
          .where('userId', isEqualTo: userId)
          .orderBy('score', descending: true)
          .limit(1)
          .get();

      int highestScore = 0;
      if (scoresQuery.docs.isNotEmpty) {
        highestScore = scoresQuery.docs.first.data()['score'] ?? 0;
      }

      return {
        'totalPoints': userData['puntosJuego'] ?? 0,
        'totalQuizzes': totalQuizzes,
        'highestScore': highestScore,
        'medals': List<String>.from(userData['medallasIDs'] ?? []),
      };
    } catch (e) {
      debugPrint('Error obteniendo estadísticas del usuario: $e');
      return {};
    }
  }

  static void showMedalDialog(BuildContext context, List<Medalla> medals) {
    if (medals.isEmpty) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E3A8A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.celebration,
              color: Colors.amber,
              size: 60,
            ),
            const SizedBox(height: 16),
            const Text(
              '¡Felicidades!',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              medals.length == 1 
                ? 'Has obtenido una nueva medalla:'
                : 'Has obtenido ${medals.length} nuevas medallas:',
              style: const TextStyle(
                fontSize: 16,
                color: Colors.white70,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ...medals.map((medal) => Container(
              margin: const EdgeInsets.symmetric(vertical: 8),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(int.parse(medal.color.replaceFirst('#', '0xFF'))),
                    Color(int.parse(medal.color.replaceFirst('#', '0xFF'))).withValues(alpha: 0.7),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Text(
                    medal.icono,
                    style: const TextStyle(fontSize: 40),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    medal.nombre,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    medal.descripcion,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            )),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber,
                foregroundColor: const Color(0xFF1E3A8A),
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: const Text(
                'Continuar',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Future<List<Medalla>> refreshUserMedals() async {
    return await getUserMedals();
  }
}