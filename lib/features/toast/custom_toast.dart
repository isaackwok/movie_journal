import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:movie_journal/themes.dart';

class CustomToast {
  static final FToast _fToast = FToast();

  static void init(BuildContext context) {
    _fToast.init(context);
  }

  // `context` is retained for API compatibility with existing call sites; the
  // toast styling is context-free (status colors come from [StatusColors]).
  static void showSuccess(BuildContext context, String message) {
    _show(icon: Icons.check, statusColor: StatusColors.success, message: message);
  }

  static void showError(String message) {
    _show(icon: Icons.close, statusColor: StatusColors.error, message: message);
  }

  static void showWarning(String message) {
    _show(
      icon: Icons.priority_high,
      statusColor: StatusColors.warning,
      message: message,
    );
  }

  /// Shared toast body: a dark bordered card with a filled status-colored icon
  /// circle (black glyph) and the message. Only the icon + accent color vary.
  static void _show({
    required IconData icon,
    required Color statusColor,
    required String message,
  }) {
    _fToast.showToast(
      gravity: ToastGravity.BOTTOM,
      toastDuration: const Duration(seconds: 2),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        margin: const EdgeInsets.only(bottom: 32, left: 16, right: 16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.white.withAlpha(76), width: 1),
          color: const Color(0xFF151515),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: statusColor,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: Colors.black, size: 16),
            ),
            const SizedBox(width: 12),
            Flexible(
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  fontFamily: 'AvenirNext',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
