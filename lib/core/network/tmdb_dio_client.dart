import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

final tmdbDioClient = Dio(
  BaseOptions(
    baseUrl: 'https://api.themoviedb.org/3',
    headers: {'Authorization': 'Bearer ${dotenv.env['TMDB_ACCESS_TOKEN']}'},
    // Without these, a dropped connection leaves search/popular skeletons
    // spinning forever — Dio's default is no timeout at all.
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 20),
  ),
);
