import 'package:dio/dio.dart';

final backendDioClient = Dio(
  BaseOptions(
    baseUrl: 'https://movie-journal-quesgen-929129412152.asia-east1.run.app',
  ),
);
