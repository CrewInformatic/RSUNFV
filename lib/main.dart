import 'package:flutter/material.dart';
import 'package:rsunfv_app/screen/eventos_s.dart';
import 'package:rsunfv_app/screen/home_s.dart';
import 'package:rsunfv_app/screen/login_s.dart';
import 'package:rsunfv_app/screen/splash_s.dart';
//IMPORTACIONES DE FIREBASE
import 'package:firebase_core/firebase_core.dart';
import 'package:rsunfv_app/firebase_options.dart';


void main() async{
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

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
        '/splash': (context) => HomeScreen(),
        '/login': (context) => LoginScreen(),
        '/eventos': (context) => EventosScreen(),
      },
    );
  }
}
