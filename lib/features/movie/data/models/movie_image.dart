class MovieImage {
  final String filePath;
  final double aspectRatio;
  final int height;
  final int width;
  final String? iso6391;
  final double voteAverage;
  final int voteCount;

  MovieImage({
    required this.filePath,
    required this.aspectRatio,
    required this.height,
    required this.width,
    this.iso6391,
    required this.voteAverage,
    required this.voteCount,
  });

  factory MovieImage.fromJson(Map<String, dynamic> json) {
    return MovieImage(
      filePath: json['file_path'],
      aspectRatio: json['aspect_ratio'],
      height: json['height'],
      width: json['width'],
      iso6391: json['iso_639_1'],
      voteAverage: json['vote_average'],
      voteCount: json['vote_count'],
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MovieImage &&
          runtimeType == other.runtimeType &&
          filePath == other.filePath &&
          aspectRatio == other.aspectRatio &&
          height == other.height &&
          width == other.width &&
          iso6391 == other.iso6391 &&
          voteAverage == other.voteAverage &&
          voteCount == other.voteCount;

  @override
  int get hashCode => Object.hash(
        filePath,
        aspectRatio,
        height,
        width,
        iso6391,
        voteAverage,
        voteCount,
      );
}
