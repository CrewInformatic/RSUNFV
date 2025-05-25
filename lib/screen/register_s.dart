import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import '../utils/colors.dart';
import '../widgets/btn.dart';
import '../widgets/header_container.dart'; // Importa tu header
import '../services/firebase_auth_services.dart';
import '../models/usuario.dart'; 

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController _fullnameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  final AuthService _authService = AuthService();

  Future<void> _handleRegister() async {
    final fullname = _fullnameController.text.trim();
    final email = _emailController.text.trim();
    final phone = _phoneController.text.trim();
    final password = _passwordController.text.trim();

    if (fullname.isEmpty || email.isEmpty || phone.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Por favor completa todos los campos')),
      );
      return;
    }

    final result = await _authService.signUpWithEmail(
      email,
      password,
      nombre: fullname,
    );

    if (result != null) {
      final uid = result.user?.uid ?? '';
      final usuario = Usuario(
        idUsuario: uid,
        codigoUsuario: '',
        nombre: fullname,
        apellido: '',
        correo: email,
        clave: password,
        escuelaID: '',
        fechaNacimientoID: '',
        fotoPerfil: '',
        poloTallaID: '',
        medallasID: [],
        estadoActivo: true,
      );

      await _authService.saveUsuario(usuario);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Registro exitoso. Verifica tu correo.')),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al registrar. Intenta de nuevo.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: <Widget>[
          HeaderContainer(text: "Registro"),
          Expanded(
            child: Container(
              margin: EdgeInsets.only(left: 20, right: 20, top: 30),
              child: Column(
                mainAxisSize: MainAxisSize.max,
                children: <Widget>[
                  _textInput(controller: _fullnameController, hint: "Fullname", icon: Icons.person),
                  _textInput(controller: _emailController, hint: "Email", icon: Icons.email),
                  _textInput(controller: _phoneController, hint: "Phone Number", icon: Icons.call),
                  _textInput(controller: _passwordController, hint: "Password", icon: Icons.vpn_key, isPassword: true),
                  Expanded(
                    child: Center(
                      child: ButtonWidget(
                        btnText: "REGISTER",
                        onClick: _handleRegister,
                      ),
                    ),
                  ),
                  RichText(
                    text: TextSpan(children: [
                      TextSpan(
                          text: "Already a member? ",
                          style: TextStyle(color: Colors.black)),
                      TextSpan(
                          text: "Login",
                          style: TextStyle(color: orangeColors),
                          recognizer: TapGestureRecognizer()
                            ..onTap = () {
                              Navigator.pop(context);
                            }),
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

  Widget _textInput({required TextEditingController controller, required String hint, required IconData icon, bool isPassword = false}) {
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
