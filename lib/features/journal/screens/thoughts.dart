import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:movie_journal/features/journal/controllers/journal.dart';

class ThoughtsScreen extends ConsumerStatefulWidget {
  const ThoughtsScreen({super.key});

  @override
  ConsumerState<ThoughtsScreen> createState() => _ThoughtsScreenState();
}

class _ThoughtsScreenState extends ConsumerState<ThoughtsScreen> {
  final TextEditingController thoughtsController = TextEditingController(
    text: '',
  );

  @override
  void initState() {
    super.initState();
    thoughtsController.text = ref.read(journalControllerProvider).thoughts;
  }

  @override
  Widget build(BuildContext context) {
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
          child: Column(
            spacing: 8,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
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
            ],
          ),
        ),
      ),
    );
  }
}
