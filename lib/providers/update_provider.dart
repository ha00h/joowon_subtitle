import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/app_release_info.dart';
import '../repositories/app_settings_repository.dart';
import '../services/update_service.dart';
import 'settings_provider.dart' show appSettingsRepositoryProvider;

enum UpdateStatus { idle, checking, upToDate, available, error }

class UpdateState {
  const UpdateState({
    this.status = UpdateStatus.idle,
    this.currentVersion,
    this.release,
    this.errorMessage,
    this.pendingDialog = false,
  });

  final UpdateStatus status;
  final String? currentVersion;
  final AppReleaseInfo? release;
  final String? errorMessage;
  final bool pendingDialog;

  UpdateState copyWith({
    UpdateStatus? status,
    String? currentVersion,
    AppReleaseInfo? release,
    String? errorMessage,
    bool? pendingDialog,
    bool clearRelease = false,
    bool clearError = false,
  }) {
    return UpdateState(
      status: status ?? this.status,
      currentVersion: currentVersion ?? this.currentVersion,
      release: clearRelease ? null : (release ?? this.release),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      pendingDialog: pendingDialog ?? this.pendingDialog,
    );
  }
}

final updateServiceProvider = Provider<UpdateService>((ref) => UpdateService());

class UpdateNotifier extends Notifier<UpdateState> {
  static const _checkCooldown = Duration(hours: 24);

  late final UpdateService _service;
  late AppSettingsRepository _repo;

  @override
  UpdateState build() {
    _service = ref.read(updateServiceProvider);
    _repo = ref.read(appSettingsRepositoryProvider);
    unawaited(_initCurrentVersion());
    return const UpdateState();
  }

  Future<void> _initCurrentVersion() async {
    final version = await _service.currentVersion();
    state = state.copyWith(currentVersion: version);
  }

  Future<void> checkAutomatic() async {
    await _repo.init();
    final lastCheck = _repo.readLastUpdateCheckAt();
    if (lastCheck != null &&
        DateTime.now().difference(lastCheck) < _checkCooldown) {
      return;
    }

    await _check(showDialogOnAvailable: true);
  }

  Future<void> checkManual() => _check(showDialogOnAvailable: false);

  Future<void> _check({required bool showDialogOnAvailable}) async {
    state = state.copyWith(
      status: UpdateStatus.checking,
      clearError: true,
      pendingDialog: false,
    );

    try {
      final current = state.currentVersion ?? await _service.currentVersion();
      final release = await _service.fetchLatestRelease();

      if (release == null) {
        throw UpdateCheckException('릴리스 정보를 읽을 수 없습니다.');
      }

      await _repo.init();
      await _repo.writeLastUpdateCheckAt(DateTime.now());

      final skipped = _repo.readSkippedUpdateVersion();
      final hasUpdate = _service.isNewerVersion(current, release.version);

      if (!hasUpdate || release.version == skipped) {
        state = state.copyWith(
          status: UpdateStatus.upToDate,
          currentVersion: current,
          clearRelease: true,
        );
        return;
      }

      state = state.copyWith(
        status: UpdateStatus.available,
        currentVersion: current,
        release: release,
        pendingDialog: showDialogOnAvailable,
      );
    } on UpdateCheckException catch (e) {
      state = state.copyWith(
        status: UpdateStatus.error,
        errorMessage: e.message,
        clearRelease: true,
      );
    } catch (e) {
      state = state.copyWith(
        status: UpdateStatus.error,
        errorMessage: '업데이트 확인 실패: $e',
        clearRelease: true,
      );
    }
  }

  Future<void> skipVersion(String version) async {
    await _repo.init();
    await _repo.writeSkippedUpdateVersion(version);
    state = state.copyWith(
      status: UpdateStatus.upToDate,
      pendingDialog: false,
      clearRelease: true,
    );
  }

  void dismissForNow() {
    state = state.copyWith(
      status: UpdateStatus.upToDate,
      pendingDialog: false,
      clearRelease: true,
    );
  }

  void clearPendingDialog() {
    if (!state.pendingDialog) return;
    state = state.copyWith(pendingDialog: false);
  }

  Future<bool> openDownload(AppReleaseInfo release) async {
    final url = release.downloadUrl ?? release.releasePageUrl;
    final uri = Uri.parse(url);
    return launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}

final updateProvider =
    NotifierProvider<UpdateNotifier, UpdateState>(UpdateNotifier.new);
