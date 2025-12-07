import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:movie_journal/features/journal/controllers/journal.dart';
import 'package:movie_journal/features/journal/screens/caption_editor.dart';
import 'package:movie_journal/features/journal/widgets/scenes_select_sheet.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:movie_journal/features/movie/movie_providers.dart';

class SceneButton extends StatelessWidget {
  const SceneButton({
    super.key,
    required this.imageUrl,
    required this.onRemove,
    required this.sceneIndex,
    this.caption,
  });

  final String imageUrl;
  final VoidCallback onRemove;
  final int sceneIndex;
  final String? caption;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        showModalBottomSheet(
          useSafeArea: true,
          isScrollControlled: true,
          context: context,
          builder: (context) => CaptionEditor(initialSceneIndex: sceneIndex),
        );
        // Navigator.push(
        //   context,
        //   PageRouteBuilder(
        //     pageBuilder:
        //         (context, animation, secondaryAnimation) =>
        //             const CaptionEditor(),
        //     transitionsBuilder: (
        //       context,
        //       animation,
        //       secondaryAnimation,
        //       child,
        //     ) {
        //       const begin = Offset(0.0, 1.0);
        //       const end = Offset.zero;
        //       const curve = Curves.easeInOut;

        //       var tween = Tween(
        //         begin: begin,
        //         end: end,
        //       ).chain(CurveTween(curve: curve));
        //       var offsetAnimation = animation.drive(tween);

        //       return SlideTransition(position: offsetAnimation, child: child);
        //     },
        //   ),
        // );
      },
      child: SizedBox(
        width: 240,
        height: 175,
        child: Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                imageUrl,
                fit: BoxFit.cover,
                width: 240,
                height: 175,
              ),
            ),
            Positioned(
              top: 0,
              right: 0,
              child: IconButton(
                style: IconButton.styleFrom(
                  minimumSize: Size(24, 24),
                  padding: EdgeInsets.zero,
                  backgroundColor: Color(0xFF151515).withAlpha(204),
                  shape: CircleBorder(),
                ),
                onPressed: onRemove,
                icon: Icon(Icons.close, color: Colors.white, size: 16),
              ),
            ),
            Positioned(
              bottom: 8,
              left: 8,
              right: 8,
              child: Row(
                spacing: 4,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    padding: EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.black.withAlpha(128),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.text_fields,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),

                  if (caption != null && caption!.isNotEmpty)
                    Flexible(
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          caption!,
                          style: TextStyle(
                            color: Colors.black,
                            fontFamily: 'AvenirNext',
                            fontWeight: FontWeight.w500,
                            fontSize: 10,
                            height: 1.4,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
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

  Widget _buildSelectedScenesView(List<SceneItem> selectedScenes) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 16,
      children: [
        SizedBox(
          height: 175,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: selectedScenes.length,
            separatorBuilder: (context, index) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final scene = selectedScenes[index];
              return SceneButton(
                imageUrl: 'https://image.tmdb.org/t/p/w500${scene.path}',
                sceneIndex: index,
                caption: scene.caption,
                onRemove: () {
                  ref
                      .read(journalControllerProvider.notifier)
                      .removeScene(scene.path);
                },
              );
            },
          ),
        ),
        OutlinedButton.icon(
          onPressed: _navigateToScenesSelectSheet,
          icon: Icon(Icons.add, color: Colors.white, size: 20),
          label: Text(
            'Add Scene',
            style: TextStyle(
              color: Colors.white,
              fontFamily: 'AvenirNext',
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          style: OutlinedButton.styleFrom(
            backgroundColor: Colors.transparent,
            side: BorderSide(color: Color(0xFFA8DADD), width: 1),
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(_borderRadius),
            ),
          ),
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
