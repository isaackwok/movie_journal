import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:movie_journal/core/network/tmdb_dio_client.dart';

void main() {
  setUpAll(() {
    // The client reads the access token at first use; load a stub so the
    // top-level final can be evaluated without a real .env file.
    dotenv.loadFromString(envString: 'TMDB_ACCESS_TOKEN=test-token');
  });

  // Regression test for ISA-9 bug 4: Dio defaults to *no* timeouts, so a
  // dropped connection left search/popular skeletons spinning forever.
  test('TMDB client pins connect and receive timeouts', () {
    expect(tmdbDioClient.options.connectTimeout, const Duration(seconds: 10));
    expect(tmdbDioClient.options.receiveTimeout, const Duration(seconds: 20));
  });
}
