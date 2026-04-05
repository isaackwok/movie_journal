import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:movie_journal/features/journal/controllers/journal.dart';
import 'package:movie_journal/features/quesgen/review.dart';
import 'package:movie_journal/features/journal/widgets/review_item.dart';
import 'package:movie_journal/analytics_manager.dart';
import 'package:movie_journal/features/journal/widgets/reviews_bottom_sheet.dart';
import 'package:movie_journal/features/journal/widgets/reviews_floating_button.dart';
import 'package:movie_journal/shared_widgets/action_text_button.dart';

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
    AnalyticsManager.logScreenView('Thoughts');
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

  void _openReviewsBottomSheet() {
    showModalBottomSheet(
      useSafeArea: true,
      isScrollControlled: true,
      context: context,
      backgroundColor: const Color(0xFF171717),
      builder: (context) => const Wrap(children: [ReviewsBottomSheet()]),
    );
  }

  Widget _buildSelectedReviewsSection(
    List<Review> references, {
    required bool isEditMode,
  }) {
    final cardWidth = MediaQuery.of(context).size.width - 64;
    final itemCount = isEditMode ? references.length : references.length + 1;
    return ListView.separated(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: itemCount,
      separatorBuilder: (_, _) => const SizedBox(width: 12),
      itemBuilder: (context, index) {
        if (!isEditMode && index == references.length) {
          return _buildAddCard();
        }
        return SizedBox(
          width: cardWidth,
          child: ReviewItem(
            review: references[index],
            onPress: isEditMode ? () {} : _openReviewsBottomSheet,
            showAction: false,
          ),
        );
      },
    );
  }

  Widget _buildAddCard() {
    return GestureDetector(
      onTap: _openReviewsBottomSheet,
      child: Container(
        width: 100,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Color(0xFF202020),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add, color: Colors.white, size: 24),
            const SizedBox(height: 4),
            Text(
              'Add',
              style: GoogleFonts.inter(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final selectedReferences =
        ref.watch(journalControllerProvider).selectedRefs;
    final isEditMode = ref.watch(journalModeProvider) == JournalMode.edit;
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        titleSpacing: 0,
        centerTitle: true,
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
                  'Thoughts',
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
                  .setThoughts(thoughtsController.text);
              Navigator.pop(context);
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        controller: scrollController,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (selectedReferences.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: SizedBox(
                  height: 175,
                  child: _buildSelectedReviewsSection(
                    selectedReferences,
                    isEditMode: isEditMode,
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
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
            ),
          ],
        ),
      ),
      floatingActionButton: isEditMode ? null : const ReviewsFloatingButton(),
      floatingActionButtonLocation: FloatingActionButtonLocation.startFloat,
    );
  }
}
