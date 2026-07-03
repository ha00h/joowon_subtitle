import 'dart:convert';

enum WindowType { operator, output }

class WindowArgs {
  const WindowArgs({
    required this.type,
    this.monitorId,
    this.outputBackground = 'black',
  });

  final WindowType type;
  final String? monitorId;
  /// `black` | `transparent`
  final String outputBackground;

  bool get isOutput => type == WindowType.output;

  String encode() => jsonEncode({
        'type': type.name,
        if (monitorId != null) 'monitorId': monitorId,
        'outputBackground': outputBackground,
      });

  static WindowArgs decode(String raw) {
    if (raw.isEmpty) {
      return const WindowArgs(type: WindowType.operator);
    }
    try {
      final json = jsonDecode(raw) as Map<String, dynamic>;
      return WindowArgs(
        type: WindowType.values.byName(
          json['type'] as String? ?? WindowType.operator.name,
        ),
        monitorId: json['monitorId'] as String?,
        outputBackground: json['outputBackground'] as String? ?? 'black',
      );
    } catch (_) {
      return const WindowArgs(type: WindowType.operator);
    }
  }
}
