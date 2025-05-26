import 'package:flutter/material.dart';
import '../services/firebase_auth_services.dart';
import '../models/usuario.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../functions/cambiar_foto.dart';
import '../functions/cerrar_sesion.dart'; // Importa la función correctamente
import 'login_s.dart'; // Importa tu pantalla de login
import '../functions/cambiar_contraseña.dart'; // Asegúrate de importar tu función

class PerfilScreen extends StatefulWidget {
  @override
  State<PerfilScreen> createState() => _PerfilScreenState();
}

class _PerfilScreenState extends State<PerfilScreen> {
  Usuario? usuario;

  @override
  void initState() {
    super.initState();
    _loadUsuario();
  }

  Future<void> _loadUsuario() async {
    final authService = AuthService();
    final userData = await authService.getUserData();
    if (userData != null) {
      setState(() {
        usuario = Usuario.fromMap(userData.data() as Map<String, dynamic>);
      });
    }
  }

  Future<void> _cambiarClave() async {
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
                          // Reautenticación
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

  Future<void> _cambiarFoto() async {
    await cambiarFotoPerfil();
    await _loadUsuario();
  }

  Future<void> _cerrarSesion() async {
    await cerrarSesion();
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => LoginScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Perfil'),
        backgroundColor: Colors.orange.shade700,
      ),
      body: usuario == null
          ? Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  // Foto de perfil
                  Center(
                    child: CircleAvatar(
                      radius: 60,
                      backgroundImage: (usuario!.fotoPerfil.isNotEmpty)
                          ? NetworkImage(usuario!.fotoPerfil)
                          : AssetImage('assets/images/default_avatar.png') as ImageProvider,
                      child: Align(
                        alignment: Alignment.bottomRight,
                        child: GestureDetector(
                          onTap: _cambiarFoto,
                          child: CircleAvatar(
                            backgroundColor: Colors.white,
                            radius: 18,
                            child: Icon(
                              Icons.camera_alt,
                              size: 20,
                              color: Colors.orange.shade700,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 24),
                  // Nombre y correo
                  ListTile(
                    leading: Icon(Icons.person, color: Colors.orange.shade700),
                    title: Text(usuario!.nombre),
                    subtitle: Text(usuario!.correo),
                    trailing: Icon(Icons.edit),
                    onTap: () {
                      // Acción para editar nombre
                    },
                  ),
                  Divider(),
                  // Cambiar clave
                  ListTile(
                    leading: Icon(Icons.lock, color: Colors.orange.shade700),
                    title: Text('Cambiar contraseña'),
                    trailing: Icon(Icons.edit),
                    onTap: _cambiarClave,
                  ),
                  Divider(),
                  Spacer(),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange.shade700,
                      minimumSize: Size(double.infinity, 48),
                    ),
                    onPressed: _cerrarSesion,
                    icon: Icon(Icons.logout),
                    label: Text('Cerrar sesión'),
                  ),
                ],
              ),
            ),
    );
  }
}