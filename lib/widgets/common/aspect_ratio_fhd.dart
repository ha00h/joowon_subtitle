import 'package:flutter/material.dart';

/// FHD 16:9 캔버스 컨테이너 (MVP §3.13)
class AspectRatioFhd extends StatelessWidget {
  const AspectRatioFhd({
    super.key,
    required this.child,
    this.backgroundColor,
  });

  final Widget child;
  final Color? backgroundColor;

  static const aspectRatio = 16 / 9;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: aspectRatio,
      child: Container(
        color: backgroundColor ?? Colors.black,
        child: child,
      ),
    );
  }
}
