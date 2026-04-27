import 'package:flutter/material.dart';

class MarqueeRow extends StatelessWidget {
  final List<String> posters;
  final Animation<double> progress;
  final double viewportWidth;
  final double leadingBleed;
  final bool reverse;
  final double tileWidth;
  final double tileHeight;
  final double gap;

  const MarqueeRow({
    super.key,
    required this.posters,
    required this.progress,
    required this.viewportWidth,
    this.leadingBleed = 0,
    required this.tileWidth,
    required this.tileHeight,
    this.reverse = false,
    this.gap = 8,
  });

  @override
  Widget build(BuildContext context) {
    if (posters.isEmpty) {
      return SizedBox(width: viewportWidth, height: tileHeight);
    }

    final tileSlot = tileWidth + gap;
    final loopWidth = tileSlot * posters.length;
    final repeatCount = ((viewportWidth / loopWidth).ceil() + 2).clamp(2, 20);
    final repeated = List<String>.generate(
      posters.length * repeatCount,
      (index) => posters[index % posters.length],
    );

    return SizedBox(
      width: viewportWidth,
      height: tileHeight,
      child: ClipRect(
        child: OverflowBox(
          minWidth: 0,
          maxWidth: double.infinity,
          alignment: Alignment.centerLeft,
          child: AnimatedBuilder(
            animation: progress,
            builder: (context, _) {
              final raw = progress.value * loopWidth;
              final dx =
                  reverse
                      ? raw - loopWidth - leadingBleed
                      : -raw - leadingBleed;
              return Transform.translate(
                offset: Offset(dx, 0),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (final url in repeated)
                      Padding(
                        padding: EdgeInsets.only(right: gap),
                        child: _PosterTile(
                          url: url,
                          width: tileWidth,
                          height: tileHeight,
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _PosterTile extends StatelessWidget {
  final String url;
  final double width;
  final double height;

  const _PosterTile({
    required this.url,
    required this.width,
    required this.height,
  });

  @override
  Widget build(BuildContext context) {
    const imageWidth = 75.0;
    const imageHeight = 100.0;
    const tilePadding = EdgeInsets.fromLTRB(8, 8, 8, 12);

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: width,
        height: height,
        padding: tilePadding,
        color: Theme.of(context).colorScheme.surfaceContainer,
        child: Image.network(
          url,
          width: imageWidth,
          height: imageHeight,
          fit: BoxFit.cover,
          errorBuilder:
              (_, _, _) => Container(
                width: imageWidth,
                height: imageHeight,
                color: Colors.white10,
              ),
        ),
      ),
    );
  }
}
