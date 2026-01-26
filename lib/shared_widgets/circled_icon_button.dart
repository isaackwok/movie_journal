import 'package:flutter/material.dart';

class CircledIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final double iconSize;
  final Color? iconColor;
  final Color? borderColor;
  final EdgeInsetsGeometry outerPadding;

  const CircledIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.iconSize = 16,
    this.iconColor,
    this.borderColor,
    this.outerPadding = const EdgeInsets.all(0),
  });

  @override
  Widget build(BuildContext context) {
    final effectiveIconColor = iconColor ?? Colors.white;
    final effectiveBorderColor =
        borderColor ?? Theme.of(context).colorScheme.primary;

    return Padding(
      padding: outerPadding,
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(icon, color: effectiveIconColor, size: iconSize),
        disabledColor: Colors.white.withAlpha(76),
        style: IconButton.styleFrom(
          shape: const CircleBorder(),
          side: BorderSide(color: effectiveBorderColor),
          alignment: Alignment.center,
          padding: EdgeInsets.zero,
        ),
      ),
    );
  }
}
