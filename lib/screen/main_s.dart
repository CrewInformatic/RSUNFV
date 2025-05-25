import 'dart:async';
import 'package:flutter/material.dart';
import 'package:rsunfv_app/screen/perfil_s.dart';
import '../widgets/perfil_header.dart';
import '../services/firebase_auth_services.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  String? imageUrl;
  bool showProfile = true;
  Timer? _timer;

  final String defaultUrl = 'https://res.cloudinary.com/dupkeaqnz/image/upload/f_auto,q_auto/hgofvxczx14ktcc5ubjs';

  @override
  void initState() {
    super.initState();
    _loadUserImage();
    _timer = Timer.periodic(Duration(seconds: 5), (timer) {
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
    final String currentImage = (showProfile && imageUrl != null && imageUrl!.isNotEmpty)
        ? imageUrl!
        : defaultUrl;

    return Scaffold(
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            Container(
              color: Colors.orange.shade700,
              padding: EdgeInsets.symmetric(vertical: 32),
              child: PerfilHeader(
                imagePath: currentImage,
                isNetwork: true,
                onCameraTap: () {},
              ),
            ),
            ListTile(
              leading: Icon(Icons.home),
              title: Text('Home'),
              onTap: () {},
            ),
            ListTile(
              leading: Icon(Icons.settings),
              title: Text('Perfil'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PerfilScreen(),
                  ),
                );
              },
            ),
          ],
        ),
      ),
      appBar: AppBar(
        title: Row(
          children: [
            AnimatedSwitcher(
              duration: Duration(milliseconds: 600),
              transitionBuilder: (child, animation) {
                final rotate = Tween(begin: 1.0, end: 0.0).animate(animation);
                return AnimatedBuilder(
                  animation: rotate,
                  child: child,
                  builder: (context, child) {
                    final isUnder = (rotate.value < 0.5);
                    final tilt = (isUnder ? (1 - rotate.value) : rotate.value) * 3.1416;
                    return Transform(
                      transform: Matrix4.rotationY(tilt),
                      alignment: Alignment.center,
                      child: child,
                    );
                  },
                );
              },
              child: CircleAvatar(
                key: ValueKey(currentImage),
                radius: 18,
                backgroundImage: NetworkImage(currentImage),
              ),
            ),
            const SizedBox(width: 12),
            Text('RSUNFV'),
          ],
        ),
        backgroundColor: Colors.orange.shade700,
        actions: [
          IconButton(
            icon: Icon(Icons.settings),
            onPressed: () {},
          ),
        ],
      ),
      backgroundColor: Colors.white,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Spacer(),
              Text(
                'Welcome to',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w700,
                  color: Colors.black,
                ),
              ),
              Text(
                'APP RSUNFV',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.bold,
                  color: Colors.orange.shade700,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'APP MOVIL DE GESTION DE VOLUNTARIADO EN LA FIEI.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey[700]),
              ),
              const SizedBox(height: 32),
              Wrap(
                spacing: 16,
                runSpacing: 12,
                alignment: WrapAlignment.center,
                children: [
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange.shade700,
                      padding:
                          EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                    ),
                    onPressed: () {},
                    icon: Icon(Icons.arrow_forward_ios, size: 16),
                    label: Text('Propon un Evento'),
                  ),
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      padding:
                          EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                    ),
                    onPressed: () {},
                    child: Text('Participa en un Evento'),
                  ),
                ],
              ),
              Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}