import 'dart:io';

import 'package:flutter/material.dart';

import '../../domain/entities/symbol.dart';

class Reel extends StatefulWidget {
  const Reel({super.key, required this.symbol, required this.spinning, required this.available});
  final SlotSymbol? symbol;
  final bool spinning;
  final List<SlotSymbol> available;

  @override
  State<Reel> createState() => _ReelState();
}

class _ReelState extends State<Reel> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 130));
  var _frame = 0;
  double _lastValue = 0;

  @override
  void didUpdateWidget(covariant Reel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.spinning && !_controller.isAnimating) _controller.repeat();
    if (!widget.spinning && _controller.isAnimating) _controller.stop();
  }

  @override
  void dispose() { _controller.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _controller,
    builder: (context, _) {
      if (widget.spinning && widget.available.isNotEmpty) {
        if (_controller.value < _lastValue) _frame = (_frame + 1) % widget.available.length;
        _lastValue = _controller.value;
      } else {
        _lastValue = 0;
      }
      final symbol = widget.spinning && widget.available.isNotEmpty
          ? widget.available[_frame % widget.available.length]
          : widget.symbol;
      return AspectRatio(
        aspectRatio: .78,
        child: Container(
          padding: const EdgeInsets.all(5),
          decoration: BoxDecoration(
            color: const Color(0xFFFFD47C),
            borderRadius: BorderRadius.circular(17),
            boxShadow: const [BoxShadow(color: Colors.black38, blurRadius: 5, offset: Offset(0, 3))],
          ),
          child: Container(
            decoration: BoxDecoration(color: const Color(0xFFFFF8E9), borderRadius: BorderRadius.circular(13)),
            clipBehavior: Clip.antiAlias,
            child: symbol?.imagePath == null
                ? const Center(child: Icon(Icons.image_outlined, color: Color(0xFFBBAF9C), size: 36))
                : Image.file(File(symbol!.imagePath!), fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => const Center(child: Icon(Icons.broken_image_outlined, color: Color(0xFFBBAF9C), size: 36))),
          ),
        ),
      );
    },
  );
}
