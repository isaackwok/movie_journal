import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:movie_journal/themes.dart';

// Re-exported so call sites that need a non-default gravity (e.g. TOP while
// the keyboard is up) don't have to import fluttertoast themselves.
export 'package:fluttertoast/fluttertoast.dart' show ToastGravity;

class CustomToast {
  static final FToast _fToast = FToast();

  static void showSuccess(BuildContext context, String message) {
    _show(
      context: context,
      icon: Icons.check,
      statusColor: StatusColors.success,
      message: message,
    );
  }

  static void showError(
    BuildContext context,
    String message, {
    ToastGravity gravity = ToastGravity.BOTTOM,
  }) {
    _show(
      context: context,
      icon: Icons.close,
      statusColor: StatusColors.error,
      message: message,
      gravity: gravity,
    );
  }

  static void showWarning(BuildContext context, String message) {
    _show(
      context: context,
      icon: Icons.priority_high,
      statusColor: StatusColors.warning,
      message: message,
    );
  }

  /// Shared toast body: a dark bordered card with a filled status-colored icon
  /// circle (black glyph) and the message. Only the icon + accent color vary.
  ///
  /// [context] resolves the overlay at show time (FToast is re-inited on every
  /// call), so callers no longer pair each show with a `CustomToast.init`.
  static void _show({
    required BuildContext context,
    required IconData icon,
    required Color statusColor,
    required String message,
    ToastGravity gravity = ToastGravity.BOTTOM,
  }) {
    _fToast.init(context);
    _fToast.showToast(
      gravity: gravity,
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
