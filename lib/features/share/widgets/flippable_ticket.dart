import 'dart:math';
import 'package:flutter/material.dart';

class FlippableTicket extends StatefulWidget {
  final Widget front;
  final Widget back;
  final bool hintOnMount;

  const FlippableTicket({
    super.key,
    required this.front,
    required this.back,
    this.hintOnMount = false,
  });

  @override
  State<FlippableTicket> createState() => _FlippableTicketState();
}

class _FlippableTicketState extends State<FlippableTicket>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;
  bool _showFront = true;
  bool _peekCancelled = false;
  bool _dragStartedFromFront = true;

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

    if (widget.hintOnMount) {
      _schedulePeek();
    }
  }

  Future<void> _schedulePeek() async {
    await Future.delayed(const Duration(milliseconds: 500));
    if (!mounted || _peekCancelled) return;

    await _controller.animateTo(
      0.30,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOut,
    );
    if (!mounted || _peekCancelled) return;

    await _controller.animateBack(
      0.0,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeIn,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _flip() {
    if (_controller.isAnimating) return;
    _peekCancelled = true;
    if (_controller.isCompleted) {
      _controller.reverse();
    } else {
      _controller.forward();
    }
  }

  void _onDragStart(DragStartDetails details) {
    _peekCancelled = true;
    _dragStartedFromFront = _showFront;
    _controller.stop();
  }

  void _onDragUpdate(DragUpdateDetails details) {
    final width = context.size?.width ?? 300;
    final delta = details.delta.dx.abs() / width;
    // Direction is locked for the entire drag gesture
    if (_dragStartedFromFront) {
      _controller.value += delta;
    } else {
      _controller.value -= delta;
    }
  }

  void _onDragEnd(DragEndDetails details) {
    final velocity = (details.primaryVelocity ?? 0).abs();
    if (velocity > 300) {
      // Fling: complete the flip to the other side
      if (_dragStartedFromFront) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    } else {
      // Snap to nearest side
      if (_controller.value > 0.5) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _flip,
      onHorizontalDragStart: _onDragStart,
      onHorizontalDragUpdate: _onDragUpdate,
      onHorizontalDragEnd: _onDragEnd,
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
