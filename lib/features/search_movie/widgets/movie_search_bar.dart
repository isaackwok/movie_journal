import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:movie_journal/features/movie/movie_providers.dart';

class MovieSearchBar extends ConsumerStatefulWidget {
  const MovieSearchBar({super.key});

  @override
  ConsumerState<MovieSearchBar> createState() => _MovieSearchBarState();
}

class _MovieSearchBarState extends ConsumerState<MovieSearchBar> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  void _submit(String value) {
    FocusScope.of(context).unfocus();
    ref.read(searchMovieControllerProvider.notifier).search(value);
  }

  @override
  Widget build(BuildContext context) {
    return SearchBar(
      keyboardType: TextInputType.text,
      controller: _controller,
      focusNode: _focusNode,
      hintText: 'Search movie',
      textInputAction: TextInputAction.search,
      hintStyle: WidgetStateProperty.all(
        TextStyle(
          fontWeight: FontWeight.w600,
          color: Color(0xFFA0A0A0),
          fontSize: 16,
        ),
      ),
      textStyle: WidgetStateProperty.all(
        TextStyle(
          fontWeight: FontWeight.w600,
          color: Colors.white,
          fontSize: 16,
        ),
      ),
      side: WidgetStateProperty.all(
        BorderSide(color: Colors.white.withAlpha(77), width: 1),
      ),
      shadowColor: WidgetStateProperty.all(Colors.transparent),
      backgroundColor: WidgetStateProperty.all(Colors.transparent),
      padding: WidgetStateProperty.all(
        const EdgeInsets.symmetric(horizontal: 12),
      ),
      constraints: const BoxConstraints(maxHeight: 44, minHeight: 44),
      onSubmitted: _submit,
      trailing: [
        // TODO: Add clear button when focus and text is not empty
        IconButton(
          onPressed: () {
            _submit(_controller.text);
          },
          icon: const Icon(Icons.search, size: 24, color: Colors.white),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
