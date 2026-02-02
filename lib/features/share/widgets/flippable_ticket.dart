import 'dart:math';
import 'package:flutter/material.dart';

class FlippableTicket extends StatefulWidget {
  final Widget front;
  final Widget back;

  const FlippableTicket({
    super.key,
    required this.front,
    required this.back,
  });

  @override
  State<FlippableTicket> createState() => _FlippableTicketState();
}

class _FlippableTicketState extends State<FlippableTicket>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;
  bool _showFront = true;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );

    _animation.addListener(() {
      final showFront = _animation.value < 0.5;
      if (showFront != _showFront) {
        setState(() => _showFront = showFront);
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _flip() {
    if (_controller.isAnimating) return;
    if (_controller.isCompleted) {
      _controller.reverse();
    } else {
      _controller.forward();
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _flip,
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          final angle = _animation.value * pi;
          final transform = Matrix4.identity()
            ..setEntry(3, 2, 0.001)
            ..rotateY(angle);

          // Counter-rotate back side so text isn't mirrored
          if (!_showFront) {
            transform.rotateY(pi);
          }

          return Transform(
            alignment: Alignment.center,
            transform: transform,
            child: _showFront ? widget.front : widget.back,
          );
        },
      ),
    );
  }
}
