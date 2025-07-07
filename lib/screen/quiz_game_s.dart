import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:math';
import 'dart:async';
import '../services/medals_service.dart';

class QuizGameScreen extends StatefulWidget {
  const QuizGameScreen({super.key});

  @override
  State<QuizGameScreen> createState() => _QuizGameScreenState();
}

class _QuizGameScreenState extends State<QuizGameScreen>
    with TickerProviderStateMixin {
  late AnimationController _progressController;
  late AnimationController _bounceController;
  late Animation<double> _bounceAnimation;

  int currentQuestionIndex = 0;
  int score = 0;
  int timeLeft = 30;
  bool gameStarted = false;
  bool gameEnded = false;
  bool isAnswering = false;
  
  List<QuizQuestion> questions = [];
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _progressController = AnimationController(
      duration: const Duration(seconds: 30),
      vsync: this,
    );
    
    _bounceController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    
    _bounceAnimation = Tween<double>(
      begin: 1.0,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _bounceController,
      curve: Curves.elasticOut,
    ));
    
    _loadQuestions();
  }

  @override
  void dispose() {
    _progressController.dispose();
    _bounceController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  void _loadQuestions() {
    // Bank de preguntas extenso sobre RSU y sostenibilidad
    List<QuizQuestion> questionBank = [
      // RSU - Conceptos Básicos
      QuizQuestion(
        question: "¿Qué significa RSU?",
        options: [
          "Responsabilidad Social Universitaria",
          "Red Social Universitaria", 
          "Recursos Sociales Unidos",
          "Registro Social Único"
        ],
        correctIndex: 0,
        explanation: "RSU significa Responsabilidad Social Universitaria, un compromiso con el desarrollo sostenible.",
      ),
      QuizQuestion(
        question: "¿Cuál es el objetivo principal de la RSU?",
        options: [
          "Generar ganancias para la universidad",
          "Formar profesionales íntegros y comprometidos con la sociedad",
          "Competir con otras universidades",
          "Aumentar el número de estudiantes"
        ],
        correctIndex: 1,
        explanation: "La RSU busca formar profesionales íntegros comprometidos con el desarrollo sostenible y la justicia social.",
      ),
      QuizQuestion(
        question: "¿Cuántos pilares fundamentales tiene la RSU?",
        options: ["2", "3", "4", "5"],
        correctIndex: 2,
        explanation: "La RSU se basa en 4 pilares: Campus responsable, Formación académica, Investigación social y Proyección social.",
      ),
      
      // Objetivos de Desarrollo Sostenible (ODS)
      QuizQuestion(
        question: "¿Cuántos Objetivos de Desarrollo Sostenible estableció la ONU?",
        options: ["15", "17", "20", "25"],
        correctIndex: 1,
        explanation: "La ONU estableció 17 Objetivos de Desarrollo Sostenible para ser alcanzados en 2030.",
      ),
      QuizQuestion(
        question: "¿Cuál es el ODS número 4?",
        options: [
          "Fin de la pobreza",
          "Educación de calidad",
          "Igualdad de género",
          "Trabajo decente"
        ],
        correctIndex: 1,
        explanation: "El ODS 4 es 'Educación de calidad: garantizar una educación inclusiva, equitativa y de calidad'.",
      ),
      QuizQuestion(
        question: "¿Qué ODS se enfoca en la igualdad de género?",
        options: ["ODS 3", "ODS 5", "ODS 8", "ODS 10"],
        correctIndex: 1,
        explanation: "El ODS 5 se enfoca en lograr la igualdad de género y empoderar a todas las mujeres y niñas.",
      ),
      QuizQuestion(
        question: "¿Cuál es la meta temporal de los ODS?",
        options: ["2025", "2030", "2035", "2040"],
        correctIndex: 1,
        explanation: "Los Objetivos de Desarrollo Sostenible deben ser alcanzados para el año 2030.",
      ),
      
      // Medio Ambiente y Sostenibilidad
      QuizQuestion(
        question: "¿Qué porcentaje de agua dulce está disponible en la Tierra?",
        options: ["75%", "50%", "25%", "3%"],
        correctIndex: 3,
        explanation: "Solo el 3% del agua de la Tierra es dulce y disponible para consumo humano.",
      ),
      QuizQuestion(
        question: "¿Cuál es la principal causa del cambio climático?",
        options: [
          "Erupciones volcánicas",
          "Emisiones de gases de efecto invernadero",
          "Ciclos solares",
          "Movimientos de placas tectónicas"
        ],
        correctIndex: 1,
        explanation: "Las emisiones de gases de efecto invernadero por actividades humanas son la principal causa.",
      ),
      QuizQuestion(
        question: "¿Qué significa 'huella de carbono'?",
        options: [
          "La marca que deja el carbón en el suelo",
          "La cantidad total de gases de efecto invernadero producidos",
          "El color que adquiere el aire contaminado",
          "La velocidad de consumo de carbón"
        ],
        correctIndex: 1,
        explanation: "La huella de carbono es la cantidad total de gases de efecto invernadero que producimos directa e indirectamente.",
      ),
      QuizQuestion(
        question: "¿Cuántos años tarda en descomponerse una botella de plástico?",
        options: ["50 años", "100 años", "450 años", "1000 años"],
        correctIndex: 2,
        explanation: "Una botella de plástico puede tardar hasta 450 años en descomponerse completamente.",
      ),
      QuizQuestion(
        question: "¿Qué es la energía renovable?",
        options: [
          "Energía que se puede reutilizar",
          "Energía que proviene de fuentes naturales inagotables",
          "Energía que se renueva cada año",
          "Energía que requiere renovación constante"
        ],
        correctIndex: 1,
        explanation: "La energía renovable proviene de fuentes naturales que se regeneran de forma natural y son prácticamente inagotables.",
      ),
      
      // Voluntariado y Participación Social
      QuizQuestion(
        question: "¿Cuál es una característica esencial del voluntariado?",
        options: [
          "Recibir una remuneración económica",
          "Ser una actividad obligatoria",
          "Realizarse de forma libre y gratuita",
          "Durar necesariamente varios años"
        ],
        correctIndex: 2,
        explanation: "El voluntariado se caracteriza por ser una actividad libre, gratuita y solidaria en beneficio de la comunidad.",
      ),
      QuizQuestion(
        question: "¿Qué beneficio NO es típico del voluntariado?",
        options: [
          "Desarrollo personal",
          "Ganancia económica directa",
          "Experiencia profesional",
          "Conexiones sociales"
        ],
        correctIndex: 1,
        explanation: "El voluntariado no busca ganancia económica directa, sino el desarrollo personal y el impacto social.",
      ),
      QuizQuestion(
        question: "¿Qué es la participación ciudadana?",
        options: [
          "Solo votar en elecciones",
          "Involucrarse activamente en asuntos de la comunidad",
          "Pagar impuestos puntualmente",
          "Cumplir solo con las leyes"
        ],
        correctIndex: 1,
        explanation: "La participación ciudadana implica involucrarse activamente en los asuntos públicos y comunitarios.",
      ),
      
      // Desarrollo Sostenible
      QuizQuestion(
        question: "¿Qué significa el término 'sostenibilidad'?",
        options: [
          "Usar recursos sin límites",
          "Satisfacer necesidades actuales sin comprometer las futuras generaciones",
          "Priorizar solo el crecimiento económico",
          "Ignorar el impacto ambiental"
        ],
        correctIndex: 1,
        explanation: "Sostenibilidad es satisfacer las necesidades del presente sin comprometer las futuras generaciones.",
      ),
      QuizQuestion(
        question: "¿Cuáles son las tres dimensiones del desarrollo sostenible?",
        options: [
          "Económica, política y cultural",
          "Social, ambiental y económica",
          "Tecnológica, social y política",
          "Ambiental, cultural y tecnológica"
        ],
        correctIndex: 1,
        explanation: "Las tres dimensiones del desarrollo sostenible son: social, ambiental y económica.",
      ),
      QuizQuestion(
        question: "¿Qué es la economía circular?",
        options: [
          "Una economía que solo funciona en círculos",
          "Un modelo que busca reducir, reutilizar y reciclar",
          "Una economía basada en monedas circulares",
          "Un sistema económico regional"
        ],
        correctIndex: 1,
        explanation: "La economía circular es un modelo que busca minimizar los desechos mediante la reducción, reutilización y reciclaje.",
      ),
      
      // Derechos Humanos y Justicia Social
      QuizQuestion(
        question: "¿Cuántos artículos tiene la Declaración Universal de Derechos Humanos?",
        options: ["25", "30", "35", "40"],
        correctIndex: 1,
        explanation: "La Declaración Universal de Derechos Humanos tiene 30 artículos que establecen los derechos fundamentales.",
      ),
      QuizQuestion(
        question: "¿En qué año se adoptó la Declaración Universal de Derechos Humanos?",
        options: ["1945", "1948", "1950", "1955"],
        correctIndex: 1,
        explanation: "La Declaración Universal de Derechos Humanos fue adoptada por la ONU el 10 de diciembre de 1948.",
      ),
      QuizQuestion(
        question: "¿Qué es la equidad de género?",
        options: [
          "Que hombres y mujeres sean idénticos",
          "Igualdad de oportunidades y trato justo para todos los géneros",
          "Solo oportunidades para mujeres",
          "Eliminar las diferencias biológicas"
        ],
        correctIndex: 1,
        explanation: "La equidad de género busca la igualdad de oportunidades y un trato justo para todas las personas, independientemente de su género.",
      ),
      
      // Educación y Desarrollo
      QuizQuestion(
        question: "¿Qué es la educación inclusiva?",
        options: [
          "Educación solo para personas con discapacidad",
          "Educación que incluye a todos sin discriminación",
          "Educación que incluye solo tecnología",
          "Educación con costos incluidos"
        ],
        correctIndex: 1,
        explanation: "La educación inclusiva garantiza el acceso, participación y aprendizaje de todos los estudiantes, especialmente aquellos en situación de vulnerabilidad.",
      ),
      QuizQuestion(
        question: "¿Cuál es un beneficio de la educación de calidad?",
        options: [
          "Solo mejora económica personal",
          "Reducción de la pobreza y desarrollo social",
          "Solo acceso a mejor tecnología",
          "Solo prestigio social"
        ],
        correctIndex: 1,
        explanation: "La educación de calidad contribuye a la reducción de la pobreza, el desarrollo social y el crecimiento económico sostenible.",
      ),
      
      // Salud y Bienestar
      QuizQuestion(
        question: "¿Qué es la salud mental?",
        options: [
          "Solo la ausencia de enfermedad mental",
          "Un estado de bienestar emocional, psicológico y social",
          "Solo tener buena memoria",
          "Solo controlar las emociones"
        ],
        correctIndex: 1,
        explanation: "La salud mental es un estado de bienestar en el cual la persona puede realizar sus actividades y hacer frente al estrés normal de la vida.",
      ),
      QuizQuestion(
        question: "¿Cuál es una práctica importante para el bienestar?",
        options: [
          "Trabajar sin descanso",
          "Mantener equilibrio entre trabajo, descanso y recreación",
          "Evitar toda actividad física",
          "Aislarse socialmente"
        ],
        correctIndex: 1,
        explanation: "Mantener un equilibrio entre trabajo, descanso y recreación es fundamental para el bienestar integral.",
      ),
      
      // Tecnología y Sociedad
      QuizQuestion(
        question: "¿Qué es la brecha digital?",
        options: [
          "Un error en el software",
          "La diferencia en el acceso a tecnologías de información",
          "La velocidad de internet",
          "El costo de los dispositivos"
        ],
        correctIndex: 1,
        explanation: "La brecha digital es la diferencia en el acceso, uso y conocimiento de las tecnologías de información y comunicación.",
      ),
      QuizQuestion(
        question: "¿Cómo puede la tecnología contribuir al desarrollo sostenible?",
        options: [
          "Solo aumentando el consumo",
          "Mejorando la eficiencia y reduciendo el impacto ambiental",
          "Solo creando más dispositivos",
          "Reemplazando completamente el trabajo humano"
        ],
        correctIndex: 1,
        explanation: "La tecnología puede contribuir al desarrollo sostenible mejorando la eficiencia de recursos y reduciendo el impacto ambiental.",
      ),
      
      // Ética y Responsabilidad
      QuizQuestion(
        question: "¿Qué es la ética profesional?",
        options: [
          "Solo seguir las reglas de la empresa",
          "Conjunto de principios morales que guían el comportamiento profesional",
          "Solo buscar el beneficio económico",
          "Competir sin límites"
        ],
        correctIndex: 1,
        explanation: "La ética profesional es el conjunto de principios morales que deben guiar el comportamiento en el ejercicio profesional.",
      ),
      QuizQuestion(
        question: "¿Qué implica ser un ciudadano responsable?",
        options: [
          "Solo pagar impuestos",
          "Participar activamente en el bienestar de la comunidad",
          "Solo votar cada cuatro años",
          "Solo cumplir leyes"
        ],
        correctIndex: 1,
        explanation: "Ser un ciudadano responsable implica participar activamente en el bienestar de la comunidad y contribuir al bien común.",
      ),
      
      // Innovación Social
      QuizQuestion(
        question: "¿Qué es la innovación social?",
        options: [
          "Solo usar redes sociales",
          "Desarrollar nuevas soluciones para problemas sociales",
          "Solo crear nuevas tecnologías",
          "Solo cambiar tradiciones"
        ],
        correctIndex: 1,
        explanation: "La innovación social busca desarrollar nuevas soluciones efectivas para abordar problemas sociales y ambientales.",
      ),
      QuizQuestion(
        question: "¿Cuál es una característica del emprendimiento social?",
        options: [
          "Solo buscar ganancias máximas",
          "Combinar objetivos sociales con sostenibilidad económica",
          "Solo ayudar a los más ricos",
          "Evitar toda responsabilidad social"
        ],
        correctIndex: 1,
        explanation: "El emprendimiento social combina la misión de generar impacto social positivo con la sostenibilidad económica.",
      ),
      
      // Cultura y Diversidad
      QuizQuestion(
        question: "¿Por qué es importante la diversidad cultural?",
        options: [
          "Solo para tener más idiomas",
          "Enriquece la sociedad y promueve la creatividad e innovación",
          "Solo para el turismo",
          "No tiene importancia real"
        ],
        correctIndex: 1,
        explanation: "La diversidad cultural enriquece a la sociedad, promueve la creatividad, innovación y el entendimiento mutuo.",
      ),
      QuizQuestion(
        question: "¿Qué es la inclusión social?",
        options: [
          "Solo incluir a algunos grupos",
          "Garantizar que todas las personas puedan participar plenamente en la sociedad",
          "Solo incluir a las mayorías",
          "Separar grupos por características"
        ],
        correctIndex: 1,
        explanation: "La inclusión social garantiza que todas las personas, independientemente de sus características, puedan participar plenamente en la sociedad.",
      ),
    ];
    
    // Seleccionar 10 preguntas aleatorias del banco de preguntas
    questionBank.shuffle(Random());
    questions = questionBank.take(10).toList();
  }

  void _startGame() {
    setState(() {
      gameStarted = true;
      timeLeft = 30;
    });
    _startTimer();
    _progressController.forward();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        timeLeft--;
      });
      
      if (timeLeft <= 0) {
        _timeUp();
      }
    });
  }

  void _timeUp() {
    if (!isAnswering) {
      _nextQuestion();
    }
  }

  void _answerQuestion(int selectedIndex) {
    if (isAnswering) return;
    
    setState(() {
      isAnswering = true;
    });

    final isCorrect = selectedIndex == questions[currentQuestionIndex].correctIndex;
    
    if (isCorrect) {
      setState(() {
        score += 10;
      });
      _bounceController.forward().then((_) => _bounceController.reverse());
    }

    // Mostrar respuesta por 2 segundos
    Future.delayed(const Duration(seconds: 2), () {
      _nextQuestion();
    });
  }

  void _nextQuestion() {
    _timer?.cancel();
    _progressController.reset();
    
    if (currentQuestionIndex < questions.length - 1) {
      setState(() {
        currentQuestionIndex++;
        timeLeft = 30;
        isAnswering = false;
      });
      _startTimer();
      _progressController.forward();
    } else {
      _endGame();
    }
  }

  void _endGame() {
    _timer?.cancel();
    setState(() {
      gameEnded = true;
    });
    _saveScore();
  }

  void _saveScore() async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId != null) {
        // Obtener datos actuales del usuario
        final userRef = FirebaseFirestore.instance
            .collection('usuarios')
            .doc(userId);
        
        final userDoc = await userRef.get();
        final userData = userDoc.data() ?? {};
        
        // Guardar la puntuación del quiz
        await FirebaseFirestore.instance
            .collection('quiz_scores')
            .add({
          'userId': userId,
          'score': score,
          'totalQuestions': questions.length,
          'timestamp': FieldValue.serverTimestamp(),
        });

        // Actualizar puntos del usuario
        await userRef.update({
          'puntosJuego': FieldValue.increment(score),
        });

        // Obtener estadísticas actualizadas para verificar medallas
        final currentPoints = (userData['puntosJuego'] ?? 0) + score;
        final totalQuizzes = await MedalsService.getTotalQuizzesCompleted();
        final currentMedals = List<String>.from(userData['medallasIDs'] ?? []);

        // Verificar y otorgar medallas
        final newMedals = await MedalsService.checkAndAwardQuizMedals(
          currentScore: score,
          totalQuestions: questions.length,
          totalQuizzesCompleted: totalQuizzes,
          totalGamePoints: currentPoints,
          currentMedalsIDs: currentMedals,
        );

        // Mostrar diálogo de medallas si se otorgaron nuevas
        if (newMedals.isNotEmpty && mounted) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            MedalsService.showMedalDialog(context, newMedals);
          });
        }
      }
    } catch (e) {
      print('Error guardando puntuación: $e');
    }
  }

  void _restartGame() {
    setState(() {
      currentQuestionIndex = 0;
      score = 0;
      timeLeft = 30;
      gameStarted = false;
      gameEnded = false;
      isAnswering = false;
    });
    _progressController.reset();
    questions.shuffle(Random());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E3A8A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'RSU Quiz Challenge',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: !gameStarted
          ? _buildStartScreen()
          : gameEnded
              ? _buildEndScreen()
              : _buildGameScreen(),
    );
  }

  Widget _buildStartScreen() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Icono del juego
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(60),
              border: Border.all(color: Colors.white, width: 3),
            ),
            child: const Icon(
              Icons.quiz,
              size: 60,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 32),
          
          // Título
          const Text(
            '🧠 RSU Quiz Challenge',
            style: TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          
          // Descripción
          const Text(
            'Pon a prueba tus conocimientos sobre\nResponsabilidad Social y Sostenibilidad',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 16,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 40),
          
          // Reglas del juego
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                _buildRuleItem('🎯', '${questions.length} preguntas'),
                const SizedBox(height: 12),
                _buildRuleItem('⏱️', '30 segundos por pregunta'),
                const SizedBox(height: 12),
                _buildRuleItem('⭐', '10 puntos por respuesta correcta'),
                const SizedBox(height: 12),
                _buildRuleItem('🏆', 'Gana puntos RSU'),
              ],
            ),
          ),
          const SizedBox(height: 40),
          
          // Botón de inicio
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: _startGame,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28),
                ),
              ),
              child: const Text(
                'COMENZAR QUIZ',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRuleItem(String icon, String text) {
    return Row(
      children: [
        Text(icon, style: const TextStyle(fontSize: 20)),
        const SizedBox(width: 12),
        Text(
          text,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
          ),
        ),
      ],
    );
  }

  Widget _buildGameScreen() {
    final question = questions[currentQuestionIndex];
    final progress = (currentQuestionIndex + 1) / questions.length;
    
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          // Header con progreso y score
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Pregunta ${currentQuestionIndex + 1}/${questions.length}',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                ),
              ),
              AnimatedBuilder(
                animation: _bounceAnimation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _bounceAnimation.value,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '⭐ $score',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          // Barra de progreso
          LinearProgressIndicator(
            value: progress,
            backgroundColor: Colors.white.withOpacity(0.3),
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.green),
            minHeight: 8,
          ),
          const SizedBox(height: 20),
          
          // Timer circular
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 80,
                height: 80,
                child: AnimatedBuilder(
                  animation: _progressController,
                  builder: (context, child) {
                    return CircularProgressIndicator(
                      value: 1 - _progressController.value,
                      strokeWidth: 6,
                      backgroundColor: Colors.white.withOpacity(0.3),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        timeLeft > 10 ? Colors.green : Colors.red,
                      ),
                    );
                  },
                ),
              ),
              Text(
                '$timeLeft',
                style: TextStyle(
                  color: timeLeft > 10 ? Colors.white : Colors.red,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 40),
          
          // Pregunta
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Text(
              question.question,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 32),
          
          // Opciones de respuesta
          Expanded(
            child: ListView.builder(
              itemCount: question.options.length,
              itemBuilder: (context, index) {
                final isCorrect = index == question.correctIndex;
                
                Color buttonColor = Colors.white;
                Color textColor = Colors.black87;
                
                if (isAnswering) {
                  if (isCorrect) {
                    buttonColor = Colors.green;
                    textColor = Colors.white;
                  }
                }
                
                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  child: SizedBox(
                    width: double.infinity,
                    height: 60,
                    child: ElevatedButton(
                      onPressed: isAnswering ? null : () => _answerQuestion(index),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: buttonColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 3,
                      ),
                      child: Text(
                        question.options[index],
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: textColor,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEndScreen() {
    final percentage = (score / (questions.length * 10) * 100).round();
    String message = '';
    String emoji = '';
    
    if (percentage >= 80) {
      message = '¡Excelente! Eres un experto en RSU';
      emoji = '🏆';
    } else if (percentage >= 60) {
      message = '¡Bien hecho! Tienes buenos conocimientos';
      emoji = '👏';
    } else if (percentage >= 40) {
      message = 'No está mal, pero puedes mejorar';
      emoji = '💪';
    } else {
      message = 'Sigue aprendiendo sobre RSU';
      emoji = '📚';
    }
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Emoji y mensaje
          Text(
            emoji,
            style: const TextStyle(fontSize: 80),
          ),
          const SizedBox(height: 24),
          
          Text(
            'Quiz Completado',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          
          Text(
            message,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 18,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 40),
          
          // Resultados
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                _buildResultItem('Puntuación', '$score/${questions.length * 10}'),
                const SizedBox(height: 16),
                _buildResultItem('Porcentaje', '$percentage%'),
                const SizedBox(height: 16),
                _buildResultItem('Respuestas correctas', '${score ~/ 10}/${questions.length}'),
                const SizedBox(height: 16),
                _buildResultItem('Puntos RSU ganados', '+$score'),
              ],
            ),
          ),
          const SizedBox(height: 40),
          
          // Botones
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _restartGame,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                    ),
                    child: const Text(
                      'JUGAR DE NUEVO',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: SizedBox(
                  height: 50,
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.white),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                    ),
                    child: const Text(
                      'SALIR',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildResultItem(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 16,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

class QuizQuestion {
  final String question;
  final List<String> options;
  final int correctIndex;
  final String explanation;

  QuizQuestion({
    required this.question,
    required this.options,
    required this.correctIndex,
    required this.explanation,
  });
}
