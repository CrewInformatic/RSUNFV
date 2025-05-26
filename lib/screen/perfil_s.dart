import 'package:flutter/material.dart';
import '../services/firebase_auth_services.dart';
import '../models/usuario.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../functions/cambiar_foto.dart'; // Importa tu función

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
    String nuevaClave = '';
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Cambiar contraseña'),
        content: Form(
          key: _formKey,
          child: TextFormField(
            obscureText: true,
            decoration: InputDecoration(labelText: 'Nueva contraseña'),
            validator: (value) {
              if (value == null || value.length < 6) {
                return 'La contraseña debe tener al menos 6 caracteres';
              }
              return null;
            },
            onChanged: (value) => nuevaClave = value,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (_formKey.currentState!.validate()) {
                try {
                  await FirebaseAuth.instance.currentUser!
                      .updatePassword(nuevaClave);
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Contraseña actualizada')),
                  );
                } catch (e) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: ${e.toString()}')),
                  );
                }
              }
            },
            child: Text('Guardar'),
          ),
        ],
      ),
    );
  }

  Future<void> _cambiarFoto() async {
    await cambiarFotoPerfil();
    await _loadUsuario(); // Refresca los datos para mostrar la nueva foto
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
                    onPressed: () {
                      
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