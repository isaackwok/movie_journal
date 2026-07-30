import 'package:dio/dio.dart';
import 'package:movie_journal/supabase_auth_manager.dart';

final quesgenDioClient = Dio(
  BaseOptions(
    baseUrl: 'https://movie-journal-quesgen-929129412152.asia-east1.run.app',
    connectTimeout: const Duration(seconds: 10),
    // The AI review generation legitimately takes tens of seconds (Cloud Run
    // cold start + LLM latency), so the receive timeout is deliberately
    // generous — it only needs to beat "hangs forever".
    receiveTimeout: const Duration(seconds: 90),
  ),
)..interceptors.add(
    QueuedInterceptorsWrapper(
      onRequest: (options, handler) async {
        // supabase_flutter refreshes the session in the background, so the
        // access token is read synchronously here rather than awaited as the
        // Firebase `getIdToken()` call was. The quesgen service verifies both
        // issuers during the migration window (plan Phase 6).
        final token = SupabaseAuthManager.currentSession?.accessToken;
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
    ),
  );
