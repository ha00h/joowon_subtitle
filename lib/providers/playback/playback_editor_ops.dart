part of 'playback.dart';

mixin PlaybackEditorOpsMixin on Notifier<PlaybackState> {
  PlaybackNotifier get _playback => this as PlaybackNotifier;

  void updateElement(SlideElement updated) {
    final elements = _playback.currentElements()
        .map((e) => e.id == updated.id ? updated : e)
        .toList();
    _playback.updateCurrentSlideElements(elements);
  }

  void moveElement(String id, double x, double y, {bool recordUndo = true}) {
    if (recordUndo) _playback.pushUndo();
    final elements = _playback.currentElements().map((e) {
      if (e.id != id) return e;
      return e.copyWith(x: x.clamp(0, 100), y: y.clamp(0, 100));
    }).toList();
    final updated = _playback.buildUpdatedSub(elements);
    if (updated != null) {
      _playback.applySub(updated, syncOutput: true);
    }
  }

  void updateTextLines(String id, List<String> lines) {
    final elements = _playback.currentElements().map((e) {
      if (e.id != id) return e;
      return e.copyWith(lines: lines);
    }).toList();
    _playback.updateCurrentSlideElements(elements);
  }

  void applyStyleToSlide(StyleFile style, {bool allSlides = false}) {
    final sub = _playback.currentSub;
    if (sub == null) return;

    final bodyRegion = style.primaryBodyRegion;
    final labelRegion = style.primaryVerseLabelRegion;

    List<SlideElement> styledElements(List<SlideElement> elements) {
      return elements.map((e) {
        if (e.type == SlideElementType.verseLabel) {
          return applyStyleConfigToTextElement(
            e,
            style.verseLabel,
            x: labelRegion.x,
            y: labelRegion.y,
            width: labelRegion.width,
            height: labelRegion.height,
          );
        }
        if (e.type == SlideElementType.text) {
          return applyStyleConfigToTextElement(
            e,
            style.text,
            x: bodyRegion.x,
            y: bodyRegion.y,
            width: bodyRegion.width,
            height: bodyRegion.height,
          );
        }
        return e;
      }).toList();
    }

    if (allSlides) {
      final slides = sub.slides
          .map(
            (s) => Slide(
              elements: styledElements(s.elements),
              tag: s.tag,
              colorTag: s.colorTag,
            ),
          )
          .toList();
      _playback.updateSub(sub.copyWith(slides: slides));
      return;
    }

    final idx = state.slideIndex;
    if (idx < 0 || idx >= sub.slides.length) return;
    final slides = [...sub.slides];
    slides[idx] = Slide(
      elements: styledElements(slides[idx].elements),
      tag: slides[idx].tag,
      colorTag: slides[idx].colorTag,
    );
    _playback.updateSub(sub.copyWith(slides: slides));
  }

  /// 텍스트 요소의 개별 스타일 override를 제거해 활성 스타일 기본값을 따르게 함.
  void clearSlideTextStyleOverrides({bool allSlides = false}) {
    final sub = _playback.currentSub;
    if (sub == null) return;

    List<SlideElement> cleared(List<SlideElement> elements) {
      return elements
          .map(
            (e) => isTextLikeElement(e.type) ? clearTextStyleOverrides(e) : e,
          )
          .toList();
    }

    if (allSlides) {
      final slides = sub.slides
          .map(
            (s) => Slide(
              elements: cleared(s.elements),
              tag: s.tag,
              colorTag: s.colorTag,
            ),
          )
          .toList();
      _playback.updateSub(sub.copyWith(slides: slides));
      return;
    }

    final idx = state.slideIndex;
    if (idx < 0 || idx >= sub.slides.length) return;
    final slides = [...sub.slides];
    slides[idx] = Slide(
      elements: cleared(slides[idx].elements),
      tag: slides[idx].tag,
      colorTag: slides[idx].colorTag,
    );
    _playback.updateSub(sub.copyWith(slides: slides));
  }
}
