import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:movie_journal/features/journal/controllers/journal.dart';
import 'package:movie_journal/features/journal/widgets/ai_references_accordion.dart';
import 'package:movie_journal/features/journal/widgets/questions_bottom_sheet.dart';
import 'package:movie_journal/features/movie/movie_providers.dart';
import 'package:movie_journal/features/quesgen/provider.dart';

class ThoughtsScreen extends ConsumerStatefulWidget {
  const ThoughtsScreen({super.key});

  @override
  ConsumerState<ThoughtsScreen> createState() => _ThoughtsScreenState();
}

class _ThoughtsScreenState extends ConsumerState<ThoughtsScreen> {
  final TextEditingController thoughtsController = TextEditingController(
    text: '',
  );
  final ScrollController scrollController = ScrollController();
  final GlobalKey textFieldKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    thoughtsController.text = ref.read(journalControllerProvider).thoughts;
    thoughtsController.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    thoughtsController.removeListener(_onTextChanged);
    thoughtsController.dispose();
    scrollController.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToCursor();
    });
  }

  void _scrollToCursor() {
    if (!mounted) return;

    final RenderBox? renderBox =
        textFieldKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    // Get the text painter to calculate cursor position
    final textPainter = TextPainter(
      text: TextSpan(
        text: thoughtsController.text,
        style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w400),
      ),
      textDirection: TextDirection.ltr,
      maxLines: null,
    );

    textPainter.layout(maxWidth: renderBox.size.width);

    // Get cursor offset
    final cursorOffset = textPainter.getOffsetForCaret(
      TextPosition(offset: thoughtsController.selection.baseOffset),
      Rect.zero,
    );

    // Calculate the cursor's global position
    final textFieldOffset = renderBox.localToGlobal(Offset.zero);
    final cursorGlobalY = textFieldOffset.dy + cursorOffset.dy;

    // Get viewport bounds
    final viewportHeight = MediaQuery.of(context).size.height;
    final appBarHeight =
        AppBar().preferredSize.height + MediaQuery.of(context).padding.top;
    final visibleTop = appBarHeight;
    final visibleBottom =
        viewportHeight - 100; // Account for floating action button

    // Check if cursor is outside viewport
    if (cursorGlobalY < visibleTop || cursorGlobalY > visibleBottom) {
      // Calculate target scroll position
      final currentScroll = scrollController.offset;
      final targetScroll =
          currentScroll +
          (cursorGlobalY - (visibleTop + 100)); // 100px padding from top

      // Animate to target position
      scrollController.animateTo(
        targetScroll.clamp(0.0, scrollController.position.maxScrollExtent),
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
      );
    }

    textPainter.dispose();
  }

  void _onReferencesButtonPressed(BuildContext context) {
    final movieAsync = ref.read(movieDetailControllerProvider);
    final movie = movieAsync.hasValue ? movieAsync.value : null;
    final quesgenState = ref.read(quesgenControllerProvider);
    if (movie != null && quesgenState.questions.isEmpty) {
      ref
          .read(quesgenControllerProvider.notifier)
          .generateQuestions(movieId: movie.id);
    }
    if (context.mounted) {
      showModalBottomSheet(
        useSafeArea: true,
        isScrollControlled: true,
        context: context,
        backgroundColor: Color(0xFF171717),
        builder: (context) => Wrap(children: [QuestionsBottomSheet()]),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedReferences =
        ref.watch(journalControllerProvider).selectedQuestions;
    return Scaffold(
      appBar: AppBar(
        title: Text('Thoughts & Feelings'),
        automaticallyImplyLeading: false,
        centerTitle: false,
        titleTextStyle: TextStyle(fontSize: 24, fontWeight: FontWeight.w500),
        actions: [
          ElevatedButton(
            onPressed: () {
              ref
                  .read(journalControllerProvider.notifier)
                  .setThoughts(thoughtsController.text);
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
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: SingleChildScrollView(
          controller: scrollController,
          child: Column(
            spacing: 8,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                key: textFieldKey,
                controller: thoughtsController,
                autofocus: true,
                onTapOutside:
                    (event) => FocusManager.instance.primaryFocus?.unfocus(),
                maxLines: null,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                ),
                decoration: InputDecoration(
                  hintText: 'Enter your text here...',
                  hintStyle: GoogleFonts.nothingYouCouldDo(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.white.withAlpha(128),
                  ),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  disabledBorder: InputBorder.none,
                  errorBorder: InputBorder.none,
                  focusedErrorBorder: InputBorder.none,
                  fillColor: Colors.transparent,
                ),
              ),
              selectedReferences.isNotEmpty
                  ? AiReferencesAccordion(
                    defaultExpanded: true,
                    references: selectedReferences,
                    onRemove: (index) {
                      ref
                          .read(journalControllerProvider.notifier)
                          .removeSelectedQuestion(selectedReferences[index]);
                    },
                  )
                  : SizedBox.shrink(),
            ],
          ),
        ),
      ),
      floatingActionButton: ElevatedButton.icon(
        icon: Icon(Icons.menu_book, color: Colors.white),
        label: Text(
          'AI References',
          style: TextStyle(color: Colors.white, fontFamily: 'AvenirNext'),
        ),
        style: ElevatedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.white,
          ),
          overlayColor: Color(0xFFA8DADD),
          backgroundColor: Colors.black,
          side: BorderSide(color: Color(0xFFA8DADD), width: 1),
        ),
        onPressed: () => _onReferencesButtonPressed(context),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.startFloat,
    );
  }
}
