import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jiffy/jiffy.dart';
import 'package:movie_journal/core/utils/color_utils.dart';
import 'package:movie_journal/features/movie/movie_providers.dart';

class PosterPreviewModal extends ConsumerStatefulWidget {
  final int movieId;
  final String movieTitle;

  const PosterPreviewModal({
    super.key,
    required this.movieId,
    required this.movieTitle,
  });

  @override
  ConsumerState<PosterPreviewModal> createState() => _PosterPreviewModalState();
}

enum ColorSchemeType {
  primary,
  primaryContainer,
  secondary,
  secondaryContainer,
  tertiary,
  tertiaryContainer,
  surface,
  surfaceContainer,
}

class _PosterPreviewModalState extends ConsumerState<PosterPreviewModal> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  final Map<int, ColorScheme?> _colorSchemes = {};
  ColorSchemeType _selectedColorType = ColorSchemeType.primaryContainer;

  @override
  void initState() {
    super.initState();
    // Fetch movie images when modal opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(movieImagesControllerProvider.notifier)
          .getMovieImages(id: widget.movieId);
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _extractColorScheme(String posterPath, int index) async {
    if (_colorSchemes.containsKey(index)) return;

    try {
      final imageProvider = NetworkImage(
        'https://image.tmdb.org/t/p/w500$posterPath',
      );

      final colorScheme = await getColors(
        imageProvider,
        Theme.of(context).brightness,
      );

      if (mounted) {
        setState(() {
          _colorSchemes[index] = colorScheme;
        });
      }
    } catch (e) {
      debugPrint('Failed to extract color scheme: $e');
    }
  }

  Color _getColorFromScheme(ColorScheme scheme) {
    switch (_selectedColorType) {
      case ColorSchemeType.primary:
        return scheme.primary;
      case ColorSchemeType.primaryContainer:
        return scheme.primaryContainer;
      case ColorSchemeType.secondary:
        return scheme.secondary;
      case ColorSchemeType.secondaryContainer:
        return scheme.secondaryContainer;
      case ColorSchemeType.tertiary:
        return scheme.tertiary;
      case ColorSchemeType.tertiaryContainer:
        return scheme.tertiaryContainer;
      case ColorSchemeType.surface:
        return scheme.surface;
      case ColorSchemeType.surfaceContainer:
        return scheme.surfaceContainer;
    }
  }

  String _getColorTypeLabel(ColorSchemeType type) {
    switch (type) {
      case ColorSchemeType.primary:
        return 'Primary';
      case ColorSchemeType.primaryContainer:
        return 'Primary Container';
      case ColorSchemeType.secondary:
        return 'Secondary';
      case ColorSchemeType.secondaryContainer:
        return 'Secondary Container';
      case ColorSchemeType.tertiary:
        return 'Tertiary';
      case ColorSchemeType.tertiaryContainer:
        return 'Tertiary Container';
      case ColorSchemeType.surface:
        return 'Surface';
      case ColorSchemeType.surfaceContainer:
        return 'Surface Container';
    }
  }

  Color _getColorByType(ColorScheme scheme, ColorSchemeType type) {
    switch (type) {
      case ColorSchemeType.primary:
        return scheme.primary;
      case ColorSchemeType.primaryContainer:
        return scheme.primaryContainer;
      case ColorSchemeType.secondary:
        return scheme.secondary;
      case ColorSchemeType.secondaryContainer:
        return scheme.secondaryContainer;
      case ColorSchemeType.tertiary:
        return scheme.tertiary;
      case ColorSchemeType.tertiaryContainer:
        return scheme.tertiaryContainer;
      case ColorSchemeType.surface:
        return scheme.surface;
      case ColorSchemeType.surfaceContainer:
        return scheme.surfaceContainer;
    }
  }

  void _showColorPicker() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Select Color Type'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children:
                  ColorSchemeType.values.map((type) {
                    return ListTile(
                      title: Text(_getColorTypeLabel(type)),
                      leading:
                          _colorSchemes[_currentPage] != null
                              ? Container(
                                width: 24,
                                height: 24,
                                decoration: BoxDecoration(
                                  color: _getColorByType(
                                    _colorSchemes[_currentPage]!,
                                    type,
                                  ),
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.grey),
                                ),
                              )
                              : null,
                      trailing:
                          _selectedColorType == type
                              ? Icon(Icons.check, color: Colors.blue)
                              : null,
                      onTap: () {
                        setState(() {
                          _selectedColorType = type;
                        });
                        Navigator.pop(context);
                      },
                    );
                  }).toList(),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final movieAsync = ref.watch(movieDetailControllerProvider);
    final imagesAsync = ref.watch(movieImagesControllerProvider);

    return Scaffold(
      backgroundColor:
          _colorSchemes[_currentPage] != null
              ? _getColorFromScheme(_colorSchemes[_currentPage]!)
              : Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            // Background with dynamic color
            if (_colorSchemes[_currentPage] != null)
              Positioned.fill(
                child: Container(
                  color: _getColorFromScheme(_colorSchemes[_currentPage]!),
                ),
              ),

            // Noise/grain texture overlay
            Positioned.fill(
              child: IgnorePointer(child: CustomPaint(painter: NoisePainter())),
            ),

            // Content
            imagesAsync.when(
              data: (imagesState) {
                final posters = imagesState.posters;

                if (posters.isEmpty) {
                  return Center(
                    child: Text(
                      'No posters available',
                      style: TextStyle(color: Colors.white),
                    ),
                  );
                }

                // Extract color for current poster
                if (_currentPage < posters.length) {
                  _extractColorScheme(
                    posters[_currentPage].filePath,
                    _currentPage,
                  );
                }

                return PageView.builder(
                  controller: _pageController,
                  itemCount: posters.length,
                  onPageChanged: (index) {
                    setState(() {
                      _currentPage = index;
                    });
                    // Preload next poster's color
                    if (index + 1 < posters.length) {
                      _extractColorScheme(
                        posters[index + 1].filePath,
                        index + 1,
                      );
                    }
                  },
                  itemBuilder: (context, index) {
                    final poster = posters[index];
                    final posterUrl =
                        'https://image.tmdb.org/t/p/w500${poster.filePath}';

                    return Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 60,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Top text: Username and date
                          Text(
                            'User // ${Jiffy.now().format(pattern: 'MM. do. yyyy.')}',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w400,
                              color: Colors.white,
                              letterSpacing: 2,
                            ),
                          ),
                          const SizedBox(height: 32),

                          // Movie poster
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                posterUrl,
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),

                          const SizedBox(height: 32),

                          // Bottom white area with movie description
                          if (movieAsync.hasValue)
                            Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.9),
                                ),
                                child: Text(
                                  movieAsync.value!.overview,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black87,
                                    height: 1.5,
                                  ),
                                  maxLines: 5,
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                );
              },
              loading:
                  () => Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  ),
              error:
                  (error, stack) => Center(
                    child: Text(
                      'Error loading posters',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
            ),

            // Color picker button (top left)
            Positioned(
              top: 16,
              left: 16,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black.withAlpha(128),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: _showColorPicker,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.palette, color: Colors.white, size: 20),
                          // const SizedBox(width: 8),
                          // Text(
                          //   _getColorTypeLabel(_selectedColorType),
                          //   style: TextStyle(
                          //     color: Colors.white,
                          //     fontSize: 14,
                          //     fontWeight: FontWeight.w500,
                          //   ),
                          // ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // Close button
            Positioned(
              top: 16,
              right: 16,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black.withAlpha(128),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close, color: Colors.white, size: 28),
                ),
              ),
            ),

            // Page counter
            Positioned(
              bottom: 16,
              left: 0,
              right: 0,
              child: imagesAsync.maybeWhen(
                data: (imagesState) {
                  if (imagesState.posters.length <= 1) return SizedBox.shrink();

                  return Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withAlpha(128),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        '${_currentPage + 1}/${imagesState.posters.length}',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  );
                },
                orElse: () => SizedBox.shrink(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Custom painter that creates a subtle noise/grain texture overlay
class NoisePainter extends CustomPainter {
  final double opacity;
  final double intensity;

  NoisePainter({this.opacity = 0.03, this.intensity = 3.0});

  @override
  void paint(Canvas canvas, Size size) {
    final random = math.Random(42); // Fixed seed for consistent pattern
    final paint = Paint();

    // Create noise pattern with small dots
    for (var i = 0; i < (size.width * size.height / 8).toInt(); i++) {
      final x = random.nextDouble() * size.width;
      final y = random.nextDouble() * size.height;
      final noiseValue = random.nextDouble();

      // Vary the opacity based on noise value
      paint.color = Colors.white.withOpacity(opacity * noiseValue * intensity);

      // Draw tiny circles for grain effect
      canvas.drawCircle(Offset(x, y), 0.5, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
