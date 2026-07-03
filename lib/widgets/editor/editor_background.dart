import 'dart:convert';

import 'package:flutter/material.dart';

import '../../models/style_file.dart';

class EditorBackground extends StatelessWidget {
  const EditorBackground({
    required this.background,
    required this.child,
    super.key,
  });

  final BackgroundConfig background;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: _decoration(background),
      child: child,
    );
  }

  BoxDecoration _decoration(BackgroundConfig bg) {
    switch (bg.type) {
      case 'color':
        return BoxDecoration(color: _parseColor(bg.color ?? '#000000'));
      case 'image':
        if (bg.imageData != null && bg.imageData!.isNotEmpty) {
          try {
            final bytes = base64Decode(bg.imageData!);
            return BoxDecoration(
              image: DecorationImage(
                image: MemoryImage(bytes),
                fit: BoxFit.cover,
              ),
            );
          } catch (_) {
            return const BoxDecoration(color: Colors.black);
          }
        }
        return const BoxDecoration(color: Colors.black);
      case 'black':
      default:
        return const BoxDecoration(color: Colors.black);
    }
  }

  Color _parseColor(String hex) {
    var value = hex.replaceFirst('#', '');
    if (value.length == 6) value = 'FF$value';
    return Color(int.parse(value, radix: 16));
  }
}
