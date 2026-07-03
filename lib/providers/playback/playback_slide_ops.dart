part of 'playback.dart';

mixin PlaybackSlideOpsMixin on Notifier<PlaybackState> {
  PlaybackNotifier get _playback => this as PlaybackNotifier;

  void deleteSlide() {
    deleteSlideAt(state.slideIndex);
  }

  void deleteSlideAt(int index) {
    final sub = _playback.currentSub;
    if (sub == null || sub.slides.length <= 1) return;
    if (index < 0 || index >= sub.slides.length) return;

    final slides = [...sub.slides]..removeAt(index);
    _playback.updateSub(sub.copyWith(slides: slides));
    final nextIndex = index >= slides.length ? slides.length - 1 : index;
    state = state.copyWith(slideIndex: nextIndex);
    _playback.selectElement(null);
    _playback.syncToOutput();
  }

  void duplicateSlideAfter(int index) {
    final sub = _playback.currentSub;
    if (sub == null || index < 0 || index >= sub.slides.length) return;

    final source = sub.slides[index];
    final copy = Slide(
      tag: source.tag,
      elements: source.elements
          .map(
            (e) => e.copyWith(id: _uuid.v4()),
          )
          .toList(),
    );
    final slides = [...sub.slides];
    slides.insert(index + 1, copy);
    _playback.updateSub(sub.copyWith(slides: slides));
    state = state.copyWith(slideIndex: index + 1);
    _playback.syncToOutput();
  }

  void setSlideTag(int index, String? tag) {
    final sub = _playback.currentSub;
    if (sub == null || index < 0 || index >= sub.slides.length) return;

    final slides = [...sub.slides];
    slides[index] = slides[index].copyWith(
      tag: tag,
      clearTag: tag == null,
    );
    _playback.updateSub(sub.copyWith(slides: slides));
  }

  void updateSlideTextAt(int index, List<String> lines) {
    final sub = _playback.currentSub;
    if (sub == null || index < 0 || index >= sub.slides.length) return;

    final slide = sub.slides[index];
    var textUpdated = false;
    final elements = slide.elements.map((e) {
      if (!textUpdated && e.type == SlideElementType.text) {
        textUpdated = true;
        return e.copyWith(lines: lines);
      }
      return e;
    }).toList();

    if (!textUpdated) {
      final style = ref.read(activeStyleFileProvider);
      final region = style.primaryBodyRegion;
      elements.add(
        SlideElement(
          id: _uuid.v4(),
          type: SlideElementType.text,
          x: region.x,
          y: region.y,
          zIndex: 0,
          lines: lines,
          anchor: 'topLeft',
        ),
      );
    }

    final slides = [...sub.slides];
    slides[index] = Slide(elements: elements, tag: slide.tag);
    _playback.updateSub(sub.copyWith(slides: slides));
  }

  /// 편집 창 진입 전 — 슬라이드 미선택(-1) 상태면 첫 슬라이드로 전환
  void prepareForSlideEdit() {
    final sub = _playback.currentSub;
    if (sub == null || sub.slides.isEmpty) return;

    if (state.slideIndex < 0) {
      state = state.copyWith(slideIndex: 0);
      _playback.syncToOutput();
    }

    final idx = state.slideIndex.clamp(0, sub.slides.length - 1);
    SlideElement? firstText;
    for (final el in sub.slides[idx].elements) {
      if (el.type == SlideElementType.text) {
        firstText = el;
        break;
      }
    }
    _playback.selectElement(firstText?.id);
  }
}
