import 'package:flutter/material.dart';
import 'package:movie_journal/features/search_movie/screens/search_movie.dart';

class EmptyPlaceholder extends StatelessWidget {
  const EmptyPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Center(
          child: Column(
            children: [
              SizedBox(height: constraints.maxHeight * 0.3),
              Text('📝', style: TextStyle(fontSize: 24)),
              SizedBox(height: 16),
              Text(
                'Your personal film archive starts here',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'AvenirNext',
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 4),
              SizedBox(
                width: 288,
                child: Text(
                  'Add your first movie to keep your memories going.',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                    fontFamily: 'AvenirNext',
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              SizedBox(height: 24),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => SearchMovieScreen(),
                    ),
                  );
                },
                child: Text('Add Movie'),
              ),
            ],
          ),
        );
      },
    );
  }
}
