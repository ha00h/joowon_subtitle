import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../constants/app_branding.dart';
import '../../models/slide_elements.dart';
import '../../providers/output_playback_provider.dart';
import '../../widgets/canvas/canvas_renderer.dart';

/// 송출 전용 화면 — read-only CanvasRenderer, 창 전체 16:9
class OutputScreen extends ConsumerWidget {
  const OutputScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playback = ref.watch(outputPlaybackProvider);
    final resolver = outputStyleResolver(playback);
    final slide = playback.currentSlide;
    final bg = playback.isTransparentBackground
        ? Colors.transparent
        : Colors.black;

    return Material(
      color: bg,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final maxW = constraints.maxWidth;
          final maxH = constraints.maxHeight;
          if (maxW <= 0 || maxH <= 0) {
            return const SizedBox.shrink();
          }

          // 16:9 fit within window
          var w = maxW;
          var h = w * 9 / 16;
          if (h > maxH) {
            h = maxH;
            w = h * 16 / 9;
          }

          return Center(
            child: SizedBox(
              width: w,
              height: h,
              child: CanvasRenderer(
                elements: slide?.elements ?? const <SlideElement>[],
                resolveText: resolver.resolveText,
                isBlank: playback.isBlank,
                showCheckerboard: false,
              ),
            ),
          );
        },
      ),
    );
  }
}

class OutputApp extends StatelessWidget {
  const OutputApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: kAppOutputWindowTitle,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: Colors.black,
      ),
      home: const OutputScreen(),
    );
  }
}
