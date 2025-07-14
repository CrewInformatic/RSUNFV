import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../core/theme/app_colors.dart';

class AdminTestimonialsScreen extends StatefulWidget {
  const AdminTestimonialsScreen({super.key});

  @override
  State<AdminTestimonialsScreen> createState() => _AdminTestimonialsScreenState();
}

class _AdminTestimonialsScreenState extends State<AdminTestimonialsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text(
          'Gestión de Testimonios',
          style: TextStyle(
            color: AppColors.darkText,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.darkText),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.mediumText,
          indicatorColor: AppColors.primary,
          tabs: const [
            Tab(
              icon: Icon(Icons.pending_actions),
              text: 'Pendientes',
            ),
            Tab(
              icon: Icon(Icons.check_circle),
              text: 'Aprobados',
            ),
            Tab(
              icon: Icon(Icons.cancel),
              text: 'Rechazados',
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildTestimonialsList('pendiente'),
          _buildTestimonialsList('aprobado'),
          _buildTestimonialsList('rechazado'),
        ],
      ),
    );
  }

  Widget _buildTestimonialsList(String status) {
    print('=== CARGANDO TESTIMONIOS: $status ===');
    
    return StreamBuilder<QuerySnapshot>(
      stream: _getTestimonialsStream(status),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          print('=== ERROR EN STREAM DE TESTIMONIOS ===');
          print('Status: $status');
          print('Tipo de error: ${snapshot.error.runtimeType}');
          print('Mensaje completo: ${snapshot.error}');
          
          // Capturar el enlace del índice si está presente
          final errorString = snapshot.error.toString();
          if (errorString.contains('https://console.firebase.google.com')) {
            final linkMatch = RegExp(r'https://console\.firebase\.google\.com[^\s]+').firstMatch(errorString);
            if (linkMatch != null) {
              final indexLink = linkMatch.group(0);
              print('=== ENLACE PARA CREAR ÍNDICE (ADMIN TESTIMONIOS) ===');
              print(indexLink);
              print('=== COPIE ESTE ENLACE Y ÁBRALO EN SU NAVEGADOR ===');
            }
          }
          
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 64,
                  color: Colors.red.shade300,
                ),
                const SizedBox(height: 16),
                Text(
                  'Error al cargar testimonios',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.red.shade600,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Text(
                    errorString.contains('index') || errorString.contains('composite')
                        ? 'Error de configuración de base de datos. Revise la consola para crear los índices necesarios.'
                        : snapshot.error.toString(),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppColors.mediumText,
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    setState(() {}); // Forzar rebuild
                  },
                  child: const Text('Reintentar'),
                ),
              ],
            ),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
          );
        }

        final testimonials = snapshot.data?.docs ?? [];

        if (testimonials.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  _getEmptyIcon(status),
                  size: 64,
                  color: AppColors.greyMedium,
                ),
                const SizedBox(height: 16),
                Text(
                  _getEmptyMessage(status),
                  style: const TextStyle(
                    fontSize: 18,
                    color: AppColors.mediumText,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            setState(() {});
          },
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: testimonials.length,
            itemBuilder: (context, index) {
              final doc = testimonials[index];
              final data = doc.data() as Map<String, dynamic>;
              return _buildTestimonialCard(doc.id, data, status);
            },
          ),
        );
      },
    );
  }

  IconData _getEmptyIcon(String status) {
    switch (status) {
      case 'pendiente':
        return Icons.inbox;
      case 'aprobado':
        return Icons.verified;
      case 'rechazado':
        return Icons.block;
      default:
        return Icons.inbox;
    }
  }

  String _getEmptyMessage(String status) {
    switch (status) {
      case 'pendiente':
        return 'No hay testimonios pendientes';
      case 'aprobado':
        return 'No hay testimonios aprobados';
      case 'rechazado':
        return 'No hay testimonios rechazados';
      default:
        return 'No hay testimonios';
    }
  }

  Widget _buildTestimonialCard(String testimonialId, Map<String, dynamic> data, String status) {
    final fechaCreacion = data['fechaCreacion'] as Timestamp?;
    final fechaAprobacion = data['fechaAprobacion'] as Timestamp?;
    final fecha = fechaAprobacion ?? fechaCreacion;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(
          color: _getStatusColor(status).withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _getStatusColor(status).withValues(alpha: 0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: _getStatusColor(status).withValues(alpha: 0.2),
                  child: Text(
                    (data['nombre'] as String? ?? 'U')[0].toUpperCase(),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: _getStatusColor(status),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        data['nombre'] ?? 'Usuario Anónimo',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.darkText,
                        ),
                      ),
                      Text(
                        data['carrera'] ?? 'Estudiante UNFV',
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.mediumText,
                        ),
                      ),
                      if (fecha != null)
                        Text(
                          DateFormat('dd/MM/yyyy HH:mm').format(fecha.toDate()),
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.mediumText,
                          ),
                        ),
                    ],
                  ),
                ),
                _buildStatusBadge(status),
              ],
            ),
          ),
          
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Text(
                  'Calificación: ',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.darkText,
                  ),
                ),
                ...List.generate(5, (index) {
                  final rating = data['rating'] as int? ?? 5;
                  return Icon(
                    index < rating ? Icons.star : Icons.star_border,
                    size: 20,
                    color: index < rating ? AppColors.warning : AppColors.greyMedium,
                  );
                }),
                const SizedBox(width: 8),
                Text(
                  '(${data['rating'] ?? 5}/5)',
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.mediumText,
                  ),
                ),
              ],
            ),
          ),
          
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.backgroundLight,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.greyMedium.withValues(alpha: 0.3),
                ),
              ),
              child: Text(
                data['mensaje'] ?? 'Sin mensaje',
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.darkText,
                  height: 1.4,
                ),
              ),
            ),
          ),
          
          if (status == 'pendiente')
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _isLoading ? null : () => _rejectTestimonial(testimonialId),
                      icon: const Icon(Icons.close),
                      label: const Text('Rechazar'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.shade50,
                        foregroundColor: Colors.red.shade700,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                          side: BorderSide(color: Colors.red.shade300),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _isLoading ? null : () => _approveTestimonial(testimonialId),
                      icon: const Icon(Icons.check),
                      label: const Text('Aprobar'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green.shade50,
                        foregroundColor: Colors.green.shade700,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                          side: BorderSide(color: Colors.green.shade300),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          
          if (status != 'pendiente' && data['adminAprobador'] != null)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.backgroundLight,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    status == 'aprobado' ? Icons.admin_panel_settings : Icons.person_off,
                    size: 16,
                    color: AppColors.mediumText,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${status == 'aprobado' ? 'Aprobado' : 'Rechazado'} por: ${data['adminAprobador']}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.mediumText,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pendiente':
        return Colors.orange;
      case 'aprobado':
        return Colors.green;
      case 'rechazado':
        return Colors.red;
      default:
        return AppColors.greyMedium;
    }
  }

  Widget _buildStatusBadge(String status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _getStatusColor(status),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        _getStatusText(status),
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: AppColors.white,
        ),
      ),
    );
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'pendiente':
        return 'PENDIENTE';
      case 'aprobado':
        return 'APROBADO';
      case 'rechazado':
        return 'RECHAZADO';
      default:
        return 'DESCONOCIDO';
    }
  }

  Stream<QuerySnapshot> _getTestimonialsStream(String status) {
    try {
      print('=== CONFIGURANDO STREAM PARA: $status ===');
      
      Query query = FirebaseFirestore.instance
          .collection('testimonios')
          .orderBy('fechaCreacion', descending: true);

      if (status == 'pendiente') {
        query = query.where('aprobado', isEqualTo: false).where('rechazado', isEqualTo: null);
      } else if (status == 'aprobado') {
        query = query.where('aprobado', isEqualTo: true);
      } else if (status == 'rechazado') {
        query = query.where('rechazado', isEqualTo: true);
      }

      print('Query configurada para $status');
      return query.snapshots();
      
    } catch (e) {
      print('=== ERROR AL CONFIGURAR STREAM ===');
      print('Status: $status');
      print('Error: $e');
      
      // Si hay error de índice, intentar consulta simplificada
      if (e.toString().contains('index') || e.toString().contains('composite')) {
        print('Error de índice detectado. Usando consulta simplificada...');
        
        // Consulta simplificada sin orderBy
        Query simpleQuery = FirebaseFirestore.instance.collection('testimonios');
        
        if (status == 'pendiente') {
          simpleQuery = simpleQuery.where('aprobado', isEqualTo: false);
        } else if (status == 'aprobado') {
          simpleQuery = simpleQuery.where('aprobado', isEqualTo: true);
        } else if (status == 'rechazado') {
          simpleQuery = simpleQuery.where('rechazado', isEqualTo: true);
        }
        
        return simpleQuery.snapshots();
      }
      
      // Si no es error de índice, re-lanzar
      rethrow;
    }
  }

  Future<void> _approveTestimonial(String testimonialId) async {
    setState(() {
      _isLoading = true;
    });

    try {
      print('=== APROBANDO TESTIMONIO ===');
      print('Testimonio ID: $testimonialId');
      
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('No autenticado');

      print('Usuario admin: ${user.uid}');

      final adminDoc = await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(user.uid)
          .get();

      final adminName = adminDoc.exists 
          ? (adminDoc.data()?['nombre'] as String? ?? 'Administrador')
          : 'Administrador';

      print('Nombre admin: $adminName');

      await FirebaseFirestore.instance
          .collection('testimonios')
          .doc(testimonialId)
          .update({
        'aprobado': true,
        'rechazado': false,
        'fechaAprobacion': FieldValue.serverTimestamp(),
        'adminAprobador': adminName,
      });

      print('=== TESTIMONIO APROBADO EXITOSAMENTE ===');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Testimonio aprobado exitosamente'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      print('=== ERROR AL APROBAR TESTIMONIO ===');
      print('Testimonio ID: $testimonialId');
      print('Tipo de error: ${e.runtimeType}');
      print('Mensaje: $e');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al aprobar testimonio: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _rejectTestimonial(String testimonialId) async {
    setState(() {
      _isLoading = true;
    });

    try {
      print('=== RECHAZANDO TESTIMONIO ===');
      print('Testimonio ID: $testimonialId');
      
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('No autenticado');

      print('Usuario admin: ${user.uid}');

      final adminDoc = await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(user.uid)
          .get();

      final adminName = adminDoc.exists 
          ? (adminDoc.data()?['nombre'] as String? ?? 'Administrador')
          : 'Administrador';

      print('Nombre admin: $adminName');

      await FirebaseFirestore.instance
          .collection('testimonios')
          .doc(testimonialId)
          .update({
        'aprobado': false,
        'rechazado': true,
        'fechaAprobacion': FieldValue.serverTimestamp(),
        'adminAprobador': adminName,
      });

      print('=== TESTIMONIO RECHAZADO EXITOSAMENTE ===');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Testimonio rechazado'),
            backgroundColor: Colors.orange,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      print('=== ERROR AL RECHAZAR TESTIMONIO ===');
      print('Testimonio ID: $testimonialId');
      print('Tipo de error: ${e.runtimeType}');
      print('Mensaje: $e');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al rechazar testimonio: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}
