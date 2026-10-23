import 'dart:convert';
import 'dart:io';

import 'package:countly_flutter/countly_flutter.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../utils.dart';

/// A clicked push notification that opens the app reaches onNotification once, with the payload it
/// arrived with, in Android.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('A clicked push notification reaches onNotification once, with its payload', (WidgetTester tester) async {
    if (!Platform.isAndroid) {
      return;
    }
    await Countly.initWithConfig(CountlyConfig(SERVER_URL, APP_KEY).setLoggingEnabled(true));

    final List<String> received = [];
    Countly.onNotification((String notification) => received.add(notification));
    await Future<void>.delayed(const Duration(seconds: 1));

    final Map<String, String> payload = {'title': 'clicked', 'message': 'body', 'c.i': 'notification_click_1'};
    // An Activity restored from saved state carries a click that was already handed over.
    await deliverTestNotificationClick(payload, restored: true);
    await Future<void>.delayed(const Duration(seconds: 2));
    expect(received, isEmpty);

    await deliverTestNotificationClick(payload);
    await Future<void>.delayed(const Duration(seconds: 2));
    print('received: $received');

    expect(received.length, 1);
    expect(json.decode(received[0]), payload);

    // An intent without a Countly message is not a click.
    await deliverTestNotificationClick({'title': 'no id'});
    await Future<void>.delayed(const Duration(seconds: 2));
    expect(received.length, 1);
  });
}
