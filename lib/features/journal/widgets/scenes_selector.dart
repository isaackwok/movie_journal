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
              backgroundColor: Colors.black,
              side: BorderSide(color: Color(0xFFA8DADD), width: 2),
              padding: EdgeInsets.all(8),
            ),
            onPressed: onRemove,
            icon: Icon(Icons.close, color: Colors.white, size: 24),
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
  @override
  Widget build(BuildContext context) {
    final movieImages = ref.watch(movieImagesControllerProvider);
    final journal = ref.watch(journalControllerProvider);
    final backdrops = movieImages.backdrops;
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
        movieImages.isError
            ? const Center(child: Text('Error loading images'))
            : Skeletonizer(
              enabled: movieImages.isLoading,
              child:
                  selectedScenes.isEmpty
                      ? ConstrainedBox(
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
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder:
                                                (context) =>
                                                    ScenesSelectSheet(),
                                          ),
                                        );
                                      },
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
                      )
                      : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
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
                              style: TextStyle(
                                color: Colors.white,
                                fontFamily: 'AvenirNext',
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              textStyle: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: Colors.white,
                              ),
                              overlayColor: Color(0xFFA8DADD),
                              backgroundColor: Colors.transparent,
                              side: BorderSide(
                                color: Color(0xFFA8DADD),
                                width: 1,
                              ),
                            ),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ScenesSelectSheet(),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
            ),
      ],
    );
  }
}
