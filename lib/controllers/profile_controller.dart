import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/usuario.dart';
import '../models/evento.dart';
import '../models/donaciones.dart';
import '../models/estadisticas_usuario.dart';
import '../models/medalla.dart';
import '../services/profile_service.dart';

enum ProfileState { loading, loaded, error, empty }

class ProfileController extends ChangeNotifier {
  // Estado
  ProfileState _state = ProfileState.loading;
  ProfileState get state => _state;

  // Datos
  Usuario? _usuario;
  List<Evento> _eventosInscritos = [];
  List<Donaciones> _donaciones = [];
  EstadisticasUsuario? _estadisticas;
  EstadisticasUsuario? _estadisticasAnteriores;
  String _nombreFacultad = '';
  String _nombreEscuela = '';
  String _nombreRol = 'Cargando...';
  
  // Error handling
  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  // Getters
  Usuario? get usuario => _usuario;
  List<Evento> get eventosInscritos => _eventosInscritos;
  List<Donaciones> get donaciones => _donaciones;
  EstadisticasUsuario? get estadisticas => _estadisticas;
  String get nombreFacultad => _nombreFacultad;
  String get nombreEscuela => _nombreEscuela;
  String get nombreRol => _nombreRol;

  // Cache para evitar recargas innecesarias
  DateTime? _lastLoadTime;
  static const Duration _cacheTimeout = Duration(minutes: 5);

  /// Carga todos los datos del perfil de forma optimizada
  Future<void> loadProfileData({bool forceRefresh = false}) async {
    // Verificar cache si no es refresh forzado
    if (!forceRefresh && _lastLoadTime != null) {
      if (DateTime.now().difference(_lastLoadTime!) < _cacheTimeout) {
        return; // Usar datos del cache
      }
    }

    _setState(ProfileState.loading);
    _errorMessage = null;

    try {
      final profileData = await ProfileService.getProfileData();
      
      _usuario = profileData.usuario;
      _eventosInscritos = profileData.eventosInscritos;
      _donaciones = profileData.donaciones;
      _nombreFacultad = profileData.nombreFacultad;
      _nombreEscuela = profileData.nombreEscuela;
      _nombreRol = profileData.nombreRol;
      
      // Calcular estadísticas
      _calcularEstadisticas();
      
      _lastLoadTime = DateTime.now();
      _setState(ProfileState.loaded);
      
    } catch (e) {
      _errorMessage = e.toString();
      _setState(ProfileState.error);
    }
  }

  /// Calcula las estadísticas del usuario
  void _calcularEstadisticas() {
    final userId = FirebaseAuth.instance.currentUser?.uid ?? '';
    
    // Guardar estadísticas anteriores para comparar medallas
    _estadisticasAnteriores = _estadisticas;
    
    // Calcular nuevas estadísticas
    _estadisticas = EstadisticasUsuario.calcular(
      eventos: _eventosInscritos,
      donaciones: _donaciones,
      userId: userId,
    );
  }

  /// Actualiza la foto de perfil
  Future<void> updateProfilePhoto(String newPhotoUrl) async {
    if (_usuario != null) {
      // Crear nuevo usuario con foto actualizada
      _usuario = Usuario(
        idUsuario: _usuario!.idUsuario,
        nombreUsuario: _usuario!.nombreUsuario,
        apellidoUsuario: _usuario!.apellidoUsuario,
        codigoUsuario: _usuario!.codigoUsuario,
        fotoPerfil: newPhotoUrl,
        correo: _usuario!.correo,
        fechaNacimiento: _usuario!.fechaNacimiento,
        poloTallaID: _usuario!.poloTallaID,
        esAdmin: _usuario!.esAdmin,
        facultadID: _usuario!.facultadID,
        escuelaId: _usuario!.escuelaId,
        estadoActivo: _usuario!.estadoActivo,
        ciclo: _usuario!.ciclo,
        edad: _usuario!.edad,
        medallasIDs: _usuario!.medallasIDs,
        fechaRegistro: _usuario!.fechaRegistro,
        fechaModificacion: _usuario!.fechaModificacion,
        idRol: _usuario!.idRol,
        puntosJuego: _usuario!.puntosJuego,
        yape: _usuario!.yape,
        cuentaBancaria: _usuario!.cuentaBancaria,
        celular: _usuario!.celular,
        banco: _usuario!.banco,
      );
      notifyListeners();
    }
  }

  /// Refresca solo los eventos inscritos
  Future<void> refreshEventos() async {
    if (_usuario == null) return;
    
    try {
      _eventosInscritos = await ProfileService.getEventosInscritos(_usuario!.idUsuario);
      _calcularEstadisticas();
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Error al refrescar eventos: $e';
    }
  }

  /// Refresca solo las donaciones
  Future<void> refreshDonaciones() async {
    if (_usuario == null) return;
    
    try {
      _donaciones = await ProfileService.getDonacionesUsuario(_usuario!.idUsuario);
      _calcularEstadisticas();
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Error al refrescar donaciones: $e';
    }
  }

  /// Limpia el cache y fuerza una recarga
  void clearCache() {
    _lastLoadTime = null;
  }

  /// Verifica si hay nuevas medallas
  List<Medalla> getNewMedals() {
    if (_estadisticasAnteriores == null || _estadisticas == null) return [];
    
    final medallasAnteriores = _estadisticasAnteriores!.medallasObtenidas.map((m) => m.id).toSet();
    final medallasActuales = _estadisticas!.medallasObtenidas.map((m) => m.id).toSet();
    
    final nuevasMedallasIds = medallasActuales.difference(medallasAnteriores);
    
    return _estadisticas!.medallasObtenidas
        .where((medalla) => nuevasMedallasIds.contains(medalla.id))
        .toList();
  }

  void _setState(ProfileState newState) {
    _state = newState;
    notifyListeners();
  }

}
