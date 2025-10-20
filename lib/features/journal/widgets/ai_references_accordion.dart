import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AiReferencesAccordion extends StatefulWidget {
  const AiReferencesAccordion({
    super.key,
    required this.references,
    required this.onRemove,
    this.defaultExpanded = false,
  });

  final List<String> references;
  final Function(int index) onRemove;
  final bool defaultExpanded;
  @override
  State<AiReferencesAccordion> createState() => _AiReferencesAccordionState();
}

class _AiReferencesAccordionState extends State<AiReferencesAccordion>
    with TickerProviderStateMixin {
  bool _isExpanded = false;
  late AnimationController _animationController;
  late Animation<double> _expandAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: Duration(milliseconds: 100),
      vsync: this,
    );
    _expandAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    if (widget.defaultExpanded) {
      _isExpanded = true;
      _animationController.forward();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _toggleExpansion() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(16)),
      child: Column(
        children: [
          InkWell(
            onTap: _toggleExpansion,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(Icons.menu_book, color: Color(0xFFA8DADD), size: 24),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'References',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  AnimatedRotation(
                    turns: _isExpanded ? 0.5 : 0,
                    duration: Duration(milliseconds: 100),
                    child: Icon(
                      Icons.keyboard_arrow_down,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizeTransition(
            sizeFactor: _expandAnimation,
            child: Padding(
              padding: EdgeInsets.only(top: 16, bottom: 8),
              child: Column(
                spacing: 12,
                children:
                    widget.references.asMap().entries.map((entry) {
                      final index = entry.key;
                      final reference = entry.value;
                      return _ReferenceCard(
                        reference: reference,
                        onRemove: () => widget.onRemove(index),
                      );
                    }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReferenceCard extends StatelessWidget {
  const _ReferenceCard({required this.reference, required this.onRemove});

  final String reference;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    // Parse the reference to extract title and content
    final lines = reference.split('\n');
    final title = lines.first;
    final content = lines.length > 1 ? lines.sublist(1).join('\n').trim() : '';

    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Color(0xFF404040), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: Colors.white,
                    height: 1.4,
                  ),
                ),
              ),
              SizedBox(width: 8),
              GestureDetector(
                onTap: onRemove,
                child: Container(
                  padding: EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Icon(
                    Icons.bookmark,
                    color: Color(0xFFA8DADD),
                    size: 24,
                  ),
                ),
              ),
            ],
          ),
          if (content.isNotEmpty) ...[
            SizedBox(height: 12),
            Text(
              content,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: Colors.white.withValues(alpha: 0.8),
                height: 1.4,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
