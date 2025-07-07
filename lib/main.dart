import 'package:flutter/material.dart';
//Firebase
import 'package:firebase_core/firebase_core.dart';
import 'package:rsunfv_app/firebase_options.dart';
//Screens
import 'package:rsunfv_app/screen/eventos_s.dart';
import 'package:rsunfv_app/screen/home_s_new.dart';
// import 'package:rsunfv_app/screen/home_s.dart'; // Archivo anterior comentado
import 'package:rsunfv_app/screen/login_s.dart';
import 'package:rsunfv_app/screen/splash_s.dart';
import 'package:rsunfv_app/screen/donaciones_s.dart';
import 'package:rsunfv_app/screen/perfil_s.dart';
import 'package:rsunfv_app/screen/games_hub_s.dart';
//Donaciones
import 'package:rsunfv_app/screen/donacion_pago_s.dart';
//SETUP
import 'package:rsunfv_app/screen/setup/codigo_edad_s.dart';
import 'package:rsunfv_app/controllers/setup_data_controller.dart';
import 'package:rsunfv_app/screen/setup/facultad_escuela_s.dart';
import 'package:rsunfv_app/screen/setup/ciclo_s.dart';
import 'package:rsunfv_app/screen/setup/talla_s.dart';


void main() async{
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

final setupController = SetupDataController();

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: SplashScreen(),
      routes: {
        '/splash': (context) => const HomeScreen(),
        '/home': (context) => const HomeScreen(),
        '/login': (context) => const LoginScreen(),
        '/eventos': (context) => const EventosScreen(),
        '/games': (context) => const GamesHubScreen(),
        '/setup/codigo': (context) => CodigoEdadScreen(controller: setupController),
        '/setup/facultad': (context) => FacultadScreen(controller: setupController),
        '/setup/ciclo': (context) => CicloScreen(controller: setupController), 
        '/setup/talla': (context) => TallaScreen(controller: setupController),
        '/donaciones': (context) => const DonacionesScreen(),
        '/donaciones/nueva': (context) => const DonacionPagoScreen(),
        '/perfil': (context) => const PerfilScreen(),
      },
    );
  }
}
