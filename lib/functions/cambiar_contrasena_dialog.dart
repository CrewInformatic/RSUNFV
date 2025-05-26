import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'cambiar_contraseña.dart';

Future<void> mostrarDialogoCambiarContrasena(BuildContext context) async {
  final _formKey = GlobalKey<FormState>();
  String actual = '';
  String nueva = '';
  String repetir = '';
  bool isLoading = false;

  await showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text('Cambiar contraseña'),
          content: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  obscureText: true,
                  decoration: InputDecoration(labelText: 'Contraseña actual'),
                  onChanged: (v) => actual = v,
                  validator: (v) => v == null || v.isEmpty ? 'Ingrese su contraseña actual' : null,
                ),
                SizedBox(height: 12),
                TextFormField(
                  obscureText: true,
                  decoration: InputDecoration(labelText: 'Nueva contraseña'),
                  onChanged: (v) => nueva = v,
                  validator: (v) => v == null || v.length < 6 ? 'Mínimo 6 caracteres' : null,
                ),
                SizedBox(height: 12),
                TextFormField(
                  obscureText: true,
                  decoration: InputDecoration(labelText: 'Repetir nueva contraseña'),
                  onChanged: (v) => repetir = v,
                  validator: (v) => v != nueva ? 'Las contraseñas no coinciden' : null,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: isLoading
                  ? null
                  : () async {
                      if (_formKey.currentState!.validate()) {
                        setState(() => isLoading = true);
                        try {
                          final user = FirebaseAuth.instance.currentUser;
                          final cred = EmailAuthProvider.credential(
                            email: user!.email!,
                            password: actual,
                          );
                          await user.reauthenticateWithCredential(cred);

                          final ok = await cambiarContrasena(nueva);
                          Navigator.pop(context);
                          if (ok) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Contraseña actualizada')),
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('No se pudo cambiar la contraseña')),
                            );
                          }
                        } on FirebaseAuthException catch (e) {
                          setState(() => isLoading = false);
                          String msg = 'Error';
                          if (e.code == 'wrong-password') {
                            msg = 'Contraseña actual incorrecta';
                          } else if (e.code == 'too-many-requests') {
                            msg = 'Demasiados intentos, intente más tarde';
                          }
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(msg)),
                          );
                        }
                      }
                    },
              child: isLoading
                  ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : Text('Guardar'),
            ),
          ],
        ),
      );
    },
  );
}