import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Widget de imagen que funciona tanto en plataformas móviles como en web
class UniversalImage extends StatelessWidget {
  final File? file;
  final Uint8List? bytes;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;

  const UniversalImage({
    super.key,
    this.file,
    this.bytes,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    Widget imageWidget;

    if (kIsWeb && bytes != null) {
      // En web, usar bytes
      imageWidget = Image.memory(
        bytes!,
        width: width,
        height: height,
        fit: fit,
      );
    } else if (!kIsWeb && file != null) {
      // En plataformas nativas, usar file
      imageWidget = Image.file(
        file!,
        width: width,
        height: height,
        fit: fit,
      );
    } else {
      // Fallback - imagen por defecto
      imageWidget = Container(
        width: width,
        height: height,
        color: Colors.grey[300],
        child: const Icon(
          Icons.image,
          color: Colors.grey,
          size: 50,
        ),
      );
    }

    if (borderRadius != null) {
      return ClipRRect(
        borderRadius: borderRadius!,
        child: imageWidget,
      );
    }

    return imageWidget;
  }
}
