import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:movie_journal/features/quesgen/review.dart';

class ReviewItem extends StatelessWidget {
  const ReviewItem({
    super.key,
    required this.review,
    required this.onPress,
    this.showAction = true,
    this.isSelected = false,
    this.transparent = false,
  });

  final Review review;
  final VoidCallback onPress;
  final bool showAction;
  final bool isSelected;
  final bool transparent;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPress,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: EdgeInsets.only(left: 16, right: 16, top: 12, bottom: 12),
        decoration: BoxDecoration(
          color: transparent ? Colors.transparent : Color(0xFF202020),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color:
                transparent ? Colors.white.withAlpha(76) : Colors.transparent,
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          spacing: 8,
          children: [
            Padding(
              padding: EdgeInsets.only(top: 4),
              child: Text(
                maxLines: 6,
                overflow: TextOverflow.ellipsis,
                review.text,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: Colors.white,
                  height: 1.4,
                ),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  spacing: 8,
                  children: [
                    _SourceIcon(source: review.source),
                    Text(
                      review.source.toUpperCase(),
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
                if (showAction) _ActionButton(isSelected: isSelected),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SourceIcon extends StatelessWidget {
  const _SourceIcon({required this.source});

  final String source;

  @override
  Widget build(BuildContext context) {
    final asset = switch (source.toLowerCase()) {
      'letterboxd' => 'assets/images/letterboxd_icon.png',
      'reddit' => 'assets/images/reddit_icon.png',
      _ => null,
    };

    if (asset == null) return SizedBox(width: 24, height: 24);

    return Image.asset(
      asset,
      width: 24,
      height: 24,
      filterQuality: FilterQuality.high,
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({required this.isSelected});

  final bool isSelected;

  static const _tealColor = Color(0xFFA8DADD);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isSelected ? _tealColor : Colors.transparent,
        border: isSelected ? null : Border.all(color: _tealColor, width: 1.333),
      ),
      child: Icon(
        isSelected ? Icons.check_rounded : Icons.add_rounded,
        color: isSelected ? Colors.black : Colors.white,
        size: 20,
      ),
    );
  }
}
