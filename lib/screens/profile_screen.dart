﻿import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:logger/logger.dart';
import 'package:intl/intl.dart';
import '../services/firebase_auth_services.dart';
import '../services/medals_service.dart';
import '../services/statistics_service.dart';
import '../services/donations_service.dart';
import '../models/usuario.dart';
import '../models/evento.dart';
import '../models/donaciones.dart';
import '../models/estadisticas_usuario.dart';
import '../models/medalla.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../functions/cambiar_foto.dart';
import '../functions/cerrar_sesion.dart';
import '../services/cloudinary_services.dart';
import '../core/constants/app_routes.dart';

class PerfilScreen extends StatefulWidget {
  const PerfilScreen({super.key});

  @override
  State<PerfilScreen> createState() => _PerfilScreenState();
}

class _PerfilScreenState extends State<PerfilScreen> {
  final _logger = Logger();
  
  DateTime? _lastLoadTime;
  static const Duration _cacheTimeout = Duration(minutes: 5);
  
  Usuario? usuario;
  List<Evento> eventosInscritos = [];
  List<Donaciones> donaciones = [];
  EstadisticasUsuario? estadisticas;
  EstadisticasUsuario? estadisticasAnteriores;
  String nombreFacultad = '';
  String nombreEscuela = '';
  String tallaNombre = '';
  bool isLoading = false;
  String nombreRol = 'Cargando...'; 
  List<Medalla> nuevasMedallas = [];
  bool _disposed = false;
  
  bool _isEditMode = false;
  final _nombreController = TextEditingController();
  final _apellidosController = TextEditingController();
  final _cicloController = TextEditingController();
  final _edadController = TextEditingController();
  bool _isSaving = false;
  
  @override
  void initState() {
    super.initState();
    _disposed = false;
    
    Future.microtask(() {
      if (!_disposed) {
        _loadAllData();
      }
    });
  }

  Future<void> _loadAllData({bool forceRefresh = false}) async {
    if (!forceRefresh && _lastLoadTime != null) {
      if (DateTime.now().difference(_lastLoadTime!) < _cacheTimeout) {
        return;
      }
    }

    await Future.wait([
      _loadUsuario(),
      _loadDatosDesdeBaseDatos(),
    ]);
    
    _lastLoadTime = DateTime.now();
  }

