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
  ProfileState _state = ProfileState.loading;
  ProfileState get state => _state;

  Usuario? _usuario;
  List<Evento> _eventosInscritos = [];
  List<Donaciones> _donaciones = [];
  EstadisticasUsuario? _estadisticas;
  EstadisticasUsuario? _estadisticasAnteriores;
  String _nombreFacultad = '';
  String _nombreEscuela = '';
  String _nombreRol = 'Cargando...';
  
  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  Usuario? get usuario => _usuario;
  List<Evento> get eventosInscritos => _eventosInscritos;
  List<Donaciones> get donaciones => _donaciones;
  EstadisticasUsuario? get estadisticas => _estadisticas;
  String get nombreFacultad => _nombreFacultad;
  String get nombreEscuela => _nombreEscuela;
  String get nombreRol => _nombreRol;

  DateTime? _lastLoadTime;
  static const Duration _cacheTimeout = Duration(minutes: 5);

  Future<void> loadProfileData({bool forceRefresh = false}) async {
    if (!forceRefresh && _lastLoadTime != null) {
      if (DateTime.now().difference(_lastLoadTime!) < _cacheTimeout) {
        return;
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
      
      _calcularEstadisticas();
      
      _lastLoadTime = DateTime.now();
      _setState(ProfileState.loaded);
      
    } catch (e) {
      _errorMessage = e.toString();
      _setState(ProfileState.error);
    }
  }

  void _calcularEstadisticas() {
    final userId = FirebaseAuth.instance.currentUser?.uid ?? '';
    
    _estadisticasAnteriores = _estadisticas;
    
    _estadisticas = EstadisticasUsuario.calcular(
      eventos: _eventosInscritos,
      donaciones: _donaciones,
      userId: userId,
    );
  }

  Future<void> updateProfilePhoto(String newPhotoUrl) async {
    if (_usuario != null) {
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

  void clearCache() {
    _lastLoadTime = null;
  }

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
