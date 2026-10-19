import 'dart:convert';

import 'package:countly_flutter/countly_flutter.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../utils.dart';

/// Every push notification reaches onNotification exactly once, as a JSON object, including a
/// second one that arrives before Dart asks for the next notification.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('Push notifications in a burst reach onNotification once each, as JSON objects', (WidgetTester tester) async {
    await Countly.initWithConfig(CountlyConfig(SERVER_URL, APP_KEY).setLoggingEnabled(true));

    final List<String> received = [];
    Countly.onNotification((String notification) => received.add(notification));
    await Future<void>.delayed(const Duration(seconds: 1));

    await deliverTestNotifications([
      {'title': 'first', 'c.i': 'notification_1'},
      {'title': 'second', 'c.i': 'notification_2'},
    ]);
    await Future<void>.delayed(const Duration(seconds: 2));
    print('received: $received');

    expect(received.length, 2);
    final dynamic first = json.decode(received[0]);
    final dynamic second = json.decode(received[1]);
    expect(first, isA<Map<String, dynamic>>());
    expect(first['title'], 'first');
    expect(second['title'], 'second');

    // A third notification while Dart is already waiting is delivered too, and nothing repeats.
    await deliverTestNotifications([
      {'title': 'third', 'c.i': 'notification_3'},
    ]);
    await Future<void>.delayed(const Duration(seconds: 2));
    expect(received.length, 3);
    expect(json.decode(received[2])['title'], 'third');
  });
}
