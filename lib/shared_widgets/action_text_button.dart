import 'package:flutter/material.dart';

class ActionTextButton extends StatelessWidget {
  const ActionTextButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.color,
  });

  final String text;
  final VoidCallback onPressed;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        foregroundColor: color ?? Theme.of(context).colorScheme.primary,
        overlayColor: Colors.transparent,
        padding: EdgeInsets.symmetric(horizontal: 16),
      ),
      child: Text(
        text,
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
      ),
    );
  }
}
