import 'package:flutter/material.dart';
import '../services/notification_service.dart';
import '../core/constants/app_routes.dart';

/// Widget para mostrar el icono de notificaciones con badge de cantidad no leídas
class NotificationButton extends StatelessWidget {
  final Color? iconColor;
  final double iconSize;

  const NotificationButton({
    super.key,
    this.iconColor,
    this.iconSize = 24,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<int>(
      stream: NotificationService.getUnreadCount(),
      builder: (context, snapshot) {
        final unreadCount = snapshot.data ?? 0;
        
        return Stack(
          children: [
            IconButton(
              icon: Icon(
                Icons.notifications,
                color: iconColor ?? Colors.white,
                size: iconSize,
              ),
              onPressed: () {
                Navigator.pushNamed(context, AppRoutes.notificaciones);
              },
              tooltip: 'Notificaciones',
            ),
            if (unreadCount > 0)
              Positioned(
                right: 8,
                top: 8,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: Colors.white,
                      width: 1,
                    ),
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 16,
                    minHeight: 16,
                  ),
                  child: Text(
                    unreadCount > 99 ? '99+' : unreadCount.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
