import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:movie_journal/features/journal/controllers/journal.dart';
import 'package:movie_journal/features/movie/movie_providers.dart';

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

class ScenesSelectSheet extends ConsumerWidget {
  const ScenesSelectSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final movieImages = ref.watch(movieImagesControllerProvider);
    final backdrops = movieImages.backdrops;
    final journal = ref.watch(journalControllerProvider);
    final selectedScenes = journal.selectedScenes;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: SingleChildScrollView(
          child: Column(
            spacing: 8,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${selectedScenes.length} selected',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  fontFamily: 'AvenirNext',
                  color: Color(0xFFA0A0A0),
                ),
              ),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                  mainAxisExtent: 123,
                ),
                itemCount: backdrops.length,
                itemBuilder: (context, index) {
                  final backdrop = backdrops[index];

                  return SceneButton(
                    index: selectedScenes.indexOf(backdrop.filePath),
                    imageUrl:
                        'https://image.tmdb.org/t/p/w500${backdrops[index].filePath}',
                    isSelected: selectedScenes.contains(backdrop.filePath),
                    onTap: () {
                      // TODO: if selected scenes is greater than 10, show toast and do nothing
                      if (selectedScenes.contains(backdrop.filePath)) {
                        ref
                            .read(journalControllerProvider.notifier)
                            .removeScene(backdrop.filePath);
                      } else {
                        ref
                            .read(journalControllerProvider.notifier)
                            .addScene(backdrop.filePath);
                      }
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ),
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        title: Column(children: [Text('Scenes')]),
        centerTitle: false,
        titleTextStyle: TextStyle(fontSize: 24, fontWeight: FontWeight.w500),
        automaticallyImplyLeading: false,
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              shadowColor: Colors.transparent,
              surfaceTintColor: Colors.transparent,
              overlayColor: Colors.transparent,
              backgroundColor: Colors.transparent,
              foregroundColor: Color(0xFFA8DADD),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: Text(
              'Done',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}
