import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/firebase_auth_services.dart';
import '../models/usuario.dart';
import '../models/evento.dart';
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
  List<Evento> eventosInscritos = [];
  String nombreFacultad = '';
  String nombreEscuela = '';
  String tallaNombre = '';
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadUsuario();
    _loadEventosInscritos();
  }

  Future<void> _loadEventosInscritos() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    try {
      final eventosSnapshot = await FirebaseFirestore.instance
          .collection('eventos')
          .where('voluntariosInscritos', arrayContains: userId)
          .get();

      setState(() {
        eventosInscritos = eventosSnapshot.docs
            .map((doc) => Evento.fromFirestore(doc))
            .toList();
      });
    } catch (e) {
      print('Error cargando eventos: $e');
    }
  }

  Future<void> _loadUsuario() async {
    setState(() => isLoading = true);
    try {
      final authService = AuthService();
      final userData = await authService.getUserData();
      if (userData != null && mounted) {
        setState(() {
          usuario = Usuario.fromMap(userData.data() as Map<String, dynamic>);
        });
        await _loadRelatedData();
      }
    } catch (e) {
      print('Error cargando usuario: $e');
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  Future<void> _loadRelatedData() async {
    if (usuario == null) return;

    try {
      setState(() => isLoading = true);

      // Cargar facultad
      if (usuario!.facultadID.isNotEmpty) {
        final facultadDoc = await FirebaseFirestore.instance
            .collection('facultad')
            .where('idFacultad', isEqualTo: usuario!.facultadID)
            .get();
        
        if (facultadDoc.docs.isNotEmpty) {
          setState(() {
            nombreFacultad = facultadDoc.docs.first.data()['nombreFacultad'] ?? 'No registrada';
          });
          print('Facultad encontrada: $nombreFacultad'); 
        } else {
          print('No se encontró la facultad con ID: ${usuario!.facultadID}'); 
        }
      }

      // Cargar escuela
      if (usuario!.escuelaId.isNotEmpty) {
        final escuelaDoc = await FirebaseFirestore.instance
            .collection('escuela')
            .where('idEscuela', isEqualTo: usuario!.escuelaId)
            .get();
        
        if (escuelaDoc.docs.isNotEmpty) {
          setState(() {
            nombreEscuela = escuelaDoc.docs.first.data()['nombreEscuela'] ?? 'No registrada';
          });
          print('Escuela encontrada: $nombreEscuela');
        } else {
          print('No se encontró la escuela con ID: ${usuario!.escuelaId}'); 
        }
      }

      // Mapeo de tallas
      final Map<String, String> tallasMap = {
        'XS': 'Extra Small (XS)',
        'S': 'Small (S)',
        'M': 'Medium (M)',
        'L': 'Large (L)',
        'XL': 'Extra Large (XL)',
        'XXL': 'Double Extra Large (XXL)',
      };

      // Cargar talla
      if (usuario!.poloTallaID.isNotEmpty) {
        setState(() {
          tallaNombre = tallasMap[usuario!.poloTallaID] ?? 'Talla no especificada';
        });
      }

    } catch (e) {
      print('Error cargando datos relacionados: $e');
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
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

  Widget _buildUserDataCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Información Personal',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.orange.shade700,
              ),
            ),
            const Divider(),
            _buildInfoRow('Código', usuario?.codigoUsuario ?? 'No registrado'),
            _buildInfoRow('Nombres', usuario?.nombreUsuario ?? 'No registrado'),
            _buildInfoRow('Apellidos', usuario?.apellidoUsuario ?? 'No registrado'),
            _buildInfoRow('Email', usuario?.correo ?? 'No registrado'),
            _buildInfoRow('Edad', '${usuario?.edad ?? 'No registrado'} años'),
            _buildInfoRow('Ciclo', usuario?.ciclo ?? 'No registrado'),
            _buildInfoRow('Facultad', nombreFacultad),
            _buildInfoRow('Escuela', nombreEscuela),
            _buildInfoRow('Talla de Polo', tallaNombre),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w500,
              color: Colors.grey,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEventosInscritos() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            'Mis Eventos',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.orange.shade700,
            ),
          ),
        ),
        SizedBox(
          height: 200,
          child: eventosInscritos.isEmpty
              ? Center(
                  child: Text('No te has inscrito a ningún evento aún'),
                )
              : ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: eventosInscritos.length,
                  itemBuilder: (context, index) {
                    final evento = eventosInscritos[index];
                    return Container(
                      width: 300,
                      margin: const EdgeInsets.all(8),
                      child: Card(
                        elevation: 4,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              height: 100,
                              decoration: BoxDecoration(
                                image: DecorationImage(
                                  image: NetworkImage(evento.foto),
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    evento.titulo,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  Text(
                                    'Fecha: ${evento.fechaInicio}',
                                    style: TextStyle(color: Colors.grey[600]),
                                  ),
                                  Text(
                                    evento.ubicacion,
                                    style: TextStyle(color: Colors.grey[600]),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildEstadisticasCard() {
    double totalHoras = 0;
    int eventosCompletados = 0;
    int eventosPendientes = 0;
    int eventosEnProceso = 0;

    // Calcular estadísticas
    for (var evento in eventosInscritos) {
      switch (evento.estado.toLowerCase()) {
        case 'finalizado':
          eventosCompletados++;
          try {
            final horaInicio = evento.horaInicio.split(':');
            final horaFin = evento.horaFin.split(':');
            
            final inicio = TimeOfDay(
              hour: int.parse(horaInicio[0]), 
              minute: int.parse(horaInicio[1])
            );
            final fin = TimeOfDay(
              hour: int.parse(horaFin[0]), 
              minute: int.parse(horaFin[1])
            );

            final duracion = ((fin.hour - inicio.hour) * 60 + 
                            (fin.minute - inicio.minute)) / 60.0;
            totalHoras += duracion;
          } catch (e) {
            print('Error calculando horas: $e');
          }
          break;
        case 'en proceso':
          eventosEnProceso++;
          break;
        case 'pendiente':
          eventosPendientes++;
          break;
      }
    }

    return Card(
      elevation: 4,
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Mis Estadísticas',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange.shade700,
                  ),
                ),
                Icon(
                  Icons.emoji_events,
                  color: Colors.orange.shade700,
                  size: 28,
                ),
              ],
            ),
            const Divider(),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildEstadisticaItem(
                  icon: Icons.event,
                  value: eventosInscritos.length.toString(),
                  label: 'Total\nEventos',
                ),
                _buildEstadisticaItem(
                  icon: Icons.check_circle,
                  value: eventosCompletados.toString(),
                  label: 'Completados',
                  color: Colors.green,
                ),
                _buildEstadisticaItem(
                  icon: Icons.pending_actions,
                  value: eventosPendientes.toString(),
                  label: 'Pendientes',
                  color: Colors.orange,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildEstadisticaItem(
                  icon: Icons.access_time,
                  value: totalHoras.toStringAsFixed(1),
                  label: 'Horas\nTotales',
                  color: Colors.blue,
                ),
                _buildEstadisticaItem(
                  icon: Icons.run_circle,
                  value: eventosEnProceso.toString(),
                  label: 'En Proceso',
                  color: Colors.purple,
                ),
              ],
            ),
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: eventosCompletados / 
                       (eventosInscritos.isEmpty ? 1 : eventosInscritos.length),
                backgroundColor: Colors.grey[200],
                color: Colors.orange.shade700,
                minHeight: 10,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Progreso: ${((eventosCompletados / 
                (eventosInscritos.isEmpty ? 1 : eventosInscritos.length)) * 
                100).toStringAsFixed(0)}%',
              style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEstadisticaItem({
    required IconData icon,
    required String value,
    required String label,
    Color? color,
  }) {
    return Column(
      children: [
        Icon(
          icon,
          size: 32,
          color: color ?? Colors.orange.shade700,
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi Perfil'),
        backgroundColor: Colors.orange.shade700,
      ),
      body: usuario == null
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  Center(child: _buildProfileImage()),
                  const SizedBox(height: 20),
                  _buildEstadisticasCard(), // Agregar estadísticas aquí
                  _buildUserDataCard(),
                  const SizedBox(height: 20),
                  _buildEventosInscritos(),
                  const SizedBox(height: 20),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange.shade700,
                        minimumSize: const Size(double.infinity, 48),
                      ),
                      onPressed: () async {
                        await cerrarSesion();
                        if (mounted) {
                          Navigator.pushReplacementNamed(context, '/login');
                        }
                      },
                      icon: const Icon(Icons.logout),
                      label: const Text('Cerrar sesión'),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}