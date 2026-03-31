import 'package:flutter/material.dart';

class PulseRipple extends StatefulWidget {
  final Widget child;
  final Color color;
  final bool shouldRotate;

  const PulseRipple({
    required this.child,
    required this.color,
    this.shouldRotate = false,
    super.key,
  });

  @override
  State<PulseRipple> createState() => _PulseRippleState();
}

class _PulseRippleState extends State<PulseRipple> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(); // ignore: discarded_futures
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        _buildRipple(0),
        _buildRipple(0.5),
        if (widget.shouldRotate)
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Transform.rotate(
                angle: _controller.value * 6.28318,
                child: child,
              );
            },
            child: widget.child,
          )
        else
          widget.child,
      ],
    );
  }

  Widget _buildRipple(double delay) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final value = (_controller.value + delay) % 1.0;
        return Opacity(
          opacity: (1.0 - value) * 0.5,
          child: Transform.scale(
            scale: 1.0 + (value * 0.5),
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: widget.color.withValues(alpha: 0.2),
              ),
            ),
          ),
        );
      },
    );
  }
}