  /// Carga donaciones, estadísticas y medallas desde la base de datos
  Future<void> _loadDatosDesdeBaseDatos() async {
    if (!mounted) return;
    
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    setState(() => isLoading = true);

    try {
      // Cargar datos en paralelo usando los nuevos servicios
      final results = await Future.wait([
        DonationsService.getDonacionesUsuario(userId: userId),
        StatisticsService.getEstadisticasUsuario(userId: userId),
        MedalsService.getMedallasUsuario(userId: userId),
        MedalsService.getMedallasDisponibles(),
        _loadEventosInscritos(userId), // Agregar carga de eventos
      ]);

      if (!mounted) return;

      setState(() {
        donaciones = results[0] as List<Donaciones>;
        estadisticas = results[1] as EstadisticasUsuario;
        eventosInscritos = results[4] as List<Evento>; // Asignar eventos cargados
        
        // Combinar medallas obtenidas con las disponibles
        final medallasObtenidas = results[2] as List<Medalla>;
        final medallasDisponibles = results[3] as List<Medalla>;
        
        // Actualizar estadísticas con medallas
        if (estadisticas != null) {
          estadisticas = EstadisticasUsuario(
            eventosInscritos: estadisticas!.eventosInscritos,
            eventosCompletados: estadisticas!.eventosCompletados,
            eventosPendientes: estadisticas!.eventosPendientes,
            eventosEnProceso: estadisticas!.eventosEnProceso,
            horasTotales: estadisticas!.horasTotales,
            rachaActual: estadisticas!.rachaActual,
            mejorRacha: estadisticas!.mejorRacha,
            donacionesRealizadas: estadisticas!.donacionesRealizadas,
            montoTotalDonado: estadisticas!.montoTotalDonado,
            medallasObtenidas: medallasObtenidas,
            medallasDisponibles: medallasDisponibles,
            puntosTotales: estadisticas!.puntosTotales,
            nivelActual: estadisticas!.nivelActual,
            progresoNivelSiguiente: estadisticas!.progresoNivelSiguiente,
          );
        }
      });

      // Verificar nuevas medallas
      await _verificarNuevasMedallasDesdeBaseDatos();

    } catch (e) {
      if (mounted) {
        _logger.e('Error cargando datos desde la base de datos: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error cargando datos: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  /// Método para cargar eventos en los que el usuario está inscrito
  Future<List<Evento>> _loadEventosInscritos(String userId) async {
    try {
      _logger.d('Cargando eventos inscritos para usuario: $userId');
      
      // Buscar eventos donde el usuario está en el array voluntariosInscritos
      final eventosSnapshot = await FirebaseFirestore.instance
          .collection('eventos')
          .where('voluntariosInscritos', arrayContains: userId)
          .get();

      _logger.d('Encontrados ${eventosSnapshot.docs.length} eventos donde el usuario está inscrito');

      if (eventosSnapshot.docs.isEmpty) {
        _logger.d('No se encontraron eventos donde el usuario esté inscrito');
        return [];
      }

      final List<Evento> eventos = [];

      for (final doc in eventosSnapshot.docs) {
        try {
          final data = doc.data();
          // Agregar el ID del documento si no está presente
          if (!data.containsKey('idEvento')) {
            data['idEvento'] = doc.id;
          }
          
          final evento = Evento.fromMap(data);
          eventos.add(evento);
          _logger.d('Evento cargado: ${evento.titulo} (Estado: ${evento.estado})');
        } catch (e) {
          _logger.w('Error procesando evento ${doc.id}: $e');
        }
      }

      // Ordenar por fecha (más recientes primero)
      eventos.sort((a, b) {
        try {
          final fechaA = DateTime.parse(a.fechaInicio);
          final fechaB = DateTime.parse(b.fechaInicio);
          return fechaB.compareTo(fechaA);
        } catch (e) {
          _logger.w('Error ordenando eventos por fecha: $e');
          return 0;
        }
      });
      
      _logger.d('Total de eventos cargados: ${eventos.length}');
      return eventos;
    } catch (e) {
      _logger.e('Error cargando eventos inscritos: $e');
      return [];
    }
  }

  Future<void> _verificarNuevasMedallasDesdeBaseDatos() async {
    if (estadisticas == null) return;

    try {
      final nuevasMedallasObtenidas = await MedalsService.verificarYOtorgarMedallas(
        eventosCompletados: estadisticas!.eventosCompletados,
        horasTotales: estadisticas!.horasTotales,
        rachaMaxima: estadisticas!.mejorRacha,
        donacionesRealizadas: estadisticas!.donacionesRealizadas,
        montoTotalDonado: estadisticas!.montoTotalDonado,
      );

      if (nuevasMedallasObtenidas.isNotEmpty && mounted) {
        setState(() {
          nuevasMedallas = nuevasMedallasObtenidas;
        });

        Future.delayed(const Duration(milliseconds: 500), () {
          _mostrarNotificacionMedallas();
        });

        // Recargar medallas después de otorgar nuevas
        await _recargarMedallas();
      }
    } catch (e) {
      _logger.e('Error verificando nuevas medallas: $e');
    }
  }

  /// Recarga las medallas del usuario
  Future<void> _recargarMedallas() async {
    try {
      final medallasObtenidas = await MedalsService.getMedallasUsuario();
      final medallasDisponibles = await MedalsService.getMedallasDisponibles();
      
      if (mounted && estadisticas != null) {
        setState(() {
          estadisticas = EstadisticasUsuario(
            eventosInscritos: estadisticas!.eventosInscritos,
            eventosCompletados: estadisticas!.eventosCompletados,
            eventosPendientes: estadisticas!.eventosPendientes,
            eventosEnProceso: estadisticas!.eventosEnProceso,
            horasTotales: estadisticas!.horasTotales,
            rachaActual: estadisticas!.rachaActual,
            mejorRacha: estadisticas!.mejorRacha,
            donacionesRealizadas: estadisticas!.donacionesRealizadas,
            montoTotalDonado: estadisticas!.montoTotalDonado,
            medallasObtenidas: medallasObtenidas,
            medallasDisponibles: medallasDisponibles,
            puntosTotales: estadisticas!.puntosTotales,
            nivelActual: estadisticas!.nivelActual,
            progresoNivelSiguiente: estadisticas!.progresoNivelSiguiente,
          );
        });
      }
    } catch (e) {
      _logger.e('Error recargando medallas: $e');
    }
  }

  /// Método migrado a los nuevos servicios dinámicos

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
      _logger.e('Error cargando usuario: $e');
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

      final futures = <Future<dynamic>>[];

      if (usuario!.idRol.isNotEmpty) {
        futures.add(
          FirebaseFirestore.instance
              .collection('roles')
              .where('idRol', isEqualTo: usuario!.idRol)
              .limit(1)
              .get()
        );
      } else {
        futures.add(Future.value(null));
      }

      if (usuario!.facultadID.isNotEmpty) {
        futures.add(
          FirebaseFirestore.instance
              .collection('facultad')
              .where('idFacultad', isEqualTo: usuario!.facultadID)
              .limit(1)
              .get()
        );
      } else {
        futures.add(Future.value(null));
      }

      if (usuario!.escuelaId.isNotEmpty) {
        futures.add(
          FirebaseFirestore.instance
              .collection('escuela')
              .where('idEscuela', isEqualTo: usuario!.escuelaId)
              .limit(1)
              .get()
        );
      } else {
        futures.add(Future.value(null));
      }

      final results = await Future.wait(futures);

      if (!mounted) return;

      if (results[0] != null && (results[0] as QuerySnapshot).docs.isNotEmpty) {
        final rolDoc = (results[0] as QuerySnapshot).docs.first;
        setState(() {
          final data = rolDoc.data() as Map<String, dynamic>;
          nombreRol = data['nombre'] ?? 'Sin rol asignado';
        });
      } else {
        setState(() {
          nombreRol = 'Voluntario';
        });
      }

      if (results[1] != null && (results[1] as QuerySnapshot).docs.isNotEmpty) {
        final facultadDoc = (results[1] as QuerySnapshot).docs.first;
        setState(() {
          final data = facultadDoc.data() as Map<String, dynamic>;
          nombreFacultad = data['nombreFacultad'] ?? 'No registrada';
        });
        _logger.d('Facultad encontrada: $nombreFacultad');
      } else {
        setState(() {
          nombreFacultad = 'No registrada';
        });
      }

      if (results[2] != null && (results[2] as QuerySnapshot).docs.isNotEmpty) {
        final escuelaDoc = (results[2] as QuerySnapshot).docs.first;
        setState(() {
          final data = escuelaDoc.data() as Map<String, dynamic>;
          nombreEscuela = data['nombreEscuela'] ?? 'No registrada';
        });
        _logger.d('Escuela encontrada: $nombreEscuela');
      } else {
        setState(() {
          nombreEscuela = 'No registrada';
        });
      }

      final Map<String, String> tallasMap = {
        'XS': 'Extra Small (XS)',
        'S': 'Small (S)',
        'M': 'Medium (M)',
        'L': 'Large (L)',
        'XL': 'Extra Large (XL)',
        'XXL': 'Double Extra Large (XXL)',
      };

      if (usuario!.poloTallaID.isNotEmpty) {
        setState(() {
          tallaNombre = tallasMap[usuario!.poloTallaID] ?? 'Talla no especificada';
        });
      }

    } catch (e) {
      _logger.e('Error cargando datos relacionados: $e');
      if (mounted) {
        setState(() {
          nombreRol = 'Error al cargar rol';
          nombreFacultad = 'Error al cargar';
          nombreEscuela = 'Error al cargar';
        });
      }
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
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
    if (!mounted) return;
    final scaffoldContext = ScaffoldMessenger.of(context);
    
    setState(() => isLoading = true);
    try {
      final newHash = await cambiarFotoPerfil();
      if (newHash != null) {
        await _loadUsuario();
      }
    } catch (e) {
      if (!mounted) return;
      scaffoldContext.showSnackBar(
        SnackBar(content: Text('Error al cambiar la foto: ${e.toString()}')),
      );
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Información Personal',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange.shade700,
                  ),
                ),
                Row(
                  children: [
                    if (isLoading)
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.orange.shade700,
                          ),
                        ),
                      ),
                    if (!isLoading && !_isSaving)
                      IconButton(
                        icon: Icon(
                          _isEditMode ? Icons.close : Icons.edit,
                          color: Colors.orange.shade700,
                        ),
                        onPressed: () {
                          setState(() {
                            if (_isEditMode) {
                              _cancelEditing();
                            } else {
                              _startEditing();
                            }
                          });
                        },
                      ),
                    if (_isSaving)
                      const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                  ],
                ),
              ],
            ),
            const Divider(),
            _buildInfoRow('Código', usuario?.codigoUsuario ?? 'No registrado'),
            _buildEditableInfoRow('Nombres', usuario?.nombreUsuario ?? 'No registrado', _nombreController),
            _buildEditableInfoRow('Apellidos', usuario?.apellidoUsuario ?? 'No registrado', _apellidosController),
            _buildInfoRow('Correo', usuario?.correo ?? 'No registrado'),
            _buildInfoRow('Escuela', nombreEscuela),
            _buildInfoRow('Facultad', nombreFacultad),
            _buildInfoRow('Rol', nombreRol),
            _buildEditableInfoRow('Ciclo', usuario?.ciclo ?? 'No registrado', _cicloController),
            _buildEditableInfoRow('Edad', '${usuario?.edad ?? 'No registrado'}', _edadController, isSuffix: ' años'),
            
            if (_isEditMode) ...[
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _saveChanges,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange.shade700,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text(
                          'Guardar Cambios',
                          style: TextStyle(color: Colors.white),
                        ),
                ),
              ),
            ],
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
              fontSize: 16,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: label == 'Rol' ? Colors.orange.shade700 : Colors.grey[700],
              fontWeight: label == 'Rol' ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditableInfoRow(String label, String value, TextEditingController controller, {String isSuffix = ''}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 16,
            ),
          ),
          if (_isEditMode)
            SizedBox(
              width: 150,
              child: TextFormField(
                controller: controller,
                textAlign: TextAlign.right,
                style: const TextStyle(fontSize: 14),
                decoration: InputDecoration(
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(4),
                    borderSide: BorderSide(color: Colors.orange.shade700),
                  ),
                  suffixText: isSuffix.isNotEmpty ? isSuffix : null,
                ),
                keyboardType: label == 'Edad' || label == 'Ciclo' ? TextInputType.number : TextInputType.text,
              ),
            )
          else
            Text(
              value + (isSuffix.isNotEmpty && !value.contains('No registrado') ? isSuffix : ''),
              style: TextStyle(
                color: Colors.grey[700],
                fontWeight: FontWeight.normal,
              ),
            ),
        ],
      ),
    );
  }

  void _startEditing() {
    _isEditMode = true;
    _nombreController.text = usuario?.nombreUsuario ?? '';
    _apellidosController.text = usuario?.apellidoUsuario ?? '';
    _cicloController.text = usuario?.ciclo ?? '';
    _edadController.text = usuario?.edad.toString() ?? '';
  }

  void _cancelEditing() {
    _isEditMode = false;
    _nombreController.clear();
    _apellidosController.clear();
    _cicloController.clear();
    _edadController.clear();
  }

  Future<void> _saveChanges() async {
    if (_isSaving) return;

    setState(() {
      _isSaving = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('Usuario no autenticado');
      }

      if (_nombreController.text.trim().isEmpty) {
        _showErrorSnackBar('El nombre no puede estar vacío');
        return;
      }

      if (_apellidosController.text.trim().isEmpty) {
        _showErrorSnackBar('Los apellidos no pueden estar vacíos');
      return;
      }

      int? edad;
      if (_edadController.text.trim().isNotEmpty) {
        edad = int.tryParse(_edadController.text.trim());
        if (edad == null || edad < 1 || edad > 120) {
          _showErrorSnackBar('La edad debe ser un número válido entre 1 y 120');
          return;
        }
      }

      final updateData = <String, dynamic>{
        'nombreUsuario': _nombreController.text.trim(),
        'apellidoUsuario': _apellidosController.text.trim(),
        'ciclo': _cicloController.text.trim(),
      };

      if (edad != null) {
        updateData['edad'] = edad;
      }

      await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(user.uid)
          .update(updateData);

      if (usuario != null) {
        setState(() {
          usuario = Usuario(
            idUsuario: usuario!.idUsuario,
            nombreUsuario: _nombreController.text.trim(),
            apellidoUsuario: _apellidosController.text.trim(),
            correo: usuario!.correo,
            codigoUsuario: usuario!.codigoUsuario,
            ciclo: _cicloController.text.trim(),
            edad: edad ?? usuario!.edad,
            facultadID: usuario!.facultadID,
            escuelaId: usuario!.escuelaId,
            idRol: usuario!.idRol,
            fotoPerfil: usuario!.fotoPerfil,
            fechaRegistro: usuario!.fechaRegistro,
            estadoActivo: usuario!.estadoActivo,
            poloTallaID: usuario!.poloTallaID,
            fechaNacimiento: usuario!.fechaNacimiento,
            esAdmin: usuario!.esAdmin,
            medallasIDs: usuario!.medallasIDs,
            fechaModificacion: usuario!.fechaModificacion,
            puntosJuego: usuario!.puntosJuego,
            yape: usuario!.yape,
            cuentaBancaria: usuario!.cuentaBancaria,
            celular: usuario!.celular,
            banco: usuario!.banco,
          );
        });
      }

      _cancelEditing();
      _showSuccessSnackBar('Información actualizada correctamente');

    } catch (e) {
      _logger.e('Error saving profile changes: $e');
      _showErrorSnackBar('Error al guardar los cambios: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  void _showSuccessSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Widget _buildEventosInscritos() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Mis Eventos',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.orange.shade700,
                ),
              ),
              if (isLoading)
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.orange.shade700),
                  ),
                ),
            ],
          ),
        ),
        SizedBox(
          height: 240,
          child: eventosInscritos.isEmpty && !isLoading
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.event_busy,
                        size: 48,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No te has inscrito a ningún evento aún',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pushNamed(context, AppRoutes.eventos);
                        },
                        icon: const Icon(Icons.explore),
                        label: const Text('Explorar Eventos'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange.shade700,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                )
              : isLoading
                  ? Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.orange.shade700),
                      ),
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
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(12),
                              onTap: () {
                                // Navegar al detalle del evento
                                Navigator.pushNamed(
                                  context,
                                  AppRoutes.eventoDetalle,
                                  arguments: {'id': evento.idEvento},
                                );
                              },
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    height: 100,
                                    decoration: BoxDecoration(
                                      borderRadius: const BorderRadius.only(
                                        topLeft: Radius.circular(12),
                                        topRight: Radius.circular(12),
                                      ),
                                      image: DecorationImage(
                                        image: NetworkImage(evento.foto.isNotEmpty 
                                            ? evento.foto 
                                            : 'https://via.placeholder.com/300x100?text=Evento'),
                                        fit: BoxFit.cover,
                                        onError: (exception, stackTrace) {
                                        },
                                      ),
                                    ),
                                    child: Container(
                                      decoration: BoxDecoration(
                                        borderRadius: const BorderRadius.only(
                                          topLeft: Radius.circular(12),
                                          topRight: Radius.circular(12),
                                        ),
                                        gradient: LinearGradient(
                                          begin: Alignment.topCenter,
                                          end: Alignment.bottomCenter,
                                          colors: [
                                            Colors.transparent,
                                            Colors.black.withValues(alpha: 0.3),
                                          ],
                                        ),
                                      ),
                                      child: Padding(
                                        padding: const EdgeInsets.all(8.0),
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.end,
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.symmetric(
                                                horizontal: 8,
                                                vertical: 4,
                                              ),
                                              decoration: BoxDecoration(
                                                color: _getEstadoColor(evento.estado),
                                                borderRadius: BorderRadius.circular(12),
                                              ),
                                              child: Text(
                                                _getEstadoText(evento.estado),
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: Padding(
                                      padding: const EdgeInsets.all(12.0),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                evento.titulo,
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 16,
                                                ),
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              const SizedBox(height: 8),
                                              Row(
                                                children: [
                                                  Icon(
                                                    Icons.calendar_today,
                                                    size: 16,
                                                    color: Colors.orange.shade700,
                                                  ),
                                                  const SizedBox(width: 4),
                                                  Expanded(
                                                    child: Text(
                                                      _formatearFecha(evento.fechaInicio),
                                                      style: TextStyle(
                                                        color: Colors.grey[600],
                                                        fontSize: 12,
                                                        fontWeight: FontWeight.w500,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 4),
                                              Row(
                                                children: [
                                                  Icon(
                                                    Icons.access_time,
                                                    size: 16,
                                                    color: Colors.orange.shade700,
                                                  ),
                                                  const SizedBox(width: 4),
                                                  Expanded(
                                                    child: Text(
                                                      '${evento.horaInicio} - ${evento.horaFin}',
                                                      style: TextStyle(
                                                        color: Colors.grey[600],
                                                        fontSize: 12,
                                                        fontWeight: FontWeight.w500,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 4),
                                              Row(
                                                children: [
                                                  Icon(
                                                    Icons.location_on,
                                                    size: 16,
                                                    color: Colors.orange.shade700,
                                                  ),
                                                  const SizedBox(width: 4),
                                                  Expanded(
                                                    child: Text(
                                                      evento.ubicacion,
                                                      style: TextStyle(
                                                        color: Colors.grey[600],
                                                        fontSize: 12,
                                                        fontWeight: FontWeight.w500,
                                                      ),
                                                      maxLines: 1,
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 8),
                                          Container(
                                            width: double.infinity,
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 6,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.orange.shade50,
                                              borderRadius: BorderRadius.circular(8),
                                              border: Border.all(
                                                color: Colors.orange.shade200,
                                              ),
                                            ),
                                            child: Row(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [
                                                Icon(
                                                  Icons.touch_app,
                                                  size: 14,
                                                  color: Colors.orange.shade700,
                                                ),
                                                const SizedBox(width: 4),
                                                Text(
                                                  'Ver detalles',
                                                  style: TextStyle(
                                                    color: Colors.orange.shade700,
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
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
    if (estadisticas == null) {
      return Card(
        elevation: 4,
        margin: const EdgeInsets.all(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.orange.shade700),
            ),
          ),
        ),
      );
    }

    return Column(
      children: [
        _buildResumenCard(),
        
        Card(
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
                    Flexible(
                      child: Text(
                        'Mis Estadísticas',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange.shade700,
                        ),
                      ),
                    ),
                    _buildNivelBadge(),
                  ],
                ),
                const Divider(),
                
                _buildProgresoNivel(),
                
                const SizedBox(height: 20),
                
                LayoutBuilder(
                  builder: (context, constraints) {
                    return Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            Expanded(
                              child: _buildEstadisticaItem(
                                icon: Icons.event,
                                value: estadisticas!.eventosInscritos.toString(),
                                label: 'Total\nEventos',
                              ),
                            ),
                            Expanded(
                              child: _buildEstadisticaItem(
                                icon: Icons.check_circle,
                                value: estadisticas!.eventosCompletados.toString(),
                                label: 'Completados',
                                color: Colors.green,
                              ),
                            ),
                            Expanded(
                              child: _buildEstadisticaItem(
                                icon: Icons.access_time,
                                value: estadisticas!.horasTotales.toStringAsFixed(1),
                                label: 'Horas\nTotales',
                                color: Colors.blue,
                              ),
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: 20),
                        
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            Expanded(
                              child: _buildEstadisticaItem(
                                icon: Icons.favorite,
                                value: estadisticas!.donacionesRealizadas.toString(),
                                label: 'Donaciones',
                                color: Colors.pink,
                              ),
                            ),
                            Expanded(
                              child: _buildEstadisticaItem(
                                icon: Icons.local_fire_department,
                                value: estadisticas!.rachaActual.toString(),
                                label: 'Racha\nActual',
                                color: Colors.orange,
                              ),
                            ),
                            Expanded(
                              child: _buildEstadisticaItem(
                                icon: Icons.stars,
                                value: estadisticas!.puntosTotales.toString(),
                                label: 'Puntos\nTotales',
                                color: Colors.purple,
                              ),
                            ),
                          ],
                        ),
                      ],
                    );
                  },
                ),
                
                const SizedBox(height: 20),
                
                _buildIndicadoresAdicionales(),
                
                const SizedBox(height: 16),
                
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: estadisticas!.porcentajeCompletado,
                    backgroundColor: Colors.grey[200],
                    color: Colors.orange.shade700,
                    minHeight: 10,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Progreso General: ${(estadisticas!.porcentajeCompletado * 100).toStringAsFixed(0)}%',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
        ),
        
        _buildMedallasCard(),
      ],
    );
  }

  Widget _buildResumenCard() {
    return Card(
      elevation: 6,
      margin: const EdgeInsets.all(16),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            colors: [Colors.orange.shade700, Colors.orange.shade500],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: LayoutBuilder(
            builder: (context, constraints) {
              return Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Expanded(
                        child: _buildResumenItem(
                          icon: Icons.emoji_events,
                          value: estadisticas!.medallasObtenidas.length.toString(),
                          label: 'Medallas',
                          color: Colors.white,
                        ),
                      ),
                      Container(
                        height: 40,
                        width: 1,
                        color: Colors.white.withValues(alpha: 0.3),
                      ),
                      Expanded(
                        child: _buildResumenItem(
                          icon: Icons.trending_up,
                          value: estadisticas!.nivelActual,
                          label: 'Nivel',
                          color: Colors.white,
                        ),
                      ),
                      Container(
                        height: 40,
                        width: 1,
                        color: Colors.white.withValues(alpha: 0.3),
                      ),
                      Expanded(
                        child: _buildResumenItem(
                          icon: Icons.monetization_on,
                          value: 'S/${estadisticas!.montoTotalDonado.toStringAsFixed(0)}',
                          label: 'Donado',
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildResumenItem({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Column(
          children: [
            FittedBox(
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(height: 8),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                value,
                style: TextStyle(
                  color: color,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                label,
                style: TextStyle(
                  color: color.withValues(alpha: 0.9),
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildIndicadoresAdicionales() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.orange.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.orange.shade200),
          ),
          child: Row(
            children: [
              Icon(Icons.local_fire_department, color: Colors.orange.shade700),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Racha Actual: ${estadisticas!.rachaActual} eventos',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'Mejor Racha: ${estadisticas!.mejorRacha} eventos',
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                  ],
                ),
              ),
              if (estadisticas!.rachaActual >= 3)
                Icon(Icons.whatshot, color: Colors.red.shade600),
            ],
          ),
        ),
        
        if (estadisticas!.donacionesRealizadas > 0) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.pink.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.pink.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.favorite, color: Colors.pink.shade700),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Total Donado: S/${estadisticas!.montoTotalDonado.toStringAsFixed(2)}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'Promedio por donación: S/${(estadisticas!.montoTotalDonado / estadisticas!.donacionesRealizadas).toStringAsFixed(2)}',
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.volunteer_activism, color: Colors.pink.shade600),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildNivelBadge() {
    if (estadisticas == null) return Container();
    
    Color colorNivel = _getColorNivel(estadisticas!.nivelActual);
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: colorNivel,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: colorNivel.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _getIconoNivel(estadisticas!.nivelActual),
            color: Colors.white,
            size: 16,
          ),
          const SizedBox(width: 4),
          Text(
            estadisticas!.nivelActual,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgresoNivel() {
    if (estadisticas == null) return Container();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Progreso hacia ${estadisticas!.siguienteNivel}',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
            Text(
              '${estadisticas!.puntosParaSiguienteNivel} puntos restantes',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: LinearProgressIndicator(
            value: estadisticas!.progresoNivelSiguiente,
            backgroundColor: Colors.grey[200],
            color: _getColorNivel(estadisticas!.nivelActual),
            minHeight: 8,
          ),
        ),
      ],
    );
  }

  Widget _buildMedallasCard() {
    if (estadisticas == null) return Container();
    
    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.emoji_events, color: Colors.orange.shade700, size: 24),
                    const SizedBox(width: 8),
                    Text(
                      'Mis Medallas',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange.shade700,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade100,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${estadisticas!.medallasObtenidas.length}/${estadisticas!.medallasObtenidas.length + estadisticas!.medallasDisponibles.length}',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange.shade700,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(),
            
            if (estadisticas!.medallasObtenidas.isEmpty)
              _buildMedallasVacias()
            else
              Column(
                children: [
                  if (estadisticas!.medallasObtenidas.isNotEmpty) ...[
                    _buildSeccionMedallas('Obtenidas', estadisticas!.medallasObtenidas, true),
                    const SizedBox(height: 20),
                  ],
                  
                  if (estadisticas!.medallasDisponibles.isNotEmpty) ...[
                    _buildSeccionMedallas('Próximas a Obtener', 
                        estadisticas!.medallasDisponibles.take(6).toList(), false),
                  ],
                  
                  const SizedBox(height: 16),
                  
                  if (estadisticas!.medallasDisponibles.length > 6)
                    TextButton(
                      onPressed: _mostrarTodasLasMedallas,
                      child: Text(
                        'Ver todas las medallas (${estadisticas!.medallasDisponibles.length} restantes)',
                        style: TextStyle(color: Colors.orange.shade700),
                      ),
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMedallasVacias() {
    return SizedBox(
      height: 120,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.emoji_events_outlined,
              size: 48,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 8),
            Text(
              '¡Participa en eventos para obtener medallas!',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Cada evento completado te acerca a nuevos logros',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey[500],
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSeccionMedallas(String titulo, List<Medalla> medallas, bool obtenidas) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              titulo,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            if (obtenidas) ...[
              const SizedBox(width: 8),
              Icon(Icons.check_circle, color: Colors.green, size: 20),
            ],
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 100,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: medallas.length,
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: _buildMedallaItem(medallas[index], obtenidas),
              );
            },
          ),
        ),
      ],
    );
  }

  /// Método mejorado movido más abajo en el archivo

  Widget _buildSeccionMedallasCompleta(String titulo, List<Medalla> medallas, bool obtenidas) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          titulo,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            childAspectRatio: 0.8,
          ),
          itemCount: medallas.length,
          itemBuilder: (context, index) {
            return _buildMedallaItem(medallas[index], obtenidas);
          },
        ),
      ],
    );
  }

  Widget _buildMedallaItem(Medalla medalla, bool obtenida) {
    return GestureDetector(
      onTap: () => _showMedallaDetalle(medalla, obtenida),
      child: Container(
        width: 70,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        child: Column(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: obtenida 
                    ? Color(int.parse('0xFF${medalla.color.substring(1)}'))
                    : Colors.grey[300],
                border: Border.all(
                  color: obtenida 
                      ? Color(int.parse('0xFF${medalla.color.substring(1)}'))
                      : Colors.grey[400]!,
                  width: 2,
                ),
                boxShadow: obtenida ? [
                  BoxShadow(
                    color: Color(int.parse('0xFF${medalla.color.substring(1)}')).withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ] : null,
              ),
              child: Center(
                child: Text(
                  medalla.icono,
                  style: TextStyle(
                    fontSize: 24,
                    color: obtenida ? null : Colors.grey[600],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              medalla.nombre,
              style: TextStyle(
                fontSize: 10,
                fontWeight: obtenida ? FontWeight.bold : FontWeight.normal,
                color: obtenida ? Colors.black87 : Colors.grey[600],
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  void _showMedallaDetalle(Medalla medalla, bool obtenida) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Text(
              medalla.icono,
              style: const TextStyle(fontSize: 32),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    medalla.nombre,
                    style: const TextStyle(fontSize: 18),
                  ),
                  Text(
                    obtenida ? 'Obtenida' : 'Bloqueada',
                    style: TextStyle(
                      fontSize: 14,
                      color: obtenida ? Colors.green : Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(medalla.descripcion),
            const SizedBox(height: 12),
            if (!obtenida) ...[
              Text(
                'Requisito: ${medalla.requisito} ${_getTipoRequisito(medalla.tipo)}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.orange.shade700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _getProgresoMedalla(medalla),
                style: TextStyle(color: Colors.grey[600]),
              ),
            ] else if (medalla.fechaObtencion != null) ...[
              Text(
                'Obtenida el: ${_formatFecha(medalla.fechaObtencion!)}',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  Color _getColorNivel(String nivel) {
    switch (nivel) {
      case 'Novato': return Colors.grey[600]!;
      case 'Voluntario': return Colors.green;
      case 'Activista': return Colors.blue;
      case 'Héroe': return Colors.purple;
      case 'Leyenda': return Colors.orange;
      case 'Maestro': return Colors.red;
      default: return Colors.grey[600]!;
    }
  }

  IconData _getIconoNivel(String nivel) {
    switch (nivel) {
      case 'Novato': return Icons.star_border;
      case 'Voluntario': return Icons.star_half;
      case 'Activista': return Icons.star;
      case 'Héroe': return Icons.emoji_events;
      case 'Leyenda': return Icons.military_tech;
      case 'Maestro': return Icons.diamond;
      default: return Icons.star_border;
    }
  }

  String _getTipoRequisito(String tipo) {
    switch (tipo) {
      case 'eventos': return 'eventos completados';
      case 'horas': return 'horas de servicio';
      case 'racha': return 'días consecutivos';
      case 'donaciones': return 'donaciones realizadas';
      case 'monto_donaciones': return 'soles donados';
      case 'diversidad': return 'tipos de eventos diferentes';
      case 'especial': return 'acciones especiales';
      case 'liderazgo': return 'eventos organizados';
      default: return 'acciones';
    }
  }

  String _getProgresoMedalla(Medalla medalla) {
    if (estadisticas == null) return '';
    
    int progreso = 0;
    switch (medalla.tipo) {
      case 'eventos':
        progreso = estadisticas!.eventosCompletados;
        break;
      case 'horas':
        progreso = estadisticas!.horasTotales.round();
        break;
      case 'racha':
        progreso = estadisticas!.mejorRacha;
        break;
      case 'donaciones':
        progreso = estadisticas!.donacionesRealizadas;
        break;
      case 'monto_donaciones':
        progreso = estadisticas!.montoTotalDonado.round();
        break;
      case 'diversidad':
        progreso = estadisticas!.eventosCompletados > 0 ? 1 : 0;
        break;
      case 'especial':
        if (medalla.id == 'madrugador') {
          progreso = _tieneEventoTemprano() ? 1 : 0;
        } else if (medalla.id == 'nocturno') {
          progreso = _tieneEventoNocturno() ? 1 : 0;
        } else if (medalla.id == 'fin_semana') {
          progreso = _tieneEventosFinSemana() ? 1 : 0;
        }
        break;
      case 'liderazgo':
        progreso = 0;
        break;
    }
    
    double porcentaje = (progreso / medalla.requisito * 100).clamp(0, 100);
    return 'Progreso: $progreso/${medalla.requisito} (${porcentaje.toStringAsFixed(0)}%)';
  }

  bool _tieneEventoTemprano() {
    for (var evento in eventosInscritos) {
      try {
        final hora = int.parse(evento.horaInicio.split(':')[0]);
        if (hora < 7 && evento.estado.toLowerCase() == 'finalizado') return true;
      } catch (e) {
      }
    }
    return false;
  }

  bool _tieneEventoNocturno() {
    for (var evento in eventosInscritos) {
      try {
        final hora = int.parse(evento.horaInicio.split(':')[0]);
        if (hora >= 22 && evento.estado.toLowerCase() == 'finalizado') return true;
      } catch (e) {
      }
    }
    return false;
  }

  bool _tieneEventosFinSemana() {
    bool tienesSabado = false;
    bool tienesDomingo = false;
    
    for (var evento in eventosInscritos) {
      if (evento.estado.toLowerCase() == 'finalizado') {
        try {
          final fecha = DateTime.parse(evento.fechaInicio);
          if (fecha.weekday == 6) tienesSabado = true;
          if (fecha.weekday == 7) tienesDomingo = true;
        } catch (e) {
        }
      }
    }
    
    return tienesSabado && tienesDomingo;
  }

  String _formatFecha(DateTime fecha) {
    return '${fecha.day}/${fecha.month}/${fecha.year}';
  }

  String _formatearFecha(String fecha) {
    try {
      final DateTime dateTime = DateTime.parse(fecha);
      final DateFormat formatter = DateFormat('dd/MM/yyyy');
      return formatter.format(dateTime);
    } catch (e) {
      _logger.w('Error formateando fecha: $fecha');
      return fecha;
    }
  }

  Widget _buildEstadisticaItem({
    required IconData icon,
    required String value,
    required String label,
    Color? color,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4.0),
          child: Column(
            children: [
              FittedBox(
                child: Icon(
                  icon,
                  size: constraints.maxWidth * 0.15,
                  color: color ?? Colors.orange.shade700,
                ),
              ),
              SizedBox(height: constraints.maxWidth * 0.03),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  value,
                  style: TextStyle(
                    fontSize: constraints.maxWidth * 0.08,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              SizedBox(height: constraints.maxWidth * 0.01),
              Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: constraints.maxWidth * 0.04,
                  color: Colors.grey,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _loadDonaciones() async {
    if (!mounted) return;
    
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      _calcularEstadisticas();
      return;
    }

    try {
      final donacionesSnapshot = await FirebaseFirestore.instance
          .collection('donaciones')
          .where('idUsuarioDonador', isEqualTo: userId)
          .get();

      if (!mounted) return;

      setState(() {
        donaciones = donacionesSnapshot.docs
            .map((doc) => Donaciones.fromMap({
                  ...doc.data(),
                  'idDonaciones': doc.id,
                }))
            .toList();
      });
      
    } catch (e) {
      if (!mounted) return;
      _logger.e('Error cargando donaciones: $e');
    }
    
    _calcularEstadisticas();
  }

  void _calcularEstadisticas() {
    final userId = FirebaseAuth.instance.currentUser?.uid ?? '';
    
    estadisticasAnteriores = estadisticas;
    
    final nuevasEstadisticas = EstadisticasUsuario.calcular(
      eventos: eventosInscritos,
      donaciones: donaciones,
      userId: userId,
    );
    
    setState(() {
      estadisticas = nuevasEstadisticas;
    });
    
    if (estadisticasAnteriores != null) {
      _verificarNuevasMedallas();
    }
  }

  void _verificarNuevasMedallas() {
    if (estadisticasAnteriores == null || estadisticas == null) return;
    
    final medallasAnteriores = estadisticasAnteriores!.medallasObtenidas.map((m) => m.id).toSet();
    final medallasActuales = estadisticas!.medallasObtenidas.map((m) => m.id).toSet();
    
    final nuevasMedallasIds = medallasActuales.difference(medallasAnteriores);
    
    if (nuevasMedallasIds.isNotEmpty) {
      nuevasMedallas = estadisticas!.medallasObtenidas
          .where((medalla) => nuevasMedallasIds.contains(medalla.id))
          .toList();
      
      Future.delayed(const Duration(milliseconds: 500), () {
        _mostrarNotificacionMedallas();
      });
    }
  }

  void _mostrarNotificacionMedallas() {
    if (nuevasMedallas.isEmpty || !mounted) return;
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.celebration, color: Colors.orange.shade700, size: 32),
            const SizedBox(width: 12),
            const Text('¡Felicidades!'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              nuevasMedallas.length == 1 
                  ? '¡Has obtenido una nueva medalla!'
                  : '¡Has obtenido ${nuevasMedallas.length} nuevas medallas!',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 20),
            ...nuevasMedallas.map((medalla) => Container(
              margin: const EdgeInsets.symmetric(vertical: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Color(int.parse('0xFF${medalla.color.substring(1)}')).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Color(int.parse('0xFF${medalla.color.substring(1)}')),
                  width: 2,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(int.parse('0xFF${medalla.color.substring(1)}')),
                    ),
                    child: Center(
                      child: Text(
                        medalla.icono,
                        style: const TextStyle(fontSize: 24),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          medalla.nombre,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          medalla.descripcion,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            )),
          ],
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange.shade700,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () {
              Navigator.pop(context);
              nuevasMedallas.clear();
            },
            child: const Text('¡Genial!', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  /// Widget mejorado para mostrar donaciones con datos dinámicos
  Widget _buildDonationsEnhancedCard() {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.favorite,
                  color: Colors.red.shade400,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  'Mis Donaciones',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange.shade700,
                  ),
                ),
              ],
            ),
            const Divider(),
            
            if (estadisticas != null) ...[
              _buildDonationsSummary(),
              const SizedBox(height: 16),
              _buildDonationsProgress(),
              const SizedBox(height: 16),
              _buildDonationsActions(),
            ] else ...[
              const Center(
                child: CircularProgressIndicator(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDonationsSummary() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.red.shade50, Colors.orange.shade50],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildDonationMetric(
                'Total Validado',
                'S/ ${estadisticas!.montoTotalDonado.toStringAsFixed(2)}',
                Icons.monetization_on,
                Colors.green,
              ),
              _buildDonationMetric(
                'Donaciones Validadas',
                '${estadisticas!.donacionesRealizadas}',
                Icons.verified,
                Colors.blue,
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildDonationImpact(),
        ],
      ),
    );
  }

  Widget _buildDonationMetric(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildDonationImpact() {
    final impacto = _calcularImpactoDonaciones();
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.trending_up, color: Colors.orange.shade700),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Impacto Generado',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                Text(
                  impacto,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[700],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDonationsProgress() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Progreso hacia siguiente nivel de donador',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(height: 8),
        _buildDonationLevelProgress(),
      ],
    );
  }

  Widget _buildDonationLevelProgress() {
    final nivelesDonativos = [
      {'nombre': 'Colaborador', 'monto': 50.0, 'color': Colors.green},
      {'nombre': 'Benefactor', 'monto': 200.0, 'color': Colors.blue},
      {'nombre': 'Héroe', 'monto': 500.0, 'color': Colors.purple},
      {'nombre': 'Leyenda', 'monto': 1000.0, 'color': Colors.orange},
    ];

    final montoActual = estadisticas!.montoTotalDonado;
    
    // Encontrar el siguiente nivel
    Map<String, dynamic>? siguienteNivel;
    for (var nivel in nivelesDonativos) {
      if (montoActual < (nivel['monto'] as double)) {
        siguienteNivel = nivel;
        break;
      }
    }

    if (siguienteNivel == null) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.amber.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(Icons.star, color: Colors.orange),
            const SizedBox(width: 8),
            const Text(
              '¡Has alcanzado el nivel máximo de donador!',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      );
    }

    final progreso = montoActual / (siguienteNivel['monto'] as double);
    final montoFaltante = (siguienteNivel['monto'] as double) - montoActual;

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Nivel: ${siguienteNivel['nombre']}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            Text(
              'S/ ${montoFaltante.toStringAsFixed(2)} restantes',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: progreso.clamp(0.0, 1.0),
          backgroundColor: Colors.grey[300],
          valueColor: AlwaysStoppedAnimation<Color>(
            siguienteNivel['color'] as Color,
          ),
        ),
      ],
    );
  }

  Widget _buildDonationsActions() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () {
              // Navegar a pantalla de donaciones usando la ruta correcta
              Navigator.pushNamed(context, '/donaciones');
            },
            icon: const Icon(Icons.volunteer_activism),
            label: const Text('Donar Ahora'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange.shade700,
              foregroundColor: Colors.white,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => _mostrarHistorialDonaciones(),
            icon: const Icon(Icons.history),
            label: const Text('Historial'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.orange.shade700,
            ),
          ),
        ),
      ],
    );
  }

  String _calcularImpactoDonaciones() {
    final monto = estadisticas!.montoTotalDonado;
    final donaciones = estadisticas!.donacionesRealizadas;
    
    if (monto < 50) {
      return 'Cada donación validada cuenta. ¡Gracias por tu generosidad!';
    } else if (monto < 200) {
      return 'Con tus donaciones validadas has ayudado a alimentar a ${(monto / 10).floor()} personas.';
    } else if (monto < 500) {
      return 'Con tus $donaciones donaciones validadas se han realizado acciones solidarias.';
    } else {
      return '¡Eres un héroe! Tus donaciones validadas han impactado a cientos de personas.';
    }
  }

  void _mostrarHistorialDonaciones() async {
    try {
      // Obtener solo donaciones validadas para el perfil
      final donacionesValidadas = await DonationsService.getDonacionesValidadas();
      final estadisticasDonaciones = await DonationsService.getEstadisticasDonaciones();
      
      if (!mounted) return;
      
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => _buildHistorialDonacionesModal(
          donacionesValidadas,
          estadisticasDonaciones,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error cargando historial: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildHistorialDonacionesModal(
    List<Donaciones> donaciones,
    Map<String, dynamic> estadisticasDonaciones,
  ) {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      maxChildSize: 0.9,
      minChildSize: 0.5,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Historial de Donaciones Validadas',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange.shade700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Solo se muestran donaciones aprobadas',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: donaciones.length,
                  itemBuilder: (context, index) {
                    final donacion = donaciones[index];
                    return _buildDonacionItem(donacion);
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDonacionItem(Donaciones donacion) {
    // Como ya solo mostramos validadas, todas tienen el mismo estado
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.green,
          child: const Icon(
            Icons.verified,
            color: Colors.white,
          ),
        ),
        title: Text(
          donacion.tipoDonacion,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (donacion.descripcion.isNotEmpty)
              Text(donacion.descripcion),
            Text(
              'Fecha: ${donacion.fechaDonacion}',
              style: TextStyle(color: Colors.grey[600]),
            ),
            Text(
              'Estado: Validada ✓',
              style: TextStyle(
                color: Colors.green,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        trailing: donacion.tipoDonacion.toLowerCase().contains('dinero') ||
                 donacion.tipoDonacion.toLowerCase().contains('monetaria')
            ? Text(
                'S/ ${donacion.monto.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              )
            : const Icon(Icons.inventory),
      ),
    );
  }

  @override
  void dispose() {
    _cancelLoadOperations();
    
    _nombreController.dispose();
    _apellidosController.dispose();
    _cicloController.dispose();
    _edadController.dispose();
    
    super.dispose();
  }

  void _cancelLoadOperations() {
    _disposed = true;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi Perfil'),
        backgroundColor: Colors.orange.shade700,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _loadAllData(forceRefresh: true),
            tooltip: 'Refrescar datos',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => _loadAllData(forceRefresh: true),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),
                Center(child: _buildProfileImage()),
                const SizedBox(height: 20),
                _buildEstadisticasCard(),
                _buildConsejosMotivacionales(),
                _buildUserDataCard(),
                const SizedBox(height: 20),
                _buildEventosInscritos(),
                const SizedBox(height: 20),
                _buildDonationsEnhancedCard(),
                const SizedBox(height: 20),
                _buildMedallasEnhancedSection(),
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
                      if (context.mounted) {
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
        ),
      ),
    );
  }

  Widget _buildConsejosMotivacionales() {
    if (estadisticas == null) return Container();
    
    List<Map<String, dynamic>> consejos = _generarConsejos();
    
    if (consejos.isEmpty) return Container();
    
    return Card(
      elevation: 4,
      margin: const EdgeInsets.all(16),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            colors: [Colors.blue.shade50, Colors.purple.shade50],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.lightbulb, color: Colors.orange.shade700, size: 24),
                  const SizedBox(width: 8),
                  Text(
                    'Consejos para Ti',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange.shade700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ...consejos.map((consejo) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Icon(
                      consejo['icon'] as IconData,
                      color: consejo['color'] as Color,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        consejo['texto'] as String,
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                  ],
                ),
              )),
            ],
          ),
        ),
      ),
    );
  }

  List<Map<String, dynamic>> _generarConsejos() {
    List<Map<String, dynamic>> consejos = [];
    
    if (estadisticas!.eventosCompletados == 0) {
      consejos.add({
        'icon': Icons.start,
        'color': Colors.green,
        'texto': '¡Inscríbete a tu primer evento para comenzar tu aventura de voluntariado!',
      });
    }
    
    if (estadisticas!.medallasObtenidas.isEmpty && estadisticas!.eventosCompletados > 0) {
      consejos.add({
        'icon': Icons.emoji_events,
        'color': Colors.amber,
        'texto': '¡Estás cerca de obtener tu primera medalla! Completa un evento más.',
      });
    }
    
    if (estadisticas!.rachaActual == 0 && estadisticas!.eventosCompletados > 0) {
      consejos.add({
        'icon': Icons.local_fire_department,
        'color': Colors.orange,
        'texto': 'Mantén una racha participando en eventos consecutivos.',
      });
    }
    
    if (estadisticas!.donacionesRealizadas == 0) {
      consejos.add({
        'icon': Icons.favorite,
        'color': Colors.pink,
        'texto': 'Considera hacer una donación para ayudar aún más a la comunidad.',
      });
    }
    
    if (estadisticas!.puntosParaSiguienteNivel <= 50 && estadisticas!.puntosParaSiguienteNivel > 0) {
      consejos.add({
        'icon': Icons.trending_up,
        'color': Colors.blue,
        'texto': '¡Solo te faltan ${estadisticas!.puntosParaSiguienteNivel} puntos para subir de nivel!',
      });
    }
    
    if (estadisticas!.eventosCompletados >= 5) {
      consejos.add({
        'icon': Icons.star,
        'color': Colors.purple,
        'texto': '¡Excelente trabajo! Has completado ${estadisticas!.eventosCompletados} eventos.',
      });
    }
    
    return consejos.take(3).toList();
  }

  /// Widget mejorado para mostrar medallas con datos dinámicos
  Widget _buildMedallasEnhancedSection() {
    if (estadisticas == null) {
      return Card(
        elevation: 4,
        margin: const EdgeInsets.all(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.orange.shade700),
            ),
          ),
        ),
      );
    }

    final medallasObtenidas = estadisticas!.medallasObtenidas;
    final medallasDisponibles = estadisticas!.medallasDisponibles;
    
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
                Row(
                  children: [
                    Icon(
                      Icons.military_tech,
                      color: Colors.amber.shade700,
                      size: 24,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Mis Logros',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange.shade700,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade100,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${medallasObtenidas.length}/${medallasDisponibles.length}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.amber.shade700,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(),
            
            // Progreso general de medallas
            _buildProgresoGeneralMedallas(medallasObtenidas, medallasDisponibles),
            
            const SizedBox(height: 16),
            
            // Medallas por categoría
            _buildMedallasPorCategoria(medallasObtenidas, medallasDisponibles),
            
            const SizedBox(height: 16),
            
            // Próximas medallas a desbloquear
            _buildProximasMedallas(medallasObtenidas, medallasDisponibles),
            
            const SizedBox(height: 16),
            
            // Botón para ver todas las medallas
            Center(
              child: ElevatedButton.icon(
                onPressed: () => _mostrarTodasLasMedallas(),
                icon: const Icon(Icons.emoji_events),
                label: const Text('Ver Todas las Medallas'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber.shade700,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgresoGeneralMedallas(List<Medalla> obtenidas, List<Medalla> disponibles) {
    final progreso = disponibles.isNotEmpty ? obtenidas.length / disponibles.length : 0.0;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.amber.shade50, Colors.orange.shade50],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Progreso General',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              Text(
                '${(progreso * 100).round()}%',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.amber.shade700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: progreso,
            backgroundColor: Colors.grey[300],
            valueColor: AlwaysStoppedAnimation<Color>(Colors.amber.shade700),
          ),
        ],
      ),
    );
  }

  Widget _buildMedallasPorCategoria(List<Medalla> obtenidas, List<Medalla> disponibles) {
    // Agrupar medallas por categoría
    final categorias = <String, Map<String, int>>{};
    
    for (var medalla in disponibles) {
      if (!categorias.containsKey(medalla.categoria)) {
        categorias[medalla.categoria] = {'total': 0, 'obtenidas': 0};
      }
      categorias[medalla.categoria]!['total'] = 
          (categorias[medalla.categoria]!['total'] ?? 0) + 1;
      
      if (obtenidas.any((m) => m.id == medalla.id)) {
        categorias[medalla.categoria]!['obtenidas'] = 
            (categorias[medalla.categoria]!['obtenidas'] ?? 0) + 1;
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Por Categoría',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 8),
        ...categorias.entries.map((entry) {
          final categoria = entry.key;
          final obtenidas = entry.value['obtenidas'] ?? 0;
          final total = entry.value['total'] ?? 0;
          final progreso = total > 0 ? obtenidas / total : 0.0;
          
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: _getColorForCategory(categoria),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    categoria.toUpperCase(),
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
                Text(
                  '$obtenidas/$total',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 2,
                  child: LinearProgressIndicator(
                    value: progreso,
                    backgroundColor: Colors.grey[300],
                    valueColor: AlwaysStoppedAnimation<Color>(
                      _getColorForCategory(categoria),
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildProximasMedallas(List<Medalla> obtenidas, List<Medalla> disponibles) {
    final medallasObtenidas = obtenidas.map((m) => m.id).toSet();
    final proximasMedallas = disponibles
        .where((m) => !medallasObtenidas.contains(m.id))
        .take(3)
        .toList();

    if (proximasMedallas.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.green.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.green.shade200),
        ),
        child: Row(
          children: [
            Icon(Icons.celebration, color: Colors.green.shade700),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                '¡Felicidades! Has desbloqueado todas las medallas disponibles.',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Próximas a Desbloquear',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 8),
        ...proximasMedallas.map((medalla) => _buildProximaMedallaItem(medalla)),
      ],
    );
  }

  Widget _buildProximaMedallaItem(Medalla medalla) {
    final progreso = _calcularProgresoHaciaMedalla(medalla);
    
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                medalla.icono,
                style: const TextStyle(fontSize: 20),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  medalla.nombre,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
              Text(
                '${(progreso * 100).round()}%',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.orange.shade700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            medalla.descripcion,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: progreso,
            backgroundColor: Colors.grey[300],
            valueColor: AlwaysStoppedAnimation<Color>(Colors.orange.shade700),
          ),
        ],
      ),
    );
  }

  Color _getColorForCategory(String categoria) {
    switch (categoria.toLowerCase()) {
      case 'bronce':
        return const Color(0xFFCD7F32);
      case 'plata':
        return const Color(0xFFC0C0C0);
      case 'oro':
        return const Color(0xFFFFD700);
      case 'diamante':
        return const Color(0xFF00FFFF);
      default:
        return Colors.grey;
    }
  }

  double _calcularProgresoHaciaMedalla(Medalla medalla) {
    if (estadisticas == null) return 0.0;
    
    double valorActual = 0;
    
    switch (medalla.tipo) {
      case 'eventos':
        valorActual = estadisticas!.eventosCompletados.toDouble();
        break;
      case 'horas':
        valorActual = estadisticas!.horasTotales;
        break;
      case 'racha':
        valorActual = estadisticas!.mejorRacha.toDouble();
        break;
      case 'donaciones':
        valorActual = estadisticas!.donacionesRealizadas.toDouble();
        break;
      case 'monto_donaciones':
        valorActual = estadisticas!.montoTotalDonado;
        break;
    }
    
    return (valorActual / medalla.requisito).clamp(0.0, 1.0);
  }

  void _mostrarTodasLasMedallas() {
    if (estadisticas == null) return;
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildMedallasModal(),
    );
  }

  Widget _buildMedallasModal() {
    return DraggableScrollableSheet(
      initialChildSize: 0.8,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Colección de Medallas',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange.shade700,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: GridView.builder(
                  controller: scrollController,
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 1,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: estadisticas!.medallasDisponibles.length,
                  itemBuilder: (context, index) {
                    final medalla = estadisticas!.medallasDisponibles[index];
                    final obtenida = estadisticas!.medallasObtenidas
                        .any((m) => m.id == medalla.id);
                    return _buildMedallaCard(medalla, obtenida);
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMedallaCard(Medalla medalla, bool obtenida) {
    return Container(
      decoration: BoxDecoration(
        color: obtenida ? Colors.white : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: obtenida ? _getColorForCategory(medalla.categoria) : Colors.grey.shade300,
          width: 2,
        ),
        boxShadow: obtenida
            ? [
                BoxShadow(
                  color: _getColorForCategory(medalla.categoria).withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                Text(
                  medalla.icono,
                  style: TextStyle(
                    fontSize: 40,
                    color: obtenida ? null : Colors.grey,
                  ),
                ),
                if (!obtenida)
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.3),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.lock,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              medalla.nombre,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
                color: obtenida ? Colors.black : Colors.grey,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              medalla.descripcion,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 10,
                color: obtenida ? Colors.grey[600] : Colors.grey,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            if (obtenida) ...[
              const SizedBox(height: 4),
              Icon(
                Icons.verified,
                color: _getColorForCategory(medalla.categoria),
                size: 16,
              ),
            ],
          ],
        ),
      ),
    );
  }
  
  // Métodos auxiliares para eventos
  Color _getEstadoColor(String estado) {
    switch (estado.toLowerCase()) {
      case 'activo':
      case 'en proceso':
      case 'próximo':
        return Colors.green;
      case 'finalizado':
      case 'completado':
        return Colors.blue;
      case 'cancelado':
        return Colors.red;
      case 'pendiente':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  String _getEstadoText(String estado) {
    switch (estado.toLowerCase()) {
      case 'activo':
        return 'Activo';
      case 'en proceso':
        return 'En Proceso';
      case 'próximo':
        return 'Próximo';
      case 'finalizado':
        return 'Finalizado';
      case 'completado':
        return 'Completado';
      case 'cancelado':
        return 'Cancelado';
      case 'pendiente':
        return 'Pendiente';
      default:
        return estado.toUpperCase();
    }
  }
}