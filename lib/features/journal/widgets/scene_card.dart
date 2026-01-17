import 'package:flutter/material.dart';

class SceneCard extends StatefulWidget {
  final String imagePath;
  final String? caption;
  final TextEditingController? controller;
  final bool isEditable;

  const SceneCard({
    super.key,
    required this.imagePath,
    this.caption,
    this.controller,
    this.isEditable = false,
  });

  @override
  State<SceneCard> createState() => _SceneCardState();
}

class _SceneCardState extends State<SceneCard> {
  late TextEditingController _effectiveController;
  bool _shouldDisposeController = false;
  @override
  void initState() {
    super.initState();
    // Use provided controller or create one with caption text
    if (widget.controller != null) {
      _effectiveController = widget.controller!;
      _shouldDisposeController = false;
    } else {
      _effectiveController = TextEditingController(text: widget.caption ?? '');
      _shouldDisposeController = true;
    }
  }

  @override
  void dispose() {
    if (_shouldDisposeController) {
      _effectiveController.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isEditable) {
      return _buildEditableCard();
    } else {
      return _buildReadOnlyCard();
    }
  }

  Widget _buildEditableCard() {
    return Column(
      spacing: 0,
      mainAxisSize: MainAxisSize.min,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(8),
            topRight: Radius.circular(8),
          ),
          child: Image.network(
            'https://image.tmdb.org/t/p/w500${widget.imagePath}',
            width: double.infinity,
            height: 205,
            fit: BoxFit.cover,
          ),
        ),
        TextField(
          enabled: widget.isEditable,
          controller: _effectiveController,
          style: TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.w500,
            fontFamily: 'AvenirNext',
            height: 1.4,
          ),
          maxLines: 2,
          minLines: 1,
          decoration: InputDecoration(
            hintText: 'Add a caption...',
            hintStyle: TextStyle(
              color: Colors.white.withAlpha(153),
              fontSize: 13,
              fontWeight: FontWeight.w500,
              fontFamily: 'AvenirNext',
            ),
            filled: true,
            fillColor: Color(0xFF151515),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(8),
                bottomRight: Radius.circular(8),
              ),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(8),
                bottomRight: Radius.circular(8),
              ),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(8),
                bottomRight: Radius.circular(8),
              ),
              borderSide: BorderSide.none,
            ),
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
        ),
      ],
    );
  }

  Widget _buildReadOnlyCard() {
    final caption = widget.caption;
    final hasCaption = caption != null && caption.isNotEmpty;

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Stack(
        children: [
          Image.network(
            'https://image.tmdb.org/t/p/w500${widget.imagePath}',
            width: double.infinity,
            height: 205,
            fit: BoxFit.cover,
          ),
          if (hasCaption)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: _buildCaptionOverlay(caption),
            ),
        ],
      ),
    );
  }

  Widget _buildCaptionOverlay(String caption) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.transparent, Colors.black.withAlpha(200)],
        ),
      ),
      padding: EdgeInsets.fromLTRB(12, 24, 12, 8),
      child: _buildCaptionText(caption),
    );
  }

  Widget _buildCaptionText(String caption) {
    const textStyle = TextStyle(
      color: Colors.white,
      fontSize: 13,
      fontWeight: FontWeight.w500,
      fontFamily: 'AvenirNext',
      height: 1.4,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final textSpan = TextSpan(text: caption, style: textStyle);
        final textPainter = TextPainter(
          text: textSpan,
          maxLines: 2,
          textDirection: TextDirection.ltr,
        )..layout(maxWidth: constraints.maxWidth);

        final isOverflowing = textPainter.didExceedMaxLines;

        if (!isOverflowing) {
          return Text(
            caption,
            style: textStyle,
            maxLines: 2,
          );
        }

        // Find truncation point - calculate how much text fits with "...more" suffix
        const moreText = '...more';
        var truncatedText = caption;
        var truncatedPainter = TextPainter(
          text: TextSpan(text: '$truncatedText$moreText', style: textStyle),
          maxLines: 2,
          textDirection: TextDirection.ltr,
        )..layout(maxWidth: constraints.maxWidth);

        while (truncatedPainter.didExceedMaxLines && truncatedText.isNotEmpty) {
          truncatedText = truncatedText.substring(0, truncatedText.length - 1);
          truncatedPainter = TextPainter(
            text: TextSpan(text: '$truncatedText$moreText', style: textStyle),
            maxLines: 2,
            textDirection: TextDirection.ltr,
          )..layout(maxWidth: constraints.maxWidth);
        }

        // Trim trailing spaces and punctuation for cleaner look
        truncatedText = truncatedText.trimRight();

        return GestureDetector(
          onTap: () {
            // TODO: Expand caption on tap
          },
          child: RichText(
            maxLines: 2,
            text: TextSpan(
              style: textStyle,
              children: [
                TextSpan(text: truncatedText),
                TextSpan(
                  text: '...',
                  style: textStyle,
                ),
                TextSpan(
                  text: 'more',
                  style: textStyle.copyWith(
                    color: Colors.white.withAlpha(128),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
