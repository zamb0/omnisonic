import 'package:flutter/widgets.dart';

/// Something on a page that paints a wash reaching up past the top of the
/// page's scroll view — today only [DetailHeader]'s cover tint.
abstract interface class TopWashSource {
  /// The wash's colour at the top edge of the page's scroll view, or null
  /// when nothing of it reaches that edge.
  Color? edgeColor();
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

  Color? get color => _sources.isEmpty ? null : _sources.last.edgeColor();

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
