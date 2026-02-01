class Review {
  final String text;
  final String source; // "letterboxd", "reddit"

  Review({required this.text, required this.source});

  Map<String, dynamic> toMap() => {'text': text, 'source': source};

  static Review fromMap(Map<String, dynamic> map) {
    return Review(
      text: map['text'] as String,
      source: map['source'] as String,
    );
  }

  // Backward compatibility: parse from old string format
  static Review fromString(String text) {
    return Review(text: text, source: 'unknown');
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Review &&
          runtimeType == other.runtimeType &&
          text == other.text &&
          source == other.source;

  @override
  int get hashCode => text.hashCode ^ source.hashCode;
}
