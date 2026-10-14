import 'dart:async';

import 'package:countly_flutter/countly_flutter.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../utils.dart';

/// A remote config download that cannot run calls its callback with an error instead of never
/// calling it, so an app waiting for remote config before it starts does not wait forever.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('Remote config downloads without consent call back with an error', (WidgetTester tester) async {
    await Countly.initWithConfig(CountlyConfig(SERVER_URL, APP_KEY).setLoggingEnabled(true).setRequiresConsent(true));
    const Duration limit = Duration(seconds: 10);

    final Completer<RequestResult> allKeys = Completer<RequestResult>();
    await Countly.instance.remoteConfig.downloadAllKeys((RequestResult rResult, String? error, bool fullValueUpdate, Map<String, RCData> downloadedValues) {
      allKeys.complete(rResult);
    });
    expect(await allKeys.future.timeout(limit), RequestResult.error);

    final Completer<RequestResult> specificKeys = Completer<RequestResult>();
    await Countly.instance.remoteConfig.downloadSpecificKeys(['key_a'], (RequestResult rResult, String? error, bool fullValueUpdate, Map<String, RCData> downloadedValues) {
      specificKeys.complete(rResult);
    });
    expect(await specificKeys.future.timeout(limit), RequestResult.error);
  });
}
