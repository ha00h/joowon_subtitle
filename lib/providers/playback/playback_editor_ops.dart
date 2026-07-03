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

    final region = style.primaryBodyRegion;
    final text = style.text;

    List<SlideElement> styledElements(List<SlideElement> elements) {
      return elements
          .map(
            (e) => applyStyleConfigToTextElement(
              e,
              text,
              x: region.x,
              y: region.y,
            ),
          )
          .toList();
    }

    if (allSlides) {
      final slides = sub.slides
          .map((s) => Slide(elements: styledElements(s.elements)))
          .toList();
      _playback.updateSub(sub.copyWith(slides: slides));
      return;
    }

    final idx = state.slideIndex;
    if (idx < 0 || idx >= sub.slides.length) return;
    final slides = [...sub.slides];
    slides[idx] = Slide(elements: styledElements(slides[idx].elements));
    _playback.updateSub(sub.copyWith(slides: slides));
  }
}
