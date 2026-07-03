import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/playback_sync_payload.dart';
import '../models/resolved_text_style.dart';
import '../models/style_file.dart';
import '../models/slide_elements.dart';
import '../models/sub_file.dart';
import '../services/playback_sync_store.dart';

class OutputPlaybackState {
  OutputPlaybackState({
    this.sub,
    this.slideIndex = 0,
    this.isBlank = true,
    required this.payload,
  });

  final SubFile? sub;
  final int slideIndex;
  final bool isBlank;
  final PlaybackSyncPayload payload;

  OutputPlaybackState.empty()
      : sub = null,
        slideIndex = 0,
        isBlank = false,
        payload = PlaybackSyncPayload(style: StyleFile.defaultStyle);

  Slide? get currentSlide {
    final s = sub;
    if (s == null || s.slides.isEmpty || slideIndex < 0) return null;
    final idx = slideIndex.clamp(0, s.slides.length - 1);
    return s.slides[idx];
  }

  bool get isTransparentBackground =>
      payload.outputBackground == 'transparent';

  OutputPlaybackState copyWith({
    SubFile? sub,
    int? slideIndex,
    bool? isBlank,
    PlaybackSyncPayload? payload,
  }) {
    return OutputPlaybackState(
      sub: sub ?? this.sub,
      slideIndex: slideIndex ?? this.slideIndex,
      isBlank: isBlank ?? this.isBlank,
      payload: payload ?? this.payload,
    );
  }
}

class OutputPlaybackNotifier extends Notifier<OutputPlaybackState> {
  Timer? _pollTimer;
  int _lastRevision = -1;

  @override
  OutputPlaybackState build() {
    ref.onDispose(() => _pollTimer?.cancel());
    _pollTimer = Timer.periodic(
      const Duration(milliseconds: 80),
      (_) => _pollFromStore(),
    );
    final initial = _stateFromStore();
    if (initial != null) return initial;
    _pollFromStore();
    return OutputPlaybackState.empty();
  }

  OutputPlaybackState? _stateFromStore() {
    final latest = PlaybackSyncStore.readLatest();
    if (latest == null) return null;
    _lastRevision = latest.revision;
    return _stateFromPayload(latest.payload);
  }

  void _pollFromStore() {
    final latest = PlaybackSyncStore.readLatest();
    if (latest == null || latest.revision == _lastRevision) return;
    _lastRevision = latest.revision;
    applySync(latest.payload);
  }

  OutputPlaybackState _stateFromPayload(PlaybackSyncPayload payload) {
    return OutputPlaybackState(
      sub: payload.sub,
      slideIndex: payload.slideIndex,
      isBlank: payload.isBlank,
      payload: payload,
    );
  }

  void applySync(PlaybackSyncPayload payload) {
    state = _stateFromPayload(payload);
  }
}

final outputPlaybackProvider =
    NotifierProvider<OutputPlaybackNotifier, OutputPlaybackState>(
  OutputPlaybackNotifier.new,
);

StyleResolver outputStyleResolver(OutputPlaybackState state) {
  return StyleResolver(styleFile: state.payload.style);
}
