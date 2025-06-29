import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:movie_journal/features/home/widgets/add_movie_button.dart';
import 'package:movie_journal/features/home/widgets/empty_placeholder.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
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
                      '0 movie journals',
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
        child: const EmptyPlaceholder(),
      ),
    );
  }
}
