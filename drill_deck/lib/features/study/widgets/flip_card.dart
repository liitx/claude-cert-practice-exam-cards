import 'package:flutter/material.dart';

/// Front-to-back flip animation around the Y axis. Uses a single animation
/// controller so we get a real 180-degree rotation rather than a crossfade.
/// The hidden face is always built but masked behind the visible one.
class FlipCard extends StatefulWidget {
  const FlipCard({
    required this.flipped,
    required this.front,
    required this.back,
    super.key,
  });

  final bool flipped;
  final Widget front;
  final Widget back;

  @override
  State<FlipCard> createState() => _FlipCardState();
}

class _FlipCardState extends State<FlipCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
      value: widget.flipped ? 1 : 0,
    );
  }

  @override
  void didUpdateWidget(covariant FlipCard old) {
    super.didUpdateWidget(old);
    if (widget.flipped != old.flipped) {
      if (widget.flipped) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final t = _controller.value;
        final angle = t * 3.1415926535;
        final showingBack = t > 0.5;

        // 3D Y-axis rotation. Add a touch of perspective.
        final transform = Matrix4.identity()
          ..setEntry(3, 2, 0.001)
          ..rotateY(angle);

        return Transform(
          transform: transform,
          alignment: Alignment.center,
          child: showingBack
              ? Transform(
                  transform: Matrix4.identity()..rotateY(3.1415926535),
                  alignment: Alignment.center,
                  child: widget.back,
                )
              : widget.front,
        );
      },
    );
  }
}
