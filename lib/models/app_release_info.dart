class AppReleaseInfo {
  const AppReleaseInfo({
    required this.version,
    required this.releasePageUrl,
    this.downloadUrl,
    this.releaseNotes,
  });

  final String version;
  final String releasePageUrl;
  final String? downloadUrl;
  final String? releaseNotes;
}
