import 'dart:convert';
import 'package:countly_flutter/countly_flutter.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import '../utils.dart';
import '../web_utils_stub.dart' if (dart.library.html) '../web_utils.dart';

/// Checks that the metrics provided at init replace the detected ones in the session request.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  tearDown(() async {
    await Countly.instance.halt();
    clearWebLocalStorage();
  });

  testWidgets('Provided metrics replace the detected ones', (WidgetTester tester) async {
    CountlyConfig config = CountlyConfig(SERVER_URL, APP_KEY).setLoggingEnabled(true).setMetricOverride({'_app_version': '9.9.9', '_locale': 'xx_YY'});
    await Countly.initWithConfig(config);
    await Future.delayed(const Duration(seconds: 2));

    final sessionRequest = await getRequestWithParam('begin_session');
    final metrics = json.decode(sessionRequest!['metrics']![0]) as Map<String, dynamic>;

    expect(metrics['_app_version'], '9.9.9');
    expect(metrics['_locale'], 'xx_YY');
    expect(metrics['_os'], isNotNull);
  });
}
