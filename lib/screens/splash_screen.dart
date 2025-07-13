import 'dart:async';
import 'package:flutter/material.dart';
import '../utils/colors.dart';
import '../screens/login_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  Timer? _timer; 

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer(const Duration(milliseconds: 4000), () {
      if (mounted) { 
        Navigator.pushReplacement( 
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel(); 
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.orangeColors, AppColors.orangeLightColors],
            end: Alignment.bottomCenter,
            begin: Alignment.topCenter,
          ),
        ),
        child: const Center( 
          child: Image(
            image: AssetImage("assets/logo_rsu.png"), 
          ),
        ),
      ),
    );
  }
}