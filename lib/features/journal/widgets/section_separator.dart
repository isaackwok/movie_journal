import 'package:flutter/material.dart';

/// The thin horizontal rule between JournalingScreen sections.
class SectionSeparator extends StatelessWidget {
  const SectionSeparator({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 36),
      child: Container(height: 0.5, color: Colors.white.withAlpha(76)),
    );
  }
}
