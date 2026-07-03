import 'package:flutter/material.dart';
import 'package:screen_retriever/screen_retriever.dart';

class MonitorInfo {
  const MonitorInfo({
    required this.id,
    required this.name,
    required this.width,
    required this.height,
    this.isDummy = false,
  });

  final String id;
  final String name;
  final double width;
  final double height;
  final bool isDummy;

  factory MonitorInfo.fromDisplay(Display display) {
    return MonitorInfo(
      id: display.id,
      name: display.name?.isNotEmpty == true
          ? display.name!
          : 'Display ${display.id}',
      width: display.size.width,
      height: display.size.height,
    );
  }

  String get label => '$name (${width.toInt()}×${height.toInt()})';
}

class MonitorListResult {
  const MonitorListResult({
    required this.monitors,
    this.isFallback = false,
    this.error,
  });

  final List<MonitorInfo> monitors;
  final bool isFallback;
  final String? error;
}

class MonitorService {
  static List<MonitorInfo> dummyMonitors() => const [
        MonitorInfo(
          id: 'dummy-1',
          name: '모니터 1 (더미)',
          width: 1920,
          height: 1080,
          isDummy: true,
        ),
        MonitorInfo(
          id: 'dummy-2',
          name: '모니터 2 (더미)',
          width: 1920,
          height: 1080,
          isDummy: true,
        ),
        MonitorInfo(
          id: 'dummy-3',
          name: '모니터 3 (더미)',
          width: 1920,
          height: 1080,
          isDummy: true,
        ),
      ];

  Future<MonitorListResult> listMonitors() async {
    try {
      final displays = await screenRetriever.getAllDisplays();
      if (displays.isEmpty) {
        return MonitorListResult(
          monitors: dummyMonitors(),
          isFallback: true,
          error: '연결된 모니터를 찾지 못했습니다.',
        );
      }
      return MonitorListResult(
        monitors: displays.map(MonitorInfo.fromDisplay).toList(),
      );
    } catch (e) {
      return MonitorListResult(
        monitors: dummyMonitors(),
        isFallback: true,
        error: e.toString(),
      );
    }
  }

  Future<Display?> findDisplay(String? monitorId) async {
    if (monitorId == null || monitorId.startsWith('dummy-')) return null;
    try {
      final displays = await screenRetriever.getAllDisplays();
      for (final d in displays) {
        if (d.id == monitorId) return d;
      }
      return displays.isNotEmpty ? displays.first : null;
    } catch (_) {
      return null;
    }
  }

  Future<Rect> boundsForMonitorId(String? monitorId) async {
    final display = await findDisplay(monitorId);
    if (display != null) return boundsForDisplay(display);
    return const Rect.fromLTWH(0, 0, 1920, 1080);
  }

  Rect boundsForDisplay(Display display) {
    final x = display.visiblePosition?.dx ?? 0;
    final y = display.visiblePosition?.dy ?? 0;
    final w = display.visibleSize?.width ?? display.size.width;
    final h = display.visibleSize?.height ?? display.size.height;
    return Rect.fromLTWH(x, y, w, h);
  }
}
