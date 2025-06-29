import 'package:dio/dio.dart';

final quesgenDioClient = Dio(
  BaseOptions(
    baseUrl: 'https://movie-journal-quesgen-929129412152.asia-east1.run.app',
  ),
);
