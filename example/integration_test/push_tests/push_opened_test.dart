import 'dart:convert';
import 'dart:io';

import 'package:countly_flutter/countly_flutter.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../utils.dart';

/// A clicked push notification reaches onNotificationOpened once, with the payload it arrived with
/// and the index of the clicked action. In Android onNotification does not get the click; in iOS it
/// does, as before.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('A clicked push notification reaches onNotificationOpened once, with the clicked action', (WidgetTester tester) async {
    await Countly.initWithConfig(CountlyConfig(SERVER_URL, APP_KEY).setLoggingEnabled(true));
    // Android gets the FCM data map, iOS the APNs payload with the Countly part under "c".
    final Map<String, Object> payload = Platform.isIOS
        ? {
            'aps': {'alert': 'body'},
            'c': {'i': 'notification_click_1'},
          }
        : {'title': 'clicked', 'message': 'body', 'c.i': 'notification_click_1'};

    // A click made before the callback is set, like the one that starts the app, is kept for it.
    await deliverTestNotificationOpened(payload, actionIndex: 1);

    final List<String> received = [];
    final List<List<Object>> opened = [];
    Countly.onNotification((String notification) => received.add(notification));
    final String? result = await Countly.onNotificationOpened((String notification, int actionIndex) => opened.add([json.decode(notification), actionIndex]));
    expect(result, '');
    await Future<void>.delayed(const Duration(seconds: 2));
    print('opened: $opened, received: $received');
    expect(opened, [
      [payload, 1],
    ]);

    if (Platform.isIOS) {
      // A click reaches onNotification once, although the app delegate passes it on again.
      await deliverTestNotificationOpened(payload);
      // A dismissal and a notification Countly did not send are not clicks.
      await deliverTestNotificationOpened(payload, actionIndex: -1);
      await deliverTestNotificationOpened({
        'aps': {'alert': 'other'},
      });
      await Future<void>.delayed(const Duration(seconds: 2));
      expect(opened, [
        [payload, 1],
        [payload, 0],
      ]);
      expect(received.map((String notification) => json.decode(notification)).toList(), [
        payload,
        payload,
        payload,
        {
          'aps': {'alert': 'other'},
        },
      ]);
    } else {
      expect(received, isEmpty);

      // A restored Activity, and an intent reopened from the recent apps, carry a click that was
      // already handed over.
      await deliverTestNotificationOpened(payload, start: 'restored');
      await deliverTestNotificationOpened(payload, start: 'history');
      await Future<void>.delayed(const Duration(seconds: 2));
      expect(opened.length, 1);

      // A fresh Activity, and an intent sent to the running one, hand their click over once each.
      await deliverTestNotificationOpened(payload);
      await deliverTestNotificationOpened(payload, start: 'newIntent', actionIndex: 2);
      await Future<void>.delayed(const Duration(seconds: 2));
      expect(opened, [
        [payload, 1],
        [payload, 0],
        [payload, 2],
      ]);

      // An intent without a Countly message is not a click.
      await deliverTestNotificationOpened({'title': 'no id'});
      await Future<void>.delayed(const Duration(seconds: 2));
      expect(opened.length, 3);
      expect(received, isEmpty);
    }

    // Setting the callback again replaces the previous one.
    final int openedBefore = opened.length;
    final List<int> replaced = [];
    await Countly.onNotificationOpened((String notification, int actionIndex) => replaced.add(actionIndex));
    await deliverTestNotificationOpened(payload, actionIndex: 1);
    await Future<void>.delayed(const Duration(seconds: 2));
    expect(replaced, [1]);
    expect(opened.length, openedBefore);
  });
}
