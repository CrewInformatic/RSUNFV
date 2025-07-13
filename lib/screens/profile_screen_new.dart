import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/usuario.dart';
import '../models/evento.dart';
import '../models/donaciones.dart';
import '../models/estadisticas_usuario.dart';

enum ProfileState { loading, loaded, error, empty }

class ProfileScreenNew extends StatefulWidget {
  const ProfileScreenNew({super.key});

  @override
  State<ProfileScreenNew> createState() => _ProfileScreenNewState();
}

class _ProfileScreenNewState extends State<ProfileScreenNew> {
  final _logger = Logger();
  
  ProfileState _state = ProfileState.loading;
  String? _errorMessage;
  
  Usuario? _usuario;
  List<Evento> _eventosInscritos = [];
  List<Donaciones> _donaciones = [];
  EstadisticasUsuario? _estadisticas;
  String _nombreFacultad = '';
  String _nombreEscuela = '';
  String _nombreRol = '';
  
  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    if (!mounted) return;
    
    setState(() {
      _state = ProfileState.loading;
      _errorMessage = null;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        setState(() {
          _state = ProfileState.empty;
          _errorMessage = 'Usuario no autenticado';
        });
        return;
      }

      final userDoc = await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(user.uid)
          .get();
      
      if (userDoc.exists) {
        _usuario = Usuario.fromMap(userDoc.data()!);
        
        await Future.wait([
          _loadEventosInscritos(user.uid),
          _loadDonaciones(user.uid),
          _loadRelatedData(),
        ]);
        
        _calcularEstadisticas();
        
        setState(() {
          _state = ProfileState.loaded;
        });
      } else {
        setState(() {
          _state = ProfileState.empty;
          _errorMessage = 'No se encontraron datos del usuario';
        });
      }
    } catch (e) {
      _logger.e('Error cargando perfil: $e');
      setState(() {
        _state = ProfileState.error;
        _errorMessage = e.toString();
      });
    }
  }

  Future<void> _loadEventosInscritos(String userId) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('eventos')
          .where('voluntariosInscritos', arrayContains: userId)
          .get();
      
      _eventosInscritos = snapshot.docs
          .map((doc) => Evento.fromFirestore(doc))
          .toList();
    } catch (e) {
      _logger.e('Error cargando eventos: $e');
    }
  }

  Future<void> _loadDonaciones(String userId) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('donaciones')
          .where('idUsuarioDonador', isEqualTo: userId)
          .get();
      
      _donaciones = snapshot.docs
          .map((doc) => Donaciones.fromMap({
                'idDonaciones': doc.id,
                ...doc.data(),
              }))
          .toList();
    } catch (e) {
      _logger.e('Error cargando donaciones: $e');
    }
  }

  Future<void> _loadRelatedData() async {
    if (_usuario == null) return;
    
    try {
      final futures = <Future<dynamic>>[];
      
      if (_usuario!.idRol.isNotEmpty) {
        futures.add(FirebaseFirestore.instance
            .collection('roles')
            .where('idRol', isEqualTo: _usuario!.idRol)
            .limit(1)
            .get());
      } else {
        futures.add(Future.value(null));
      }
      
      if (_usuario!.facultadID.isNotEmpty) {
        futures.add(FirebaseFirestore.instance
            .collection('facultad')
            .where('idFacultad', isEqualTo: _usuario!.facultadID)
            .limit(1)
            .get());
      } else {
        futures.add(Future.value(null));
      }
      
      if (_usuario!.escuelaId.isNotEmpty) {
        futures.add(FirebaseFirestore.instance
            .collection('escuela')
            .where('idEscuela', isEqualTo: _usuario!.escuelaId)
            .limit(1)
            .get());
      } else {
        futures.add(Future.value(null));
      }
      
      final results = await Future.wait(futures);
      
      if (results[0] != null && (results[0] as QuerySnapshot).docs.isNotEmpty) {
        final data = (results[0] as QuerySnapshot).docs.first.data() as Map<String, dynamic>;
        _nombreRol = data['nombre'] ?? 'Sin rol';
      } else {
        _nombreRol = 'Sin rol';
      }
      
      if (results[1] != null && (results[1] as QuerySnapshot).docs.isNotEmpty) {
        final data = (results[1] as QuerySnapshot).docs.first.data() as Map<String, dynamic>;
        _nombreFacultad = data['nombreFacultad'] ?? 'No asignada';
      } else {
        _nombreFacultad = 'No asignada';
      }
      
      if (results[2] != null && (results[2] as QuerySnapshot).docs.isNotEmpty) {
        final data = (results[2] as QuerySnapshot).docs.first.data() as Map<String, dynamic>;
        _nombreEscuela = data['nombreEscuela'] ?? 'No asignada';
      } else {
        _nombreEscuela = 'No asignada';
      }
    } catch (e) {
      _logger.e('Error cargando datos relacionados: $e');
    }
  }

  void _calcularEstadisticas() {
    final userId = FirebaseAuth.instance.currentUser?.uid ?? '';
    _estadisticas = EstadisticasUsuario.calcular(
      eventos: _eventosInscritos,
      donaciones: _donaciones,
      userId: userId,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text('Mi Perfil'),
        backgroundColor: Colors.orange.shade700,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _loadProfileData(),
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    switch (_state) {
      case ProfileState.loading:
        return _buildLoadingState();
      case ProfileState.loaded:
        return _buildLoadedState();
      case ProfileState.error:
        return _buildErrorState();
      case ProfileState.empty:
        return _buildEmptyState();
    }
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.orange.shade700),
          ),
          const SizedBox(height: 16),
          Text(
            'Cargando perfil...',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Error al cargar el perfil',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.red[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage ?? 'Ha ocurrido un error inesperado',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => _loadProfileData(),
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange.shade700,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.person_outline,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No se encontraron datos del perfil',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => _loadProfileData(),
            child: const Text('Recargar'),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadedState() {
    return RefreshIndicator(
      onRefresh: _loadProfileData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              
              Center(
                child: _buildProfileImage(),
              ),
              
              const SizedBox(height: 20),
              
              _buildEstadisticasCard(),
              
              const SizedBox(height: 16),
              
              _buildUserDataCard(),
              
              const SizedBox(height: 20),
              
              if (_eventosInscritos.isNotEmpty)
                _buildEventosCard(),
              
              const SizedBox(height: 20),
              
              if (_donaciones.isNotEmpty)
                _buildDonacionesCard(),
              
              const SizedBox(height: 20),
              
              _buildLogoutButton(),
              
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileImage() {
    final photoUrl = _usuario?.fotoPerfil ?? '';
    
    return GestureDetector(
      onTap: () => _showPhotoOptions(),
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: Colors.orange.shade700,
            width: 3,
          ),
        ),
        child: CircleAvatar(
          radius: 60,
          backgroundColor: Colors.orange.shade100,
          backgroundImage: photoUrl.isNotEmpty ? NetworkImage(photoUrl) : null,
          child: photoUrl.isEmpty 
            ? Icon(
                Icons.person,
                size: 60,
                color: Colors.orange.shade700,
              )
            : null,
        ),
      ),
    );
  }

  Widget _buildEstadisticasCard() {
    if (_estadisticas == null) return const SizedBox.shrink();
    
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.analytics, color: Colors.orange.shade700),
                const SizedBox(width: 8),
                const Text(
                  'Estadísticas',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem('Eventos', _estadisticas!.eventosInscritos.toString(), Icons.event),
                _buildStatItem('Donaciones', _estadisticas!.donacionesRealizadas.toString(), Icons.favorite),
                _buildStatItem('Puntos', _estadisticas!.puntosTotales.toString(), Icons.star),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.orange.shade700, size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.orange.shade700,
          ),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
      ],
    );
  }

  Widget _buildUserDataCard() {
    if (_usuario == null) return const SizedBox.shrink();
    
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.person_outline, color: Colors.orange.shade700),
                const SizedBox(width: 8),
                const Text(
                  'Información Personal',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildDataRow('Nombre', _usuario!.nombre, Icons.badge),
            _buildDataRow('Email', _usuario!.email, Icons.email),
            _buildDataRow('Teléfono', _usuario!.celular ?? 'No especificado', Icons.phone),
            _buildDataRow('Rol', _nombreRol, Icons.work),
            _buildDataRow('Facultad', _nombreFacultad, Icons.school),
            _buildDataRow('Escuela', _nombreEscuela, Icons.apartment),
          ],
        ),
      ),
    );
  }

  Widget _buildDataRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          const SizedBox(width: 12),
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(
              value.isNotEmpty ? value : 'No especificado',
              style: TextStyle(
                color: value.isNotEmpty ? Colors.black87 : Colors.grey,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEventosCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.event, color: Colors.orange.shade700),
                const SizedBox(width: 8),
                Text(
                  'Eventos Inscritos (${_eventosInscritos.length})',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...(_eventosInscritos.take(3).map((evento) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4.0),
              child: Row(
                children: [
                  Icon(Icons.circle, size: 8, color: Colors.orange.shade700),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      evento.titulo,
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                ],
              ),
            ))),
            if (_eventosInscritos.length > 3)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  'Y ${_eventosInscritos.length - 3} más...',
                  style: TextStyle(color: Colors.grey[600], fontStyle: FontStyle.italic),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDonacionesCard() {
    final totalMonto = _donaciones.fold<double>(
      0.0,
      (total, donacion) => total + donacion.monto,
    );
    
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.favorite, color: Colors.orange.shade700),
                const SizedBox(width: 8),
                const Text(
                  'Donaciones',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem('Total', _donaciones.length.toString(), Icons.volunteer_activism),
                _buildStatItem('Monto', 'S/ ${totalMonto.toStringAsFixed(2)}', Icons.attach_money),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogoutButton() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: _cerrarSesion,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.logout, color: Colors.red),
              const SizedBox(width: 8),
              const Text(
                'Cerrar Sesión',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showPhotoOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Cambiar foto de perfil',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Tomar foto'),
              onTap: () {
                Navigator.pop(context);
                _showMessage('Funcionalidad de cámara no implementada');
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Elegir de galería'),
              onTap: () {
                Navigator.pop(context);
                _showMessage('Funcionalidad de galería no implementada');
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _cerrarSesion() async {
    try {
      await FirebaseAuth.instance.signOut();
      if (mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
      }
    } catch (e) {
      _logger.e('Error cerrando sesión: $e');
      _showMessage('Error al cerrar sesión: ${e.toString()}');
    }
  }

  void _showMessage(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.orange.shade700,
        ),
      );
    }
  }
}
