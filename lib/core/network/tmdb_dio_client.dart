import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

final tmdbDioClient = Dio(
  BaseOptions(
    baseUrl: 'https://api.themoviedb.org/3',
    headers: {'Authorization': 'Bearer ${dotenv.env['TMDB_ACCESS_TOKEN']}'},
  ),
);
