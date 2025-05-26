import 'package:flutter/material.dart';
import 'package:rsunfv_app/widgets/drawer.dart';
import '../widgets/home_header.dart';
import '../services/firebase_auth_services.dart';
import '../utils/home_img.dart'; // ← IMPORTANTE
import 'dart:async';

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
                  HomeImg1.homeImageUrl, // usa homeImageAsset si es asset
                  fit: BoxFit.cover,
                ),
              ),

              // TEXTO BIENVENIDA + DESCRIPCIÓN
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Text(
                  'Área de Responsabilidad Social Universitaria',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5,
                    shadows: [
        Shadow(
          offset: Offset(0.5, 0.5),
          color: Colors.black12,
          blurRadius: 0.5,
        )
      ],
                  ),
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Text(
                  'La Secretaría de Proyección y Responsabilidad Social Universitaria es la responsable de ejecutar la política de proyección social de la Universidad. '
                  'La proyección social se define como una función universitaria de transferencia de conocimientos que la Católica ha adoptado como parte constitutiva '
                  'de su modelo de enseñanza y aprendizaje.',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.black87,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.justify,
                ),
              ),

              // Puedes seguir agregando más contenido aquí...
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

          // MENÚ DESPLEGABLE (debajo del header)
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
      'Perfil que buscamos',
      'Actividades',
      'Contáctanos',
    ];

    return items
        .map((item) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                item,
                style: const TextStyle(fontSize: 16, color: Colors.black87),
              ),
            ))
        .toList();
  }
}
