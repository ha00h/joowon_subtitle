enum OutputBackground { black, transparent }

class AppSettings {
  const AppSettings({
    this.workspacePath,
    this.workspaceBookmark,
    this.stylePath,
    this.styleBookmark,
    this.outputBackground = OutputBackground.black,
    this.outputMonitorId,
  });

  final String? workspacePath;
  final String? workspaceBookmark;
  final String? stylePath;
  final String? styleBookmark;
  final OutputBackground outputBackground;
  final String? outputMonitorId;

  AppSettings copyWith({
    String? workspacePath,
    String? workspaceBookmark,
    String? stylePath,
    String? styleBookmark,
    OutputBackground? outputBackground,
    String? outputMonitorId,
    bool clearWorkspacePath = false,
    bool clearWorkspaceBookmark = false,
    bool clearStylePath = false,
    bool clearStyleBookmark = false,
    bool clearOutputMonitorId = false,
  }) {
    return AppSettings(
      workspacePath:
          clearWorkspacePath ? null : (workspacePath ?? this.workspacePath),
      workspaceBookmark: clearWorkspaceBookmark
          ? null
          : (workspaceBookmark ?? this.workspaceBookmark),
      stylePath: clearStylePath ? null : (stylePath ?? this.stylePath),
      styleBookmark:
          clearStyleBookmark ? null : (styleBookmark ?? this.styleBookmark),
      outputBackground: outputBackground ?? this.outputBackground,
      outputMonitorId: clearOutputMonitorId
          ? null
          : (outputMonitorId ?? this.outputMonitorId),
    );
  }
}
