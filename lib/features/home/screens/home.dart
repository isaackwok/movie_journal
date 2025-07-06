import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:movie_journal/features/home/widgets/add_movie_button.dart';
import 'package:movie_journal/features/home/widgets/empty_placeholder.dart';
import 'package:movie_journal/features/home/widgets/journals_list.dart';
import 'package:movie_journal/features/journal/controllers/journals.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final journals = ref.watch(journalsControllerProvider).journals;
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        toolbarHeight: 76,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                // Image.asset('assets/images/avatar.png', width: 60, height: 60),
                SvgPicture.asset(
                  'assets/images/avatar.svg',
                  width: 60,
                  height: 60,
                ),
                SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Jessie',
                      style: GoogleFonts.nothingYouCouldDo(
                        fontSize: 28,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      '${journals.length} movie journals',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const AddMovieButton(),
          ],
        ),
        centerTitle: false,
      ),
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: 20),
        child:
            journals.isEmpty ? const EmptyPlaceholder() : const JournalsList(),
      ),
    );
  }
}
