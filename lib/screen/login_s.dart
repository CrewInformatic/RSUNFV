import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import '../screen/register_s.dart';
import '../utils/colors.dart';
import '../widgets/btn.dart';
import '../widgets/header_container.dart';
import '../services/firebase_auth_services.dart';
import '../screen/setup/codigo_edad_s.dart';
import '../controllers/setup_data_controller.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  final AuthService _authService = AuthService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool _isLoading = false;

  Future<void> _handleLogin() async {
    setState(() => _isLoading = true);
    
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      _showSnackBar('Por favor completa todos los campos');
      setState(() => _isLoading = false);
      return;
    }

    try {
      final result = await _authService.signInWithEmail(email, password);

      if (result != null) {
        final user = result.user;

        if (user != null && user.emailVerified) {
          // Verificar si el documento del usuario existe en Firestore
          final userDoc = await _firestore.collection('usuarios').doc(user.uid).get();
          
          if (!userDoc.exists) {
            // Si el documento no existe, crearlo con datos básicos
            await _createUserDocument(user.uid, email);
          }

          final controller = SetupDataController();
          await controller.initUser(); // Inicializar el usuario

          // Verificar si necesita completar el setup
          if (controller.usuario.codigoUsuario.isEmpty || 
              controller.usuario.edad == 0 || 
              controller.usuario.facultadID.isEmpty ||
              controller.usuario.ciclo.isEmpty ||
              controller.usuario.poloTallaID.isEmpty) {
            // Usuario necesita completar setup
            if (mounted) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => CodigoEdadScreen(controller: controller),
                ),
              );
            }
          } else {
            // Usuario ya completó setup, ir a home
            if (mounted) {
              Navigator.pushReplacementNamed(context, '/home');
            }
          }
        } else {
          _showSnackBar('Por favor verifica tu correo electrónico');
          await _authService.sendEmailVerification();
        }
      } else {
        _showSnackBar('Credenciales incorrectas');
      }
    } catch (e) {
      _showSnackBar('Error al iniciar sesión: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _createUserDocument(String uid, String email) async {
    try {
      // Crear fecha actual en formato ISO
      String currentDate = DateTime.now().toIso8601String();
      
      await _firestore.collection('usuarios').doc(uid).set({
        'idUsuario': uid,
        'correo': email,
        'nombreUsuario': email.split('@')[0],
        'apellidoUsuario': '',
        'codigoUsuario': '',
        'fotoPerfil': '',
        'fechaNacimiento': '',
        'poloTallaID': '',
        'esAdmin': false,
        'facultadID': '',
        'estadoActivo': true,
        'ciclo': '',
        'edad': 0,
        'medallasID': '',
        'fechaRegistro': currentDate,
        'fechaModificacion': currentDate,
      });
    } catch (e) {
      print('Error al crear documento de usuario: $e');
      _showSnackBar('Error al crear perfil de usuario');
    }
  }

  void _showSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
  }

  void _showRecoverPasswordDialog(BuildContext context) {
    final TextEditingController emailController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Recuperar Contraseña"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Ingresa tu correo electrónico y te enviaremos un enlace para restablecer tu contraseña.',
                style: TextStyle(fontSize: 14),
              ),
              SizedBox(height: 16),
              TextField(
                controller: emailController,
                decoration: InputDecoration(
                  hintText: 'Email',
                  prefixIcon: Icon(Icons.email),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              child: Text("Cancelar"),
              onPressed: () => Navigator.of(context).pop(),
            ),
            ElevatedButton(
              onPressed: () async {
                final email = emailController.text.trim();
                if (email.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Por favor ingresa tu email'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                try {
                  await _authService.resetPassword(email);
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Se ha enviado un enlace a tu correo'),
                      backgroundColor: Colors.green,
                    ),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error al enviar el correo: ${e.toString()}'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.orangeColors,
              ),
              child: Text("Enviar"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: <Widget>[
          HeaderContainer(text: "Iniciar Sesión"),
          Expanded(
            child: Container(
              margin: EdgeInsets.only(left: 20, right: 20, top: 30),
              child: Column(
                mainAxisSize: MainAxisSize.max,
                children: <Widget>[
                  _textInput(
                      controller: _emailController,
                      hint: "Email",
                      icon: Icons.email),
                  _textInput(
                      controller: _passwordController,
                      hint: "Password",
                      icon: Icons.vpn_key,
                      isPassword: true),
                  Container(
                    margin: EdgeInsets.only(top: 10),
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () => _showRecoverPasswordDialog(context),
                      child: Text(
                        "¿Olvidaste tu contraseña?",
                        style: TextStyle(
                          color: AppColors.orangeColors,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Center(
                      child: _isLoading
                          ? CircularProgressIndicator(
                              color: AppColors.orangeColors,
                            )
                          : ButtonWidget(
                              onClick: _handleLogin,
                              btnText: "LOGIN",
                            ),
                    ),
                  ),
                  RichText(
                    text: TextSpan(children: [
                      TextSpan(
                          text: "Don't have an account? ",
                          style: TextStyle(color: Colors.black)),
                      TextSpan(
                        text: "Register",
                        style: TextStyle(color: AppColors.orangeColors),
                        recognizer: TapGestureRecognizer()
                          ..onTap = () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => RegisterScreen()),
                            );
                          },
                      ),
                    ]),
                  )
                ],
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _textInput({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool isPassword = false,
  }) {
    return Container(
      margin: EdgeInsets.only(top: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.all(Radius.circular(20)),
        color: Colors.white,
      ),
      padding: EdgeInsets.only(left: 10),
      child: TextFormField(
        controller: controller,
        obscureText: isPassword,
        decoration: InputDecoration(
          border: InputBorder.none,
          hintText: hint,
          prefixIcon: Icon(icon),
        ),
      ),
    );
  }
}