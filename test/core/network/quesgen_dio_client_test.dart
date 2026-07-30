import 'package:flutter_test/flutter_test.dart';
import 'package:movie_journal/core/network/quesgen_dio_client.dart';

void main() {
  // Regression test for ISA-9 bug 4. The receive timeout is deliberately
  // generous — the AI review endpoint legitimately takes tens of seconds
  // (Cloud Run cold start + LLM latency) — but it must exist so the reviews
  // sheet cannot hang forever.
  test('quesgen client pins connect and a generous receive timeout', () {
    expect(
      quesgenDioClient.options.connectTimeout,
      const Duration(seconds: 10),
    );
    expect(
      quesgenDioClient.options.receiveTimeout,
      const Duration(seconds: 90),
    );
  });
}
