import 'package:countly_flutter/countly_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../utils.dart';
import '../web_utils_stub.dart' if (dart.library.html) '../web_utils.dart';

/// Web push subscription tests.
/// Everything that needs a granted notification permission belongs in a browser the test runner
/// cannot answer prompts in, so these cover the refusals the SDK reports before it prompts.
/// On non-web platforms, a single placeholder test passes so the runner doesn't fail.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  if (!kIsWeb) {
    testWidgets('web_push_test (web-only, skipped on native)', (WidgetTester tester) async {
      // This test suite is web-only. On native platforms, this placeholder passes.
    });
    return;
  }

  group('Web push subscription refusals', () {
    tearDown(() async {
      await Countly.instance.halt();
      clearWebLocalStorage();
    });

    test('Subscribing without push consent is refused', () async {
      CountlyConfig config = CountlyConfig(SERVER_URL, APP_KEY).setLoggingEnabled(true).setRequiresConsent(true).setConsentEnabled([CountlyConsent.sessions]);
      config.push.setVapidPublicKey('BPq1PLxGtCBJbTHKzPKMdYBhCtBcCVcBZQWq5hFTSFoOhoN0XGvZsO3P1EqwhIH0TRMjAHMDJ8ipmYmJrkPPXwA');
      await Countly.initWithConfig(config);

      final result = await Countly.askForNotificationPermission();
      expect(result, contains('no_consent'));
    });

    test('Subscribing without a VAPID public key is refused', () async {
      CountlyConfig config = CountlyConfig(SERVER_URL, APP_KEY).setLoggingEnabled(true);
      await Countly.initWithConfig(config);

      final result = await Countly.askForNotificationPermission();
      expect(result, contains('missing_vapid_key'));
    });

    test('Subscribing with a malformed VAPID public key is refused', () async {
      CountlyConfig config = CountlyConfig(SERVER_URL, APP_KEY).setLoggingEnabled(true);
      config.push.setVapidPublicKey('not-a-vapid-key');
      await Countly.initWithConfig(config);

      final result = await Countly.askForNotificationPermission();
      expect(result, contains('invalid_vapid_key'));
    });

    test('Unsubscribing reports back even when nothing was subscribed', () async {
      CountlyConfig config = CountlyConfig(SERVER_URL, APP_KEY).setLoggingEnabled(true);
      await Countly.initWithConfig(config);

      final result = await Countly.disablePushNotifications();
      expect(result, startsWith('unsubscribed'));
    });
  });
}
