import 'package:flutter/material.dart';
import 'package:movie_journal/shared_widgets/action_text_button.dart';

/// The Cancel / centered-title / Done app bar used by the full-screen sheets
/// (ThoughtsScreen, ScenesSelectSheet, CaptionEditor).
///
/// [title] is optional — CaptionEditor shows only the two actions.
class SheetAppBar extends StatelessWidget implements PreferredSizeWidget {
  const SheetAppBar({
    super.key,
    this.title,
    required this.onCancel,
    required this.onDone,
    this.backgroundColor,
  });

  final String? title;
  final VoidCallback onCancel;
  final VoidCallback onDone;
  final Color? backgroundColor;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: backgroundColor,
      elevation: 0,
      automaticallyImplyLeading: false,
      titleSpacing: 0,
      title: Row(
        children: [
          ActionTextButton(
            text: 'Cancel',
            color: Colors.white,
            onPressed: onCancel,
          ),
          if (title != null)
            Expanded(
              child: Center(
                child: Text(
                  title!,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
        ],
      ),
      actions: [ActionTextButton(text: 'Done', onPressed: onDone)],
    );
  }
}
