import 'package:flutter/material.dart';

class SceneCard extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return Column(
      spacing: 0,
      mainAxisSize: MainAxisSize.min,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(12),
            topRight: Radius.circular(12),
          ),
          child: Image.network(
            'https://image.tmdb.org/t/p/original$imagePath',
            width: double.infinity,
            height: 205,
            fit: BoxFit.cover,
          ),
        ),
        TextField(
          enabled: isEditable,
          controller: controller,
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
            hintText: isEditable ? 'Add a caption...' : '<No caption>',
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
}
