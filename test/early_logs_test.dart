@TestOn('vm')
library early_logs_test;

import 'dart:async';
import 'dart:convert';

import 'package:countly_flutter/countly_flutter.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('Messages logged before init, config warnings included, are printed once init enables logging', () async {
    Map<String, dynamic>? sent;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(const MethodChannel('countly_flutter'), (MethodCall call) async {
      if (call.method == 'init') {
        sent = (jsonDecode((call.arguments as Map<Object?, Object?>)['data'] as String) as List<dynamic>)[0] as Map<String, dynamic>;
      }
      return null;
    });

    final List<String> printed = <String>[];
    await runZoned(() async {
      final CountlyConfig config = CountlyConfig('https://example.com', 'app_key')..setLoggingEnabled(true);
      config.content.setAllowedIntentSchemes(['https://']);
      config.push.setAllowedIntentSchemes(['market']);
      config.push.setAllowedIntentSchemes(['intent']);
      config.content.setContentReloadOnStallTimeout(0);
      config.setUpdateSessionTimerDelay(0);
      config.setWebSDKUrl('');
      config.setMetricOverride({});
      await Countly.instance.views.startView('before_init');
      await Countly.initWithConfig(config);
    }, zoneSpecification: ZoneSpecification(print: (Zone self, ZoneDelegate parent, Zone zone, String line) => printed.add(line)));

    final int initLine = printed.indexWhere((String line) => line.contains('Calling "initWithConfig"'));
    expect(initLine, greaterThan(0));
    final List<String> early = printed.sublist(0, initLine);
    expect(early, contains(contains('content.setAllowedIntentSchemes, ignoring [https://], which is not a URI scheme')));
    expect(early, contains(contains('content.setAllowedIntentSchemes, no allowed scheme is left, so every scheme except the blocked ones stays allowed')));
    expect(early, contains(contains('push.setAllowedIntentSchemes, ignoring [intent], as the "intent" scheme is always blocked')));
    expect(early, contains(contains('push.setAllowedIntentSchemes, no allowed scheme is left, so the schemes set before stay: [market]')));
    expect(early, contains(contains('setContentReloadOnStallTimeout, timeout must be at least 1 millisecond, ignoring [0]')));
    expect(early, contains(contains('setUpdateSessionTimerDelay, delay must be at least 1 second, ignoring [0]')));
    expect(early, contains(contains('setWebSDKUrl, url cannot be empty')));
    expect(early, contains(contains('setMetricOverride, no metrics were provided')));
    expect(early, contains(contains('"initWithConfig" must be called before "[Views] startView"')));
    expect(sent!['pushAllowedIntentSchemes'], ['market']);
    expect(sent!.containsKey('contentAllowedIntentSchemes'), isFalse);
  });
}
