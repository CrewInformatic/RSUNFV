import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/usuario.dart';
import '../models/evento.dart';
import '../models/donaciones.dart';
import '../models/estadisticas_usuario.dart';

enum ProfileState { loading, loaded, error, empty }

class ProfileScreenSimple extends StatefulWidget {
  const ProfileScreenSimple({super.key});

  @override
  State<ProfileScreenSimple> createState() => _ProfileScreenSimpleState();
}

class _ProfileScreenSimpleState extends State<ProfileScreenSimple> {
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
        backgroundColor: const Color(0xFF2E7D32),
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
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2E7D32)),
          ),
          SizedBox(height: 16),
          Text(
            'Cargando perfil...',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: Colors.red[300],
          ),
          const SizedBox(height: 16),
          const Text(
            'Error al cargar el perfil',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            _errorMessage ?? 'Error desconocido',
            style: const TextStyle(fontSize: 14, color: Colors.grey),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => _loadProfileData(),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2E7D32),
              foregroundColor: Colors.white,
            ),
            child: const Text('Reintentar'),
          ),
        ],
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
          const Text(
            'Perfil no encontrado',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'No se pudo cargar la información del perfil',
            style: TextStyle(fontSize: 14, color: Colors.grey),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => _loadProfileData(),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2E7D32),
              foregroundColor: Colors.white,
            ),
            child: const Text('Reintentar'),
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
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildProfileImage(),
            const SizedBox(height: 24),
            
            _buildEstadisticasCard(),
            const SizedBox(height: 16),
            
            _buildUserDataCard(),
            const SizedBox(height: 16),
            
            if (_eventosInscritos.isNotEmpty)
              _buildEventosCard(),
            const SizedBox(height: 16),
            
            if (_donaciones.isNotEmpty)
              _buildDonacionesCard(),
            const SizedBox(height: 32),
            
            _buildLogoutButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileImage() {
    final photoUrl = _usuario?.fotoPerfil ?? '';
    
    return Center(
      child: CircleAvatar(
        radius: 60,
        backgroundColor: const Color(0xFF2E7D32),
        backgroundImage: photoUrl.isNotEmpty ? NetworkImage(photoUrl) : null,
        child: photoUrl.isEmpty 
          ? Text(
              _usuario?.nombre.isNotEmpty == true 
                ? _usuario!.nombre.substring(0, 1).toUpperCase()
                : '?',
              style: const TextStyle(fontSize: 48, color: Colors.white),
            )
          : null,
      ),
    );
  }

  Widget _buildEstadisticasCard() {
    if (_estadisticas == null) return const SizedBox.shrink();
    
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Estadísticas',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem('Eventos', _estadisticas!.eventosInscritos.toString()),
                _buildStatItem('Donaciones', _estadisticas!.donacionesRealizadas.toString()),
                _buildStatItem('Puntos', _estadisticas!.puntosTotales.toString()),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2E7D32),
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
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Información Personal',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildDataRow('Nombre', _usuario!.nombre),
            _buildDataRow('Email', _usuario!.email),
            _buildDataRow('Teléfono', _usuario!.celular ?? 'No especificado'),
            _buildDataRow('Rol', _nombreRol),
            _buildDataRow('Facultad', _nombreFacultad),
            _buildDataRow('Escuela', _nombreEscuela),
          ],
        ),
      ),
    );
  }

  Widget _buildDataRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Eventos Inscritos (${_eventosInscritos.length})',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ...(_eventosInscritos.take(3).map((evento) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4.0),
              child: Row(
                children: [
                  const Icon(Icons.event, size: 16, color: Color(0xFF2E7D32)),
                  const SizedBox(width: 8),
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
                  style: const TextStyle(color: Colors.grey),
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
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Donaciones',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem('Total', _donaciones.length.toString()),
                _buildStatItem('Monto', 'S/ ${totalMonto.toStringAsFixed(2)}'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogoutButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () => _cerrarSesion(),
        icon: const Icon(Icons.logout),
        label: const Text('Cerrar Sesión'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.red,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
