import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';

final quesgenDioClient = Dio(
  BaseOptions(
    baseUrl: 'https://movie-journal-quesgen-929129412152.asia-east1.run.app',
  ),
)..interceptors.add(
    QueuedInterceptorsWrapper(
      onRequest: (options, handler) async {
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          final token = await user.getIdToken();
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
    ),
  );
