import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/app_release_info.dart';
import '../services/update_service.dart';

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

class UpdateNotifier extends Notifier<UpdateState> {
  static const _boxName = 'app_settings';
  static const _skippedVersionKey = 'skippedUpdateVersion';
  static const _lastCheckKey = 'lastUpdateCheckAt';
  static const _checkCooldown = Duration(hours: 24);

  late final UpdateService _service;
  Box<String>? _box;

  @override
  UpdateState build() {
    _service = UpdateService();
    unawaited(_initCurrentVersion());
    return const UpdateState();
  }

  Future<void> _initCurrentVersion() async {
    final version = await _service.currentVersion();
    state = state.copyWith(currentVersion: version);
  }

  Future<Box<String>> _settingsBox() async {
    _box ??= Hive.isBoxOpen(_boxName)
        ? Hive.box<String>(_boxName)
        : await Hive.openBox<String>(_boxName);
    return _box!;
  }

  Future<void> checkAutomatic() async {
    final box = await _settingsBox();
    final lastCheckRaw = box.get(_lastCheckKey);
    if (lastCheckRaw != null) {
      final lastCheck = DateTime.tryParse(lastCheckRaw);
      if (lastCheck != null &&
          DateTime.now().difference(lastCheck) < _checkCooldown) {
        return;
      }
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

      final box = await _settingsBox();
      await box.put(_lastCheckKey, DateTime.now().toIso8601String());

      final skipped = box.get(_skippedVersionKey);
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
    final box = await _settingsBox();
    await box.put(_skippedVersionKey, version);
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
