import 'package:flutter/material.dart';
import 'package:movie_journal/features/journal/widgets/review_item.dart';
import 'package:movie_journal/features/quesgen/review.dart';

class AiReferencesAccordion extends StatefulWidget {
  const AiReferencesAccordion({
    super.key,
    required this.references,
    required this.onRemove,
    this.defaultExpanded = false,
  });

  final List<Review> references;
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
                  Icon(
                    Icons.menu_book,
                    color: Theme.of(context).colorScheme.primary,
                    size: 24,
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Reviews',
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
                      final review = entry.value;
                      return ReviewItem(
                        review: review,
                        onPress: () => widget.onRemove(index),
                        showAction: false,
                        transparent: true,
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
