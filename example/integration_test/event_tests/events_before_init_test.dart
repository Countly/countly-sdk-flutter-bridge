import 'dart:convert';

import 'package:countly_flutter/countly_flutter.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../utils.dart';

/// Events recorded before init, and events without a key, are dropped with an error log
/// instead of throwing or reaching the native SDKs.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('Events before init or without a key never reach the event queue', (WidgetTester tester) async {
    // Keys are unique per run because the event queue survives between runs on a device.
    final String run = DateTime.now().millisecondsSinceEpoch.toString();

    // None of these may throw, even though the native SDKs are not initialized yet.
    await Countly.instance.events.recordEvent('before_init_$run');
    await Countly.instance.events.startEvent('timed_before_init_$run');
    await Countly.instance.events.endEvent('timed_before_init_$run');

    await Countly.initWithConfig(CountlyConfig(SERVER_URL, APP_KEY).setLoggingEnabled(true));
    await Countly.instance.events.recordEvent('after_init_$run');
    await Countly.instance.events.recordEvent('');

    final List<String> keys = [];
    for (final String rawEvent in await getEventQueue()) {
      keys.add(json.decode(rawEvent)['key'] as String);
    }
    print('EQ keys: $keys');

    expect(keys, contains('after_init_$run'));
    expect(keys, isNot(contains('before_init_$run')));
    expect(keys, isNot(contains('timed_before_init_$run')));
    expect(keys, isNot(contains('')));
  });
}
