import 'dart:convert';
import 'dart:io';

import 'package:countly_flutter/countly_flutter.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../utils.dart';

/// A clicked push notification reaches onNotification once, with the payload it arrived with, in
/// Android, as it does in iOS.
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

    await deliverTestNotificationClick({'title': 'clicked', 'message': 'body', 'c.i': 'notification_click_1', 'c.l': 'https://count.ly'});
    await Future<void>.delayed(const Duration(seconds: 2));
    print('received: $received');

    expect(received.length, 1);
    final dynamic clicked = json.decode(received[0]);
    expect(clicked, isA<Map<String, dynamic>>());
    expect(clicked['title'], 'clicked');
    expect(clicked['message'], 'body');
    expect(clicked['c.i'], 'notification_click_1');
    expect(clicked['c.l'], 'https://count.ly');

    // An intent without a Countly message is not a click.
    await deliverTestNotificationClick({'title': 'no id'});
    await Future<void>.delayed(const Duration(seconds: 2));
    expect(received.length, 1);
  });
}
