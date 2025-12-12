import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:movie_journal/features/journal/controllers/journal.dart';
import 'package:movie_journal/features/journal/widgets/scene_card.dart';

class CaptionEditor extends ConsumerStatefulWidget {
  final int initialSceneIndex;

  const CaptionEditor({super.key, required this.initialSceneIndex});

  @override
  ConsumerState<CaptionEditor> createState() => _CaptionEditorState();
}

class _CaptionEditorState extends ConsumerState<CaptionEditor> {
  late PageController _pageController;
  late Map<String, TextEditingController> _captionControllers;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _currentPage = widget.initialSceneIndex;
    _pageController = PageController(initialPage: widget.initialSceneIndex);

    // Initialize caption controllers for each scene
    final selectedScenes = ref.read(journalControllerProvider).selectedScenes;
    _captionControllers = {};

    for (final scene in selectedScenes) {
      _captionControllers[scene.path] = TextEditingController(
        text: scene.caption ?? '',
      );
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    // Dispose all caption controllers
    for (final controller in _captionControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _onPageChanged(int page) {
    setState(() {
      _currentPage = page;
    });
  }

  void _saveAllCaptions() {
    // Save all captions to Riverpod
    for (final entry in _captionControllers.entries) {
      final scenePath = entry.key;
      final caption = entry.value.text;
      ref
          .read(journalControllerProvider.notifier)
          .updateSceneCaption(scenePath, caption);
    }
    Navigator.pop(context);
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
                      color: Theme.of(context).colorScheme.primary,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'AvenirNext',
                      height: 1.4,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: _saveAllCaptions,
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    backgroundColor: Colors.transparent,
                  ),
                  child: Text(
                    'Done',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
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
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: SizedBox(
                height: 260,
                child: PageView.builder(
                  controller: _pageController,
                  onPageChanged: _onPageChanged,
                  itemCount: selectedScenes.length,
                  itemBuilder: (context, index) {
                    final scene = selectedScenes[index];
                    final controller = _captionControllers[scene.path];

                    return SingleChildScrollView(
                      child: SceneCard(
                        imagePath: scene.path,
                        controller: controller,
                        isEditable: true,
                      ),
                    );
                  },
                ),
              ),
            ),
            SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: SizedBox(
                width: double.infinity,
                height: 24,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Centered dots
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      spacing: 4,
                      children: List.generate(
                        selectedScenes.length,
                        (index) => Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color:
                                index == _currentPage
                                    ? Colors.white
                                    : Colors.white.withAlpha(77),
                          ),
                        ),
                      ),
                    ),
                    // Text positioned on the right
                    Positioned(
                      right: 0,
                      child: Text(
                        '${_currentPage + 1} of ${selectedScenes.length}',
                        style: TextStyle(
                          color: Colors.white.withAlpha(153),
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          fontFamily: 'AvenirNext',
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
