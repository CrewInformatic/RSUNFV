import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:rsunfv_app/widgets/drawer.dart';
import '../widgets/home_header.dart';
import '../services/firebase_auth_services.dart';
import '../utils/home_img.dart';
import 'dart:async';
import 'package:url_launcher/url_launcher.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String? imageUrl;
  bool showProfile = true;
  Timer? _timer;
  bool _menuVisible = false;
  final String defaultUrl =
      'https://res.cloudinary.com/dupkeaqnz/image/upload/f_auto,q_auto/hgofvxczx14ktcc5ubjs';

  @override
  void initState() {
    super.initState();
    _loadUserImage();
    _timer = Timer.periodic(const Duration(seconds: 5), (timer) {
      setState(() {
        showProfile = !showProfile;
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _loadUserImage() async {
    final authService = AuthService();
    final userData = await authService.getUserData();
    setState(() {
      imageUrl = userData?.get('fotoPerfil');
    });
  }

  @override
  Widget build(BuildContext context) {
    final String currentImage =
        (showProfile && imageUrl != null && imageUrl!.isNotEmpty)
            ? imageUrl!
            : defaultUrl;

    return Scaffold(
      drawer: MyDrawer(currentImage: currentImage),
      body: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.only(top: 100),
            children: [
              // IMAGEN PRINCIPAL
              SizedBox(
                width: double.infinity,
                height: 200,
                child: Image.network(
                  HomeImg1.homeImageUrl,
                  fit: BoxFit.cover,
                ),
              ),

              // TEXTOS
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Text(
                  'Área de Responsabilidad Social Universitaria',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5,
                    shadows: [Shadow(offset: Offset(0.5, 0.5), color: Colors.black12, blurRadius: 0.5)],
                  ),
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Text(
                  'La Secretaría de Proyección y Responsabilidad Social Universitaria es la responsable de ejecutar la política de proyección social de la Universidad. '
                  'La proyección social se define como una función universitaria de transferencia de conocimientos que la Católica ha adoptado como parte constitutiva '
                  'de su modelo de enseñanza y aprendizaje.',
                  style: TextStyle(fontSize: 16, color: Colors.black87, height: 1.5),
                  textAlign: TextAlign.justify,
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Text(
                  '¿Qué es RSU?',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5,
                    shadows: [Shadow(offset: Offset(0.5, 0.5), color: Colors.black12, blurRadius: 0.5)],
                  ),
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Text(
                  'La Responsabilidad Social Universitaria (RSU) es un compromiso ético y social que tienen las universidades para contribuir al desarrollo sostenible de la sociedad. '
                  'Implica la integración de actividades académicas, investigativas y de extensión que buscan mejorar la calidad de vida de las comunidades, promoviendo valores de solidaridad, equidad y respeto al medio ambiente.',
                  style: TextStyle(fontSize: 16, color: Colors.black87, height: 1.5),
                  textAlign: TextAlign.justify,
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Text(
                  '¿Quiénes Somos?',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5,
                    shadows: [Shadow(offset: Offset(0.5, 0.5), color: Colors.black12, blurRadius: 0.5)],
                  ),
                ),
              ),
              // VIDEO MINIATURA
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: GestureDetector(
                  onTap: () async {
                    const url = 'https://www.youtube.com/watch?v=wSNe17HEm2o';
                    if (await canLaunchUrl(Uri.parse(url))) {
                      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
                    }
                  },
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          'https://img.youtube.com/vi/wSNe17HEm2o/0.jpg',
                          height: 200,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      ),
                      Container(
                        decoration: BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                        child: const Icon(Icons.play_arrow, color: Colors.white, size: 64),
                      ),
                    ],
                  ),
                ),
              ),

              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Text(
                  'Perfil del Voluntario/a',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5,
                    shadows: [Shadow(offset: Offset(0.5, 0.5), color: Colors.black12, blurRadius: 0.5)],
                  ),
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Text(
                  '• Estudiantes de especialidades como Ingeniería Infórmatica, Electronica, Mecatronica, Telecomunicaciones y otras afines.\n'
                  '• Con compromiso, sensibles, pacientes y con disposición para trabajar con niños/as.\n\n'
                  'Tareas/Responsabilidades del voluntario/a:\n'
                  '   • Visitar a los/as niños/as en sus casas un promedio de 4 horas a la semana (dos horas por día) en horarios y días fijos. Las fechas y horas se coordinarán con las familias de los niños y según la disponibilidad del/a voluntario/a.\n'
                  '   • Asistir a reuniones de seguimiento sobre el proceso de tutoría.\n'
                  '   • Elaborar un informe final sobre la experiencia con el niño asignado.',
                  style: TextStyle(fontSize: 16, color: Colors.black87, height: 1.5),
                  textAlign: TextAlign.justify,
                ),
              ),

              // PIE DE PÁGINA
              const SizedBox(height: 24),
              Container(
                color: Colors.grey.shade100,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Columna izquierda
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'Contáctenos',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Correo electrónico:\nvoluntariado.rsu@unfv.edu.pe',
                          style: TextStyle(fontSize: 14),
                        ),
                      ],
                    ),
                    // Columna derecha
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text(
                          'Síguenos en:',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            IconButton(
                              icon: const FaIcon(FontAwesomeIcons.youtube),
                              onPressed: () {
                                launchUrl(Uri.parse('https://youtube.com'), mode: LaunchMode.externalApplication);
                              },
                              tooltip: 'YouTube',
                              color: Colors.red,
                            ),
                            IconButton(
                              icon: const FaIcon(FontAwesomeIcons.facebook),
                              onPressed: () {
                                launchUrl(Uri.parse('https://facebook.com'), mode: LaunchMode.externalApplication);
                              },
                              tooltip: 'Facebook',
                              color: Colors.blueAccent,
                            ),
                            IconButton(
                              icon: const FaIcon(FontAwesomeIcons.instagram),
                              onPressed: () {
                                launchUrl(Uri.parse('https://instagram.com'), mode: LaunchMode.externalApplication);
                              },
                              tooltip: 'Instagram',
                              color: Colors.purple,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),

          // HEADER
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: HomeHeader(
              onToggleMenu: () {
                setState(() {
                  _menuVisible = !_menuVisible;
                });
              },
            ),
          ),

          // MENÚ DESPLEGABLE
          if (_menuVisible)
            Positioned(
              top: 80,
              left: 0,
              right: 0,
              child: Container(
                color: const Color(0xFFF9F9F9),
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: _buildMenuItems(),
                ),
              ),
            ),
        ],
      ),
    );
  }

  List<Widget> _buildMenuItems() {
    const items = [
      '¿Qué es RSU?',
      'Equipo de gestión',
      'Proyectos',
      'Eventos',
      'Voluntariado',
    ];

    return items.map((item) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Text(item, style: const TextStyle(fontSize: 16)),
      );
    }).toList();
  }
}
