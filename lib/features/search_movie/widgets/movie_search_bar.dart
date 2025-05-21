import 'package:flutter/material.dart';

class MovieSearchBar extends StatefulWidget {
  const MovieSearchBar({super.key, required this.onSubmit});

  final Function(String) onSubmit;

  @override
  State<MovieSearchBar> createState() => _MovieSearchBarState();
}

class _MovieSearchBarState extends State<MovieSearchBar> {
  final TextEditingController _controller = TextEditingController();

  void _submit(String value) {
    FocusScope.of(context).unfocus();
    widget.onSubmit(value);
  }

  @override
  Widget build(BuildContext context) {
    return SearchBar(
      keyboardType: TextInputType.text,
      controller: _controller,
      hintText: 'Search movie',
      textInputAction: TextInputAction.search,
      hintStyle: WidgetStateProperty.all(
        TextStyle(
          fontWeight: FontWeight.w500,
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
      shadowColor: WidgetStateProperty.all(Colors.transparent),
      backgroundColor: WidgetStateProperty.all(Colors.white.withAlpha(38)),
      padding: WidgetStateProperty.all(
        const EdgeInsets.symmetric(horizontal: 12),
      ),
      constraints: const BoxConstraints(maxHeight: 44),
      onChanged: (value) {},
      onSubmitted: _submit,
      trailing: [
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
