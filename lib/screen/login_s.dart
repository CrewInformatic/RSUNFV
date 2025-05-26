import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import '../screen/register_s.dart';
import '../utils/colors.dart';
import '../widgets/btn.dart';
import '../widgets/header_container.dart'; // Importa tu header
import '../services/firebase_auth_services.dart'; 
// Pantalla principal
import 'home_s.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  final AuthService _authService = AuthService(); 

  Future<void> _handleLogin() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Por favor completa todos los campos')),
      );
      return;
    }

    final result = await _authService.signInWithEmail(email, password);

    if (result != null) {
      final user = result.user;

      if (user != null && user.emailVerified) {
        // Ir a la pantalla principal
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => HomeScreen()),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Por favor verifica tu correo electrónico')),
        );
        await _authService.sendEmailVerification(); // Reenvía verificación si es necesario
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Credenciales incorrectas')),
      );
    }
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
                    child: Text(
                      "Forgot Password?",
                    ),
                  ),
                  Expanded(
                    child: Center(
                      child: ButtonWidget(
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
