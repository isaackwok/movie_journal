import 'package:flutter/material.dart';

class ConfirmationDialog extends StatelessWidget {
  final String title;
  final String description;
  final String cancelText;
  final String confirmText;
  final Function onCancel;
  final Function onConfirm;
  final TextStyle cancelTextStyle;
  final TextStyle confirmTextStyle;
  final TextStyle titleTextStyle;
  final TextStyle descriptionTextStyle;

  const ConfirmationDialog({
    super.key,
    required this.title,
    required this.description,
    required this.onCancel,
    required this.onConfirm,
    this.cancelText = 'Cancel',
    this.confirmText = 'Confirm',
    this.titleTextStyle = const TextStyle(
      fontFamily: 'AvenirNext',
      fontSize: 24,
      fontWeight: FontWeight.w500,
      height: 1.5,
      color: Colors.white,
    ),
    this.descriptionTextStyle = const TextStyle(
      fontFamily: 'AvenirNext',
      fontSize: 14,
      fontWeight: FontWeight.w400,
      height: 1.4,
      color: Colors.white,
    ),
    this.cancelTextStyle = const TextStyle(
      fontFamily: 'AvenirNext',
      fontSize: 14,
      fontWeight: FontWeight.w500,
      height: 1.4,
      color: Colors.white,
    ),
    this.confirmTextStyle = const TextStyle(
      fontFamily: 'AvenirNext',
      fontSize: 14,
      fontWeight: FontWeight.w500,
      height: 1.4,
      color: Color(0xFFFF615D),
    ),
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Color(0xFF151515),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: titleTextStyle, textAlign: TextAlign.left),
            const SizedBox(height: 24),
            Text(
              description,
              style: descriptionTextStyle,
              textAlign: TextAlign.left,
            ),
            const SizedBox(height: 40),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () {
                    onCancel();
                  },
                  style: TextButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                  child: Text(cancelText, style: cancelTextStyle),
                ),
                TextButton(
                  onPressed: () {
                    onConfirm();
                  },
                  style: TextButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                  child: Text(confirmText, style: confirmTextStyle),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
