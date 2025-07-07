import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/notification_service.dart';
import '../services/cloudinary_services.dart';
import '../services/local_notification_service.dart';
import '../core/theme/app_colors.dart';
import '../widgets/drawer.dart';
import '../models/usuario.dart';

/// Pantalla de bandeja de notificaciones
class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  bool _showOnlyUnread = false;
  Usuario? _currentUser;

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
  }

  Future<void> _loadCurrentUser() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final userDoc = await FirebaseFirestore.instance
            .collection('usuarios')
            .doc(user.uid)
            .get();
        
        if (userDoc.exists && mounted) {
          setState(() {
            _currentUser = Usuario.fromMap({
              ...userDoc.data()!,
              'idUsuario': userDoc.id,
            });
          });
        }
      }
    } catch (e) {
      // Error silencioso para no romper la pantalla
      debugPrint('Error loading current user: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notificaciones'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          // Filtro de solo no leídas
          IconButton(
            icon: Icon(
              _showOnlyUnread ? Icons.mark_email_read : Icons.mark_email_unread,
            ),
            onPressed: () {
              setState(() {
                _showOnlyUnread = !_showOnlyUnread;
              });
            },
            tooltip: _showOnlyUnread ? 'Mostrar todas' : 'Solo no leídas',
          ),
          // Marcar todas como leídas
          IconButton(
            icon: const Icon(Icons.done_all),
            onPressed: () async {
              final scaffoldMessenger = ScaffoldMessenger.of(context);
              await NotificationService.markAllAsRead();
              if (mounted) {
                scaffoldMessenger.showSnackBar(
                  const SnackBar(
                    content: Text('Todas las notificaciones marcadas como leídas'),
                    backgroundColor: AppColors.success,
                  ),
                );
              }
            },
            tooltip: 'Marcar todas como leídas',
          ),
          // Botón de prueba de notificación local
          IconButton(
            icon: const Icon(Icons.notification_add),
            onPressed: () async {
              await LocalNotificationService.showInstantNotification(
                id: DateTime.now().millisecondsSinceEpoch,
                title: '🧪 Notificación de Prueba',
                body: 'Esta es una notificación flotante de prueba desde RSUNFV',
                priority: NotificationPriority.high,
              );
              
              final scaffoldMessenger = ScaffoldMessenger.of(context);
              scaffoldMessenger.showSnackBar(
                const SnackBar(
                  content: Text('Notificación de prueba enviada'),
                  backgroundColor: AppColors.success,
                ),
              );
            },
            tooltip: 'Probar notificación flotante',
          ),
        ],
      ),
      drawer: MyDrawer(
        currentImage: _currentUser?.fotoPerfil ?? CloudinaryService.defaultAvatarUrl,
      ),
      body: StreamBuilder<List<NotificationData>>(
        stream: NotificationService.getUserNotifications(
          soloNoLeidas: _showOnlyUnread,
        ),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                color: AppColors.primary,
              ),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Colors.red,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Error al cargar notificaciones',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Por favor, intenta nuevamente',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.mediumText,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {});
                    },
                    child: const Text('Reintentar'),
                  ),
                ],
              ),
            );
          }

          final notifications = snapshot.data ?? [];

          if (notifications.isEmpty) {
            return _buildEmptyState();
          }

          return RefreshIndicator(
            onRefresh: () async {
              setState(() {});
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: notifications.length,
              itemBuilder: (context, index) {
                final notification = notifications[index];
                return _buildNotificationCard(notification);
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _showOnlyUnread ? Icons.mark_email_read : Icons.notifications_none,
            size: 80,
            color: AppColors.mediumText,
          ),
          const SizedBox(height: 16),
          Text(
            _showOnlyUnread 
                ? 'No tienes notificaciones sin leer'
                : 'No tienes notificaciones',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: AppColors.mediumText,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _showOnlyUnread
                ? 'Todas tus notificaciones han sido leídas'
                : 'Te notificaremos sobre eventos y donaciones',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.mediumText,
            ),
            textAlign: TextAlign.center,
          ),
          if (_showOnlyUnread) ...[
            const SizedBox(height: 16),
            TextButton(
              onPressed: () {
                setState(() {
                  _showOnlyUnread = false;
                });
              },
              child: const Text('Ver todas las notificaciones'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildNotificationCard(NotificationData notification) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: notification.leida ? 1 : 3,
      color: notification.leida ? null : AppColors.primary.withValues(alpha: 0.05),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () => _handleNotificationTap(notification),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icono del tipo de notificación
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _getNotificationColor(notification.tipo).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(
                  _getNotificationIcon(notification.tipo),
                  color: _getNotificationColor(notification.tipo),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              
              // Contenido de la notificación
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            notification.titulo,
                            style: TextStyle(
                              fontWeight: notification.leida 
                                  ? FontWeight.normal 
                                  : FontWeight.bold,
                              fontSize: 16,
                              color: AppColors.darkText,
                            ),
                          ),
                        ),
                        if (!notification.leida)
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      notification.mensaje,
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.mediumText,
                        height: 1.3,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _formatDate(notification.fechaCreacion),
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.mediumText,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Menú de opciones
              PopupMenuButton<String>(
                icon: const Icon(
                  Icons.more_vert,
                  color: AppColors.mediumText,
                ),
                onSelected: (value) => _handleMenuAction(value, notification),
                itemBuilder: (context) => [
                  if (!notification.leida)
                    const PopupMenuItem(
                      value: 'mark_read',
                      child: Row(
                        children: [
                          Icon(Icons.mark_email_read, size: 18),
                          SizedBox(width: 8),
                          Text('Marcar como leída'),
                        ],
                      ),
                    ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete, size: 18, color: Colors.red),
                        SizedBox(width: 8),
                        Text('Eliminar', style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getNotificationIcon(NotificationType tipo) {
    switch (tipo) {
      case NotificationType.eventoProximo:
        return Icons.schedule;
      case NotificationType.eventoNuevo:
        return Icons.event;
      case NotificationType.donacionVerificada:
        return Icons.verified;
      case NotificationType.recordatorioEvento:
        return Icons.alarm;
      case NotificationType.inscripcionEvento:
        return Icons.how_to_reg;
    }
  }

  Color _getNotificationColor(NotificationType tipo) {
    switch (tipo) {
      case NotificationType.eventoProximo:
        return Colors.orange;
      case NotificationType.eventoNuevo:
        return AppColors.primary;
      case NotificationType.donacionVerificada:
        return AppColors.success;
      case NotificationType.recordatorioEvento:
        return Colors.red;
      case NotificationType.inscripcionEvento:
        return Colors.blue;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inMinutes < 1) {
      return 'Ahora';
    } else if (difference.inHours < 1) {
      return 'Hace ${difference.inMinutes} min';
    } else if (difference.inDays < 1) {
      return 'Hace ${difference.inHours} h';
    } else if (difference.inDays < 7) {
      return 'Hace ${difference.inDays} días';
    } else {
      return DateFormat('dd/MM/yyyy').format(date);
    }
  }

  void _handleNotificationTap(NotificationData notification) async {
    // Marcar como leída si no lo está
    if (!notification.leida) {
      await NotificationService.markAsRead(notification.id);
    }

    // Navegar según el tipo de notificación
    if (mounted) {
      switch (notification.tipo) {
        case NotificationType.eventoProximo:
        case NotificationType.eventoNuevo:
        case NotificationType.recordatorioEvento:
        case NotificationType.inscripcionEvento:
          if (notification.eventoId != null) {
            Navigator.pushNamed(
              context,
              '/evento_detalle',
              arguments: {'id': notification.eventoId},
            );
          }
          break;
        case NotificationType.donacionVerificada:
          Navigator.pushNamed(context, '/donaciones');
          break;
      }
    }
  }

  void _handleMenuAction(String action, NotificationData notification) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    
    switch (action) {
      case 'mark_read':
        await NotificationService.markAsRead(notification.id);
        if (mounted) {
          scaffoldMessenger.showSnackBar(
            const SnackBar(
              content: Text('Notificación marcada como leída'),
              backgroundColor: AppColors.success,
            ),
          );
        }
        break;
      case 'delete':
        await NotificationService.deleteNotification(notification.id);
        if (mounted) {
          scaffoldMessenger.showSnackBar(
            const SnackBar(
              content: Text('Notificación eliminada'),
              backgroundColor: AppColors.success,
            ),
          );
        }
        break;
    }
  }
}
