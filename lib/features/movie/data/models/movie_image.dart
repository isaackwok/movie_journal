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
}
