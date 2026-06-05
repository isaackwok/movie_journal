import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:movie_journal/features/journal/controllers/journal.dart';
import 'package:movie_journal/features/movie/movie_providers.dart';
import 'package:movie_journal/features/movie/data/models/movie_image.dart';
import 'package:movie_journal/features/toast/custom_toast.dart';
import 'package:movie_journal/shared_widgets/action_text_button.dart';

class SceneButton extends StatelessWidget {
  const SceneButton({
    super.key,
    required this.index,
    required this.imageUrl,
    required this.isSelected,
    required this.onTap,
  });

  final int index;
  final String imageUrl;
  final bool isSelected;
  final VoidCallback onTap;

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
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          decoration: BoxDecoration(
            border:
                isSelected
                    ? Border.all(color: Colors.white, width: 2)
                    : Border.all(color: Colors.transparent, width: 2),
            borderRadius: BorderRadius.circular(8),
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
        if (isSelected)
          Positioned(
            top: 8,
            right: 8,
            child: Container(
              alignment: Alignment.center,
              constraints: BoxConstraints(
                minWidth: 20,
                minHeight: 20,
                maxWidth: 20,
                maxHeight: 20,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: Text(
                '${index + 1}',
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class ScenesSelectSheet extends ConsumerStatefulWidget {
  const ScenesSelectSheet({super.key});

  @override
  ConsumerState<ScenesSelectSheet> createState() => _ScenesSelectSheetState();
}

class _ScenesSelectSheetState extends ConsumerState<ScenesSelectSheet> {
  static const int _maxSceneLimit = 10;
  late List<SceneItem> _localSelectedScenes;

  @override
  void initState() {
    super.initState();
    _localSelectedScenes = List.from(
      ref.read(journalControllerProvider).selectedScenes,
    );
  }

  @override
  Widget build(BuildContext context) {
    final movieImagesAsync = ref.watch(movieImagesControllerProvider);
    final backdrops =
        movieImagesAsync.hasValue
            ? movieImagesAsync.value!.backdrops
            : <MovieImage>[];
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Sticky count header — stays visible while the grid scrolls.
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'Select up to $_maxSceneLimit (${_localSelectedScenes.length}/$_maxSceneLimit)',
                style: TextStyle(
                  fontFamily: 'AvenirNext',
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  height: 1.5,
                  color: Colors.white.withAlpha(153),
                ),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                child: GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                    mainAxisExtent: 123,
                  ),
                  itemCount: backdrops.length,
                  itemBuilder: (context, index) {
                    final backdrop = backdrops[index];
                    final isSelected = _localSelectedScenes.any(
                      (scene) => scene.path == backdrop.filePath,
                    );
                    final selectedIndex = _localSelectedScenes.indexWhere(
                      (scene) => scene.path == backdrop.filePath,
                    );

                    return SceneButton(
                      index: selectedIndex,
                      imageUrl:
                          'https://image.tmdb.org/t/p/w500${backdrops[index].filePath}',
                      isSelected: isSelected,
                      onTap: () {
                        if (isSelected) {
                          setState(() {
                            _localSelectedScenes.removeWhere(
                              (scene) => scene.path == backdrop.filePath,
                            );
                          });
                          return;
                        }
                        if (_localSelectedScenes.length >= _maxSceneLimit) {
                          CustomToast.init(context);
                          CustomToast.showError(
                            'You can select up to $_maxSceneLimit scenes',
                          );
                          return;
                        }
                        setState(() {
                          _localSelectedScenes.add(
                            SceneItem(path: backdrop.filePath),
                          );
                        });
                      },
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        automaticallyImplyLeading: false,
        titleSpacing: 0,
        title: Row(
          children: [
            ActionTextButton(
              text: 'Cancel',
              color: Colors.white,
              onPressed: () {
                Navigator.pop(context);
              },
            ),
            Expanded(
              child: Center(
                child: Text(
                  'Scenes',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.w500),
                ),
              ),
            ),
          ],
        ),
        actions: [
          ActionTextButton(
            text: 'Done',
            onPressed: () {
              ref
                  .read(journalControllerProvider.notifier)
                  .setSelectedScenes(_localSelectedScenes);
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }
}
