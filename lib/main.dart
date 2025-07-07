import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:rsunfv_app/firebase_options.dart';
import 'package:rsunfv_app/core/constants/app_routes.dart';
import 'package:rsunfv_app/controllers/setup_data_controller.dart';
import 'package:rsunfv_app/presentation/screens/home/home_screen.dart';
import 'package:rsunfv_app/screens/login_screen.dart';
import 'package:rsunfv_app/screens/events_screen_new.dart';
import 'package:rsunfv_app/screens/profile_screen.dart';
import 'package:rsunfv_app/screens/donations_screen.dart';
import 'package:rsunfv_app/screens/games_hub_screen.dart';
import 'package:rsunfv_app/screens/splash_screen.dart';
import 'package:rsunfv_app/screens/donation_payment_screen.dart';
import 'package:rsunfv_app/screens/cards_screen.dart';
import 'package:rsunfv_app/screens/notifications_screen.dart';
import 'package:rsunfv_app/screens/setup/cycle_screen.dart';
import 'package:rsunfv_app/screens/setup/code_age_screen.dart';
import 'package:rsunfv_app/screens/setup/faculty_school_screen.dart';
import 'package:rsunfv_app/screens/setup/size_screen.dart';
import 'package:rsunfv_app/services/notification_trigger_service.dart';
import 'package:rsunfv_app/services/local_notification_service.dart';

/// Punto de entrada principal de la aplicación RSUNFV
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // Inicializar el servicio de notificaciones automáticas
  NotificationTriggerService.initialize();
  
  // Inicializar el servicio de notificaciones locales
  await LocalNotificationService.initialize(
    onNotificationTap: _handleNotificationTap,
  );
  
  // Solicitar permisos de notificación
  await LocalNotificationService.requestPermissions();
  
  runApp(const MyApp());
}

/// Manejar el tap en notificaciones locales
void _handleNotificationTap(String? payload) {
  if (payload != null && payload.isNotEmpty) {
    // Aquí puedes manejar la navegación basada en el payload
    // Por ejemplo, si payload es "/evento_detalle?id=123"
    // Puedes extraer la ruta y navegar apropiadamente
    print('Notification tapped with payload: $payload');
  }
}

/// Controlador global para el proceso de configuración inicial
final setupController = SetupDataController();

/// Widget principal de la aplicación RSUNFV
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'RSUNFV App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const SplashScreen(),
      routes: _buildRoutes(),
    );
  }


  Map<String, WidgetBuilder> _buildRoutes() {
    return {
      AppRoutes.splash: (context) => const HomeScreen(),
      AppRoutes.home: (context) => const HomeScreen(),
      AppRoutes.login: (context) => const LoginScreen(),
      AppRoutes.eventos: (context) => const EventosScreenNew(),
      AppRoutes.eventoDetalle: (context) => _buildEventoDetalleRoute(context),
      AppRoutes.games: (context) => const GamesHubScreen(),
      AppRoutes.setupCodigo: (context) => CodigoEdadScreen(controller: setupController),
      AppRoutes.setupFacultad: (context) => FacultadScreen(controller: setupController),
      AppRoutes.setupCiclo: (context) => CicloScreen(controller: setupController),
      AppRoutes.setupTalla: (context) => TallaScreen(controller: setupController),
      AppRoutes.donaciones: (context) => const DonacionesScreen(),
      AppRoutes.donacionesNueva: (context) => const DonacionPagoScreen(),
      AppRoutes.perfil: (context) => const PerfilScreen(),
      AppRoutes.notificaciones: (context) => const NotificationsScreen(),
    };
  }

  Widget _buildEventoDetalleRoute(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    
    if (args != null && args['id'] != null) {
      return EventoDetailScreen(
        eventoId: args['id'] as String,
      );
    }
    
    return const EventosScreenNew();
  }
}
