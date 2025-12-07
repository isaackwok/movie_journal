import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:movie_journal/features/journal/controllers/journal.dart';

class CaptionEditor extends ConsumerStatefulWidget {
  final int initialSceneIndex;

  const CaptionEditor({
    super.key,
    required this.initialSceneIndex,
  });

  @override
  ConsumerState<CaptionEditor> createState() => _CaptionEditorState();
}

class _CaptionEditorState extends ConsumerState<CaptionEditor> {
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: widget.initialSceneIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final selectedScenes = ref.watch(journalControllerProvider).selectedScenes;

    return SizedBox(
      height: MediaQuery.of(context).size.height,
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black,
          elevation: 0,
          automaticallyImplyLeading: false,
          title: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    backgroundColor: Colors.transparent,
                  ),
                  child: Text(
                    'Cancel',
                    style: TextStyle(
                      color: Color(0xFFA8DADD),
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'AvenirNext',
                      height: 1.4,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    // Leave empty for now
                  },
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    backgroundColor: Colors.transparent,
                  ),
                  child: Text(
                    'Done',
                    style: TextStyle(
                      color: Color(0xFFA8DADD),
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'AvenirNext',
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
          titleSpacing: 0,
        ),
        body: Column(
          children: [
            SizedBox(height: 55),
            SizedBox(
              height: 205,
              child: PageView.builder(
                controller: _pageController,
                itemCount: selectedScenes.length,
                itemBuilder: (context, index) {
                  final scenePath = selectedScenes[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        'https://image.tmdb.org/t/p/original$scenePath',
                        width: double.infinity,
                        height: 205,
                        fit: BoxFit.cover,
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
