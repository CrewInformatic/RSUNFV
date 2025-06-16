import 'package:flutter/material.dart';
import '../services/firebase_auth_services.dart';
import '../models/usuario.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../functions/cambiar_foto.dart';
import '../functions/cerrar_sesion.dart';
import '../functions/cambiar_nombre.dart';
import '../services/cloudinary_services.dart';

class PerfilScreen extends StatefulWidget {
  const PerfilScreen({super.key});

  @override
  State<PerfilScreen> createState() => _PerfilScreenState();
}

class _PerfilScreenState extends State<PerfilScreen> {
  Usuario? usuario;
  bool isLoading = false;

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
    final formKey = GlobalKey<FormState>();
    String antiguaClave = '';
    String nuevaClave = '';
    String repetirClave = '';
    bool isLoading = false;
    final scaffoldContext = context;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) => AlertDialog(
            title: Text('Cambiar contraseña'),
            content: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    obscureText: true,
                    decoration: InputDecoration(labelText: 'Contraseña actual'),
                    onChanged: (v) => antiguaClave = v,
                    validator: (v) => v == null || v.isEmpty
                        ? 'Ingrese su contraseña actual'
                        : null,
                  ),
                  TextFormField(
                    obscureText: true,
                    decoration: InputDecoration(labelText: 'Nueva contraseña'),
                    onChanged: (v) => nuevaClave = v,
                    validator: (v) =>
                        v == null || v.length < 6 ? 'Mínimo 6 caracteres' : null,
                  ),
                  TextFormField(
                    obscureText: true,
                    decoration:
                        InputDecoration(labelText: 'Repetir nueva contraseña'),
                    onChanged: (v) => repetirClave = v,
                    validator: (v) =>
                        v != nuevaClave ? 'Las contraseñas no coinciden' : null,
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
                        if (formKey.currentState!.validate()) {
                          setState(() => isLoading = true);
                          try {
                            final user = FirebaseAuth.instance.currentUser;
                            final email = user?.email;
                            if (user != null && email != null) {
                              // Reautenticación
                              final cred = EmailAuthProvider.credential(
                                  email: email, password: antiguaClave);
                              await user.reauthenticateWithCredential(cred);

                              // Cambia la contraseña usando tu servicio
                              final authService = AuthService();
                              final ok = await authService.cambiarPassword(nuevaClave);

                              Navigator.pop(context);
                              ScaffoldMessenger.of(scaffoldContext).showSnackBar(
                                SnackBar(
                                  content: Text(ok
                                      ? 'Contraseña actualizada'
                                      : 'No se pudo cambiar la contraseña'),
                                ),
                              );
                            }
                          } catch (e) {
                            setState(() => isLoading = false);
                            ScaffoldMessenger.of(scaffoldContext).showSnackBar(
                              SnackBar(content: Text('Error: ${e.toString()}')),
                            );
                          }
                        }
                      },
                child: isLoading
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : Text('Guardar'),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildProfileImage() {
    return Stack(
      children: [
        CircleAvatar(
          radius: 60,
          backgroundImage: NetworkImage(
            usuario?.fotoPerfil.isNotEmpty == true
                ? usuario!.fotoPerfil
                : CloudinaryService.defaultAvatarUrl
          ),
          backgroundColor: Colors.grey[200],
        ),
        Positioned(
          bottom: 0,
          right: 0,
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
        if (isLoading)
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black26,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Future<void> _cambiarFoto() async {
    setState(() => isLoading = true);
    try {
      final newHash = await cambiarFotoPerfil();
      if (newHash != null) {
        await _loadUsuario();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al cambiar la foto: ${e.toString()}')),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _cambiarNombre() async {
    final formKey = GlobalKey<FormState>();
    String nuevoNombre = usuario?.nombreUsuario ?? '';
    bool isLoading = false;
    final scaffoldContext = context;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) => AlertDialog(
            title: Text('Cambiar nombre'),
            content: Form(
              key: formKey,
              child: TextFormField(
                initialValue: nuevoNombre,
                decoration: InputDecoration(labelText: 'Nuevo nombre'),
                onChanged: (v) => nuevoNombre = v,
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Ingrese un nombre' : null,
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
                        if (formKey.currentState!.validate()) {
                          setState(() => isLoading = true);
                          final ok = await cambiarNombre(nuevoNombre.trim());
                          Navigator.pop(context);
                          if (ok) {
                            await _loadUsuario();
                            ScaffoldMessenger.of(scaffoldContext).showSnackBar(
                              SnackBar(content: Text('Nombre actualizado')),
                            );
                          } else {
                            ScaffoldMessenger.of(scaffoldContext).showSnackBar(
                              SnackBar(content: Text('No se pudo cambiar el nombre')),
                            );
                          }
                        }
                      },
                child: isLoading
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : Text('Guardar'),
              ),
            ],
          ),
        );
      },
    );
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
                  Center(child: _buildProfileImage()),
                  SizedBox(height: 24),
                  ListTile(
                    leading: Icon(Icons.person, color: Colors.orange.shade700),
                    title: Text(usuario!.nombreUsuario),
                    subtitle: Text(usuario!.correo),
                    trailing: Icon(Icons.edit),
                    onTap: _cambiarNombre,
                  ),
                  Divider(),
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
                    onPressed: () async {
                      await cerrarSesion();
                      Navigator.pushReplacementNamed(context, '/login');
                    },
                    icon: Icon(Icons.logout),
                    label: Text('Cerrar sesión'),
                  ),
                ],
              ),
            ),
    );
  }
}