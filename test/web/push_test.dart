@TestOn('browser')
library push_test;

import 'dart:convert';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:countly_flutter/countly_flutter.dart';
import 'package:flutter_test/flutter_test.dart';

import 'web_test_utils.dart';

/// A well-formed VAPID public key: a base64-url encoded uncompressed P-256 point.
const String vapidPublicKey = 'BEl62iUYgUivxIkv69yViEuiBIa-Ib9-SkvMeAtA3LFgDzkrxZJjSgSnfckjBJuBkr3qBUYIHBQFLXYp5Nksh8U';

/// Whether the Web SDK that was loaded has web push, which arrived in 26.8.0.
bool webSdkHasPush() {
  final JSAny? function = webInstance()['enable_push_notifications'];
  return function != null && function.typeofEquals('function');
}

/// Posts [data] to the page the way the Countly service worker does.
void postFromServiceWorker(Map<String, Object?> data) {
  final JSObject serviceWorker = (globalContext['navigator'] as JSObject)['serviceWorker'] as JSObject;
  final JSObject details = JSObject();
  details['data'] = data.jsify();
  final JSObject event = (globalContext['MessageEvent'] as JSFunction).callAsConstructor<JSObject>('message'.toJS, details);
  serviceWorker.callMethod('dispatchEvent'.toJS, event);
}

void main() {
  setUpWebPlugin();

  test('onNotification registered before init waits for a notification instead of answering at once', () async {
    final List<String> received = [];
    // ignore: unawaited_futures
    Countly.onNotification(received.add);
    await Future<void>.delayed(const Duration(milliseconds: 500));
    expect(received, isEmpty);
  });

  test('Push calls report why they cannot subscribe', () async {
    final CountlyConfig config = testConfig()
      ..setRequiresConsent(true)
      ..setConsentEnabled(['events']);
    config.push.setVapidPublicKey(vapidPublicKey);
    await Countly.initWithConfig(config);

    if (!webSdkHasPush()) {
      expect(await Countly.askForNotificationPermission(), 'subscribed: failed, reason: unsupported');
      expect(await Countly.disablePushNotifications(), 'unsubscribed: failed, reason: unsupported');
      return;
    }
    expect(await Countly.askForNotificationPermission(), 'subscribed: failed, reason: no_consent');
    expect(await Countly.disablePushNotifications(), 'unsubscribed: success');
  });

  test('Push needs a VAPID public key, and a well-formed one', () async {
    await Countly.initWithConfig(testConfig()..giveAllConsents());
    if (!webSdkHasPush()) {
      markTestSkipped('The loaded Web SDK has no web push');
      return;
    }
    expect(await Countly.askForNotificationPermission(), 'subscribed: failed, reason: missing_vapid_key');
    await Countly.instance.halt();

    final CountlyConfig config = testConfig()..giveAllConsents();
    config.push.setVapidPublicKey('not-a-vapid-key');
    await Countly.initWithConfig(config);
    expect(await Countly.askForNotificationPermission(), 'subscribed: failed, reason: invalid_vapid_key');
  });

  test('onNotification reports the events the service worker posts, in order', () async {
    final CountlyConfig config = testConfig()..giveAllConsents();
    config.push.setVapidPublicKey(vapidPublicKey);
    await Countly.initWithConfig(config);
    if (!webSdkHasPush()) {
      markTestSkipped('The loaded Web SDK has no web push');
      return;
    }

    final List<Map<String, dynamic>> received = [];
    // ignore: unawaited_futures
    Countly.onNotification((String notification) => received.add(jsonDecode(notification) as Map<String, dynamic>));
    postFromServiceWorker({
      'type': 'countly_push_received',
      'messageId': 'message_1',
      'title': 'Sale',
      'message': 'Half off today',
      'payload': {'promo': 'half'},
    });
    postFromServiceWorker({'type': 'countly_push_closed', 'messageId': 'message_1'});
    await Future<void>.delayed(const Duration(milliseconds: 300));

    expect(received.map((n) => n['type']).toList(), ['received', 'closed']);
    expect(received.first['messageId'], 'message_1');
    expect(received.first['title'], 'Sale');
    expect(received.first['message'], 'Half off today');
    expect(received.first['payload'], {'promo': 'half'});
  });
}
