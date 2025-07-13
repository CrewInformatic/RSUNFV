import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

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
      imageWidget = Image.memory(
        bytes!,
        width: width,
        height: height,
        fit: fit,
      );
    } else if (!kIsWeb && file != null) {
      imageWidget = Image.file(
        file!,
        width: width,
        height: height,
        fit: fit,
      );
    } else {
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
