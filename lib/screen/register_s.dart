import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import '../utils/colors.dart';
import '../widgets/btn.dart';
import '../widgets/header_container.dart';
import '../functions/funciones_registro.dart';

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

  Future<void> _handleRegister() async {
    final success = await RegistroFunctions.handleRegister(
      fullname: _fullnameController.text.trim(),
      email: _emailController.text.trim(),
      phone: _phoneController.text.trim(),
      password: _passwordController.text.trim(),
      context: context,
    );

    if (success) {
      Navigator.pop(context);
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
                  _textInput(
                      controller: _fullnameController,
                      hint: "Fullname",
                      icon: Icons.person),
                  _textInput(
                      controller: _emailController,
                      hint: "Email",
                      icon: Icons.email),
                  _textInput(
                      controller: _phoneController,
                      hint: "Phone Number",
                      icon: Icons.call),
                  _textInput(
                      controller: _passwordController,
                      hint: "Password",
                      icon: Icons.vpn_key,
                      isPassword: true),
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
                          style: TextStyle(color: AppColors.orangeColors),
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

  Widget _textInput(
      {required TextEditingController controller,
      required String hint,
      required IconData icon,
      bool isPassword = false}) {
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
