import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:movie_journal/features/journal/controllers/journal.dart';
import 'package:movie_journal/features/journal/widgets/scenes_select_sheet.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:movie_journal/features/movie/movie_providers.dart';

class SceneButton extends StatelessWidget {
  const SceneButton({
    super.key,
    required this.imageUrl,
    required this.onRemove,
  });

  final String imageUrl;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.network(
            imageUrl,
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
          ),
        ),
        Positioned(
          top: 0,
          right: 0,
          child: IconButton(
            style: IconButton.styleFrom(
              minimumSize: Size(24, 24),
              backgroundColor: Colors.black,
              side: BorderSide(color: Color(0xFFA8DADD), width: 1),
            ),
            onPressed: onRemove,
            icon: Icon(Icons.close, color: Colors.white, size: 16),
          ),
        ),
      ],
    );
  }
}

class ScenesSelector extends ConsumerStatefulWidget {
  const ScenesSelector({super.key, required this.movieId});
  final int movieId;

  @override
  ConsumerState<ScenesSelector> createState() => _ScenesSelectorState();
}

class _ScenesSelectorState extends ConsumerState<ScenesSelector> {
  static const double _borderRadius = 16.0;
  static const double _minMaxHeight = 215.0;
  static const Color _accentColor = Color(0xFFA8DADD);

  void _navigateToScenesSelectSheet() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => ScenesSelectSheet()),
    );
  }

  Widget _buildEmptyScenesView(String firstBackdropPath) {
    return ConstrainedBox(
      constraints: const BoxConstraints(
        minHeight: _minMaxHeight,
        maxHeight: _minMaxHeight,
      ),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(_borderRadius),
            child: Image.network(
              'https://image.tmdb.org/t/p/w500$firstBackdropPath',
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
              errorBuilder: (context, error, stackTrace) {
                return const Center(child: Text('Error loading image'));
              },
            ),
          ),
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(_borderRadius),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black.withAlpha(102),
                  borderRadius: BorderRadius.circular(_borderRadius),
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: _navigateToScenesSelectSheet,
                    borderRadius: BorderRadius.circular(8),
                    child: Center(
                      child: Text(
                        "+  Add Scenes",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'AvenirNext',
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectedScenesView(List<String> selectedScenes) {
    return Column(
      spacing: 16,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GridView.builder(
          padding: EdgeInsets.zero,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            mainAxisExtent: 120,
          ),
          itemCount: selectedScenes.length,
          itemBuilder: (context, index) {
            return SceneButton(
              imageUrl:
                  'https://image.tmdb.org/t/p/w500${selectedScenes[index]}',
              onRemove: () {
                ref
                    .read(journalControllerProvider.notifier)
                    .removeScene(selectedScenes[index]);
              },
            );
          },
        ),
        ElevatedButton.icon(
          icon: Icon(Icons.add, color: Colors.white),
          label: Text(
            'Add Scenes',
            style: TextStyle(color: Colors.white, fontFamily: 'AvenirNext'),
          ),
          style: ElevatedButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(_borderRadius),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            textStyle: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.white,
            ),
            overlayColor: _accentColor,
            backgroundColor: Colors.transparent,
            side: BorderSide(color: _accentColor, width: 1),
          ),
          onPressed: _navigateToScenesSelectSheet,
        ),
      ],
    );
  }

  Widget _buildEmptyBackdropsState() {
    return Container(
      height: _minMaxHeight,
      decoration: BoxDecoration(
        color: Color(0xFF1C1C1E),
        borderRadius: BorderRadius.circular(_borderRadius),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Scene missing!',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w600,
                fontFamily: 'AvenirNext',
              ),
            ),
            SizedBox(height: 8),
            Text(
              "We couldn't find any scene photos for this movie.",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontFamily: 'AvenirNext',
                letterSpacing: 0,
              ),
            ),
            SizedBox(height: 4),
            Text(
              'Keep this one in your memory. ✨',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                letterSpacing: 0,
                fontSize: 14,
                fontFamily: 'AvenirNext',
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final movieImagesAsync = ref.watch(movieImagesControllerProvider);
    final journal = ref.watch(journalControllerProvider);
    final selectedScenes = journal.selectedScenes;

    return Column(
      spacing: 16,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'What are the memorable scenes?',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            fontFamily: 'AvenirNext',
          ),
        ),
        movieImagesAsync.when(
          data: (movieImages) {
            final backdrops = movieImages.backdrops;
            if (backdrops.isEmpty) {
              return _buildEmptyBackdropsState();
            }

            return selectedScenes.isEmpty
                ? _buildEmptyScenesView(backdrops[0].filePath)
                : _buildSelectedScenesView(selectedScenes);
          },
          loading:
              () => Skeletonizer(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    minHeight: _minMaxHeight,
                    maxHeight: _minMaxHeight,
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(_borderRadius),
                    child: Bone(width: double.infinity, height: _minMaxHeight),
                  ),
                ),
              ),
          error:
              (error, stack) =>
                  const Center(child: Text('Error loading images')),
        ),
      ],
    );
  }
}
