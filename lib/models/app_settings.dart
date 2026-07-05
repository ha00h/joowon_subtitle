enum OutputBackground { black, transparent }

class AppSettings {
  const AppSettings({
    this.workspacePath,
    this.workspaceBookmark,
    this.stylePath,
    this.styleBookmark,
    this.outputBackground = OutputBackground.black,
    this.outputMonitorId,
    this.operatorPanelWidth = 300,
    this.operatorSearchListRatio = 0.6,
  });

  static const defaultOperatorPanelWidth = 300.0;
  static const minOperatorPanelWidth = 240.0;
  static const maxOperatorPanelWidth = 480.0;
  static const minOperatorSearchListRatio = 0.25;
  static const maxOperatorSearchListRatio = 0.75;

  final String? workspacePath;
  final String? workspaceBookmark;
  final String? stylePath;
  final String? styleBookmark;
  final OutputBackground outputBackground;
  final String? outputMonitorId;
  final double operatorPanelWidth;
  final double operatorSearchListRatio;

  AppSettings copyWith({
    String? workspacePath,
    String? workspaceBookmark,
    String? stylePath,
    String? styleBookmark,
    OutputBackground? outputBackground,
    String? outputMonitorId,
    double? operatorPanelWidth,
    double? operatorSearchListRatio,
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
      operatorPanelWidth: operatorPanelWidth ?? this.operatorPanelWidth,
      operatorSearchListRatio:
          operatorSearchListRatio ?? this.operatorSearchListRatio,
    );
  }
}
