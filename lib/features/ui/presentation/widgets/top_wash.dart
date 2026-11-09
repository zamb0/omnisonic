import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

/// Something on a page that paints a wash reaching up past the top of the
/// page's scroll view — today only [DetailHeader]'s cover tint.
abstract interface class TopWashSource {
  /// Where the wash is on screen right now, or null when it is not laid out.
  TopWashGeometry? geometry();
}

/// A page's wash in global coordinates: a vertical gradient that holds
/// [full] down to [fadeStart] of its height, then fades out by its bottom.
@immutable
class TopWashGeometry {
  const TopWashGeometry({
    required this.viewportTop,
    required this.washTop,
    required this.washHeight,
    required this.full,
    required this.fadeStart,
  });

  /// The top edge of the page's scroll view, which clips the wash.
  final double viewportTop;
  final double washTop;
  final double washHeight;
  final Color full;

  /// Fraction of [washHeight] at which the fade begins.
  final double fadeStart;

  double get washBottom => washTop + washHeight;

  /// The wash's colour at global [y], or null outside it.
  Color? colorAt(double y) {
    if (washHeight <= 0) return null;
    final t = (y - washTop) / washHeight;
    if (t < 0 || t >= 1) return null;
    if (t <= fadeStart) return full;
    return full.withValues(
      alpha: full.a * (1 - (t - fadeStart) / (1 - fadeStart)),
    );
  }

  /// The colour at the scroll view's top edge: what the chrome above the
  /// page continues with.
  Color? get edgeColor => colorAt(viewportTop);

  /// The gradient the page paints, spread over [washRect].
  Gradient get gradient => LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [full, full, full.withValues(alpha: 0)],
    stops: [0, fadeStart, 1],
  );

  @override
  bool operator ==(Object other) =>
      other is TopWashGeometry &&
      other.viewportTop == viewportTop &&
      other.washTop == washTop &&
      other.washHeight == washHeight &&
      other.full == full &&
      other.fadeStart == fadeStart;

  @override
  int get hashCode =>
      Object.hash(viewportTop, washTop, washHeight, full, fadeStart);
}

/// Carries a page's top wash onto the chrome above the page.
///
/// On desktop the top bar sits above the page's scroll view rather than in
/// it, so a detail header's tint was clipped at the viewport's top edge and
/// met the bare canvas behind the transparent top bar in a hard line. The
/// shell paints [TopWashStrip] behind its top bar in the colour the wash has
/// at that edge, so the two read as one.
///
/// The most recently attached source wins: a page pushed over another one
/// with a header (album over artist) takes over, and hands back when it is
/// popped.
class TopWash extends ChangeNotifier {
  final List<TopWashSource> _sources = [];

  void attach(TopWashSource source) {
    _sources.add(source);
    notifyListeners();
  }

  void detach(TopWashSource source) {
    if (_sources.remove(source)) notifyListeners();
  }

  /// A source scrolled or changed: repaint the strip.
  void sourceChanged() => notifyListeners();

  TopWashGeometry? get geometry =>
      _sources.isEmpty ? null : _sources.last.geometry();

  /// The wash's colour at the top edge of the page's scroll view, or null
  /// when nothing of it reaches that edge.
  Color? get color => geometry?.edgeColor;

  /// The nearest shell's wash, or null where the page's top bar is inside
  /// its own scroll view (the phone shell) and there is nothing to carry.
  static TopWash? maybeOf(BuildContext context) =>
      context.getInheritedWidgetOfExactType<TopWashScope>()?.wash;
}

class TopWashScope extends InheritedWidget {
  const TopWashScope({super.key, required this.wash, required super.child});

  final TopWash wash;

  @override
  bool updateShouldNotify(TopWashScope oldWidget) => wash != oldWidget.wash;
}

/// Fills its box with [TopWash.color]. Repaints without rebuilding.
class TopWashStrip extends StatelessWidget {
  const TopWashStrip({super.key, required this.wash});

  final TopWash wash;

  @override
  Widget build(BuildContext context) => IgnorePointer(
    child: CustomPaint(
      painter: _TopWashPainter(wash),
      child: const SizedBox.expand(),
    ),
  );
}

class _TopWashPainter extends CustomPainter {
  _TopWashPainter(this.wash) : super(repaint: wash);

  final TopWash wash;

  @override
  void paint(Canvas canvas, Size size) {
    final color = wash.color;
    if (color == null || color.a == 0) return;
    canvas.drawRect(Offset.zero & size, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_TopWashPainter oldDelegate) => wash != oldDelegate.wash;
}

/// The page's wash continued sideways, behind the sidebar column.
///
/// A detail header's tint reaches the content column's edge and no further,
/// so on desktop it stopped in a hard vertical line at the sidebar's glass,
/// and the canvas showed around the sidebar's rounded corners. This paints
/// the same gradient at the same height across its own box: flat in the
/// colour at the scroll view's top edge above it (as [TopWashStrip] does over
/// the top bar), the page's gradient below.
class TopWashSide extends LeafRenderObjectWidget {
  const TopWashSide({super.key, required this.wash});

  final TopWash wash;

  @override
  RenderObject createRenderObject(BuildContext context) =>
      RenderTopWashSide(wash);

  @override
  void updateRenderObject(
    BuildContext context,
    RenderTopWashSide renderObject,
  ) {
    renderObject.wash = wash;
  }
}

/// Render object of [TopWashSide].
class RenderTopWashSide extends RenderBox {
  RenderTopWashSide(this._wash);

  TopWash _wash;
  set wash(TopWash value) {
    if (value == _wash) return;
    if (attached) _wash.removeListener(markNeedsPaint);
    _wash = value;
    if (attached) _wash.addListener(markNeedsPaint);
    markNeedsPaint();
  }

  @override
  void attach(PipelineOwner owner) {
    super.attach(owner);
    _wash.addListener(markNeedsPaint);
  }

  @override
  void detach() {
    _wash.removeListener(markNeedsPaint);
    super.detach();
  }

  @override
  bool get sizedByParent => true;

  @override
  Size computeDryLayout(BoxConstraints constraints) => constraints.biggest;

  @override
  void paint(PaintingContext context, Offset offset) {
    final geometry = _wash.geometry;
    if (geometry == null) return;

    // Global y to this box's paint coordinates.
    final shift = offset.dy - localToGlobal(Offset.zero).dy;
    final canvas = context.canvas;
    final bounds = offset & size;
    final viewportTop = geometry.viewportTop + shift;

    final edge = geometry.edgeColor;
    if (edge != null && edge.a > 0 && viewportTop > bounds.top) {
      canvas.drawRect(
        Rect.fromLTRB(bounds.left, bounds.top, bounds.right, viewportTop),
        Paint()..color = edge,
      );
    }

    final washRect = Rect.fromLTRB(
      bounds.left,
      geometry.washTop + shift,
      bounds.right,
      geometry.washBottom + shift,
    );
    final visible = washRect.intersect(
      Rect.fromLTRB(bounds.left, viewportTop, bounds.right, bounds.bottom),
    );
    if (visible.isEmpty || visible.height <= 0) return;
    canvas.drawRect(
      visible,
      Paint()..shader = geometry.gradient.createShader(washRect),
    );
  }
}
