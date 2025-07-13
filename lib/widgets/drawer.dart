import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'perfil_header.dart'; // Asegúrate de importar tu PerfilHeader
import '../presentation/screens/home/home_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/admin_event_attendance_screen.dart';
import '../screens/admin_statistics_screen.dart';
import '../screens/validation_screen.dart';
import '../screens/admin_tools_screen.dart';
import '../core/constants/app_routes.dart';

class MyDrawer extends StatefulWidget {
  final String currentImage;

  const MyDrawer({
    super.key,
    required this.currentImage,
  });

  @override
  State<MyDrawer> createState() => _MyDrawerState();
}

class _MyDrawerState extends State<MyDrawer> {
  bool _isAdmin = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkAdminStatus();
  }

  Future<void> _checkAdminStatus() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      setState(() {
        _isLoading = false;
      });
      return;
    }

    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(currentUser.uid)
          .get();

      if (userDoc.exists) {
        final userData = userDoc.data()!;
        final isAdmin = userData['esAdmin'] ?? false;
        
        // Debug logging
        debugPrint('🔍 Admin check - User UID: ${currentUser.uid}');
        debugPrint('🔍 Admin check - Document exists: ${userDoc.exists}');
        debugPrint('🔍 Admin check - User data keys: ${userData.keys.toList()}');
        debugPrint('🔍 Admin check - esAdmin field: ${userData['esAdmin']}');
        debugPrint('🔍 Admin check - isAdmin result: $isAdmin');
        
        setState(() {
          _isAdmin = isAdmin;
          _isLoading = false;
        });
        
        debugPrint('🔍 Admin check - State updated, _isAdmin: $_isAdmin');
      } else {
        debugPrint('🔍 Admin check - User document does not exist');
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('🔍 Admin check - Error: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('🎨 Building drawer - _isLoading: $_isLoading, _isAdmin: $_isAdmin');
    
    if (_isLoading) {
      debugPrint('🔄 Showing loading spinner for admin check');
    } else if (_isAdmin) {
      debugPrint('✅ Showing admin menu - _isAdmin: $_isAdmin');
    } else {
      debugPrint('❌ NOT showing admin menu - _isAdmin: $_isAdmin');
    }
    
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          Container(
            color: Colors.orange.shade700,
            padding: const EdgeInsets.symmetric(vertical: 32),
            child: PerfilHeader(
              imagePath: widget.currentImage,
              isNetwork: true,
              onCameraTap: () {},
            ),
          ),
          ListTile(
            leading: const Icon(Icons.home),
            title: const Text('Home'),
            onTap: () {
              Navigator.pop(context); // Cierra el drawer
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const HomeScreen()),
                (route) => false,
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.event),
            title: const Text('Eventos'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/eventos');
            },
          ),
          ListTile(
            leading: const Icon(Icons.volunteer_activism),
            title: const Text('Donaciones'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/donaciones');
            },
          ),
          ListTile(
            leading: const Icon(Icons.person),
            title: const Text('Perfil'),
            onTap: () {
              Navigator.pop(context); // Cierra el drawer
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const PerfilScreen()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.rate_review),
            title: const Text('Enviar Testimonio'),
            subtitle: const Text('Comparte tu experiencia'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, AppRoutes.enviarTestimonio);
            },
          ),
          
          // Sección de administración (solo visible para administradores)
          if (_isLoading) ...[
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            ),
          ] else if (_isAdmin) ...[
            const Divider(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Icon(
                    Icons.admin_panel_settings,
                    color: Colors.orange.shade700,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'ADMINISTRACIÓN',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange.shade700,
                    ),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: Icon(
                Icons.assignment_turned_in,
                color: Colors.orange.shade700,
              ),
              title: const Text('Control de Asistencia'),
              subtitle: const Text('Marcar asistencia de eventos'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AdminEventAttendanceScreen(),
                  ),
                );
              },
            ),
            ListTile(
              leading: Icon(
                Icons.analytics,
                color: Colors.orange.shade700,
              ),
              title: const Text('Estadísticas'),
              subtitle: const Text('Ver métricas de eventos'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AdminStatisticsScreen(),
                  ),
                );
              },
            ),
            ListTile(
              leading: Icon(
                Icons.verified_user,
                color: Colors.orange.shade700,
              ),
              title: const Text('Validaciones'),
              subtitle: const Text('Gestionar validaciones de donaciones'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ValidationScreen(),
                  ),
                );
              },
            ),
            ListTile(
              leading: Icon(
                Icons.build,
                color: Colors.orange.shade700,
              ),
              title: const Text('Herramientas'),
              subtitle: const Text('Migración y corrección de datos'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AdminToolsScreen(),
                  ),
                );
              },
            ),
            ListTile(
              leading: Icon(
                Icons.rate_review,
                color: Colors.orange.shade700,
              ),
              title: const Text('Gestionar Testimonios'),
              subtitle: const Text('Aprobar/rechazar testimonios'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, AppRoutes.adminTestimonios);
              },
            ),
            ListTile(
              leading: Icon(
                Icons.reviews,
                color: Colors.orange.shade700,
              ),
              title: const Text('Gestionar Testimonios'),
              subtitle: const Text('Revisar y aprobar testimonios'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, AppRoutes.adminTestimonios);
              },
            ),
          ],
        ],
      ),
    );
  }
}
