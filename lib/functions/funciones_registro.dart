import 'package:flutter/material.dart';
import '../models/usuario.dart';
import '../services/firebase_auth_services.dart';
import 'package:logger/logger.dart';

class RegistroFunctions {
  static final AuthService _authService = AuthService();
  static final Logger _logger = Logger();

  static Future<bool> handleRegister({
    required String fullname,
    required String email,
    required String phone,
    required String password,
    required BuildContext context,
  }) async {
    try {
      if (fullname.isEmpty || email.isEmpty || phone.isEmpty || password.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Por favor completa todos los campos')),
        );
        return false;
      }

      final result = await _authService.signUpWithEmail(
        email,
        password,
        nombre: fullname,
      );

      if (!context.mounted) return false;

      if (result != null) {
        final uid = result.user?.uid ?? '';
        final usuario = Usuario(
          idUsuario: uid,
          codigoUsuario: '',
          nombreUsuario: fullname,
          apellidoUsuario: '',
          correo: email,
          facultadID: '',
          fechaNacimiento: '',
          fotoPerfil: '',
          poloTallaID: '',
          medallasID: '',
          estadoActivo: true,
        );

        await _authService.saveUsuario(usuario);
        
        if (!context.mounted) return false;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Registro exitoso. Verifica tu correo.')),
        );
        return true;
      } else {
        if (!context.mounted) return false;
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error al registrar. Intenta de nuevo.')),
        );
        return false;
      }
    } catch (e) {
      _logger.e('Error en el registro: $e');
      if (!context.mounted) return false;
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error inesperado. Intenta de nuevo.')),
      );
      return false;
    }
  }
}