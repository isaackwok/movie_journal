import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:movie_journal/features/movie/movie_providers.dart';

class SceneButton extends StatelessWidget {
  const SceneButton({
    super.key,
    required this.imageUrl,
    required this.isSelected,
    required this.onTap,
    this.overlay,
  });

  final String imageUrl;
  final bool isSelected;
  final VoidCallback onTap;
  final String? overlay;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        ClipRRect(
          // borderRadius: BorderRadius.circular(8),
          child: Image.network(
            imageUrl,
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
          ),
        ),
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          decoration: BoxDecoration(
            border:
                isSelected
                    ? Border.all(
                      color: Theme.of(context).primaryColor,
                      width: 2,
                    )
                    : Border.all(color: Colors.transparent, width: 2),
            // borderRadius: BorderRadius.circular(8),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              highlightColor: Colors.transparent,
              splashColor: Colors.transparent,
              onTap: onTap,
              child: SizedBox(width: double.infinity, height: double.infinity),
            ),
          ),
        ),
        if (overlay != null)
          Positioned.fill(
            child: ClipRRect(
              // borderRadius: BorderRadius.circular(8),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black.withAlpha(76),
                  // borderRadius: BorderRadius.circular(8),
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: onTap,
                    // borderRadius: BorderRadius.circular(8),
                    child: Center(
                      child: Text(
                        overlay!,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
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
  Set<int> selectedScenes = {};

  void _toggleScene(int index) {
    setState(() {
      if (selectedScenes.contains(index)) {
        selectedScenes.remove(index);
      } else {
        selectedScenes.add(index);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final movieImages = ref.watch(movieImagesControllerProvider);
    final backdrops = movieImages.backdrops;

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
        movieImages.isError
            ? const Center(child: Text('Error loading images'))
            : Skeletonizer(
              enabled: movieImages.isLoading,
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  minHeight: 215,
                  maxHeight: 215,
                ),
                child: Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.network(
                        'https://image.tmdb.org/t/p/w500${backdrops[0].filePath}',
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: double.infinity,
                        errorBuilder: (context, error, stackTrace) {
                          return const Center(
                            child: Text('Error loading image'),
                          );
                        },
                      ),
                    ),
                    Positioned.fill(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.black.withAlpha(102),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () {
                                // TODO: Add a modal to select the scenes
                              },
                              // borderRadius: BorderRadius.circular(8),
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
              ),
              // child: GridView.builder(
              //   shrinkWrap: true,
              //   physics: const NeverScrollableScrollPhysics(),
              //   gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              //     crossAxisCount: 2,
              //     childAspectRatio: 16 / 9,
              //     crossAxisSpacing: 4,
              //     mainAxisSpacing: 4,
              //     mainAxisExtent: 123,
              //   ),
              //   itemCount: 6,
              //   itemBuilder: (context, index) {
              //     if (index == 5) {
              //       return SceneButton(
              //         imageUrl:
              //             'https://image.tmdb.org/t/p/w500${backdrops[index].filePath}',
              //         isSelected: selectedScenes.contains(index),
              //         onTap: () {
              //           // TODO: Add a modal to select the scenes
              //         },
              //         overlay: '+${backdrops.length - 6}',
              //       );
              //     }

              //     return SceneButton(
              //       imageUrl:
              //           'https://image.tmdb.org/t/p/w500${backdrops[index].filePath}',
              //       isSelected: selectedScenes.contains(index),
              //       onTap: () => _toggleScene(index),
              //     );
              //   },
              // ),
            ),
      ],
    );
  }
}
