@TestOn('vm')
library early_logs_silent_test;

import 'dart:async';

import 'package:countly_flutter/countly_flutter.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('Without logging, nothing logged before init or after it is printed', () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(const MethodChannel('countly_flutter'), (MethodCall call) async => null);

    final List<String> printed = <String>[];
    await runZoned(() async {
      final CountlyConfig config = CountlyConfig('https://example.com', 'app_key');
      config.content.setAllowedIntentSchemes(['https://']);
      config.setUpdateSessionTimerDelay(0);
      await Countly.instance.views.startView('before_init');
      await Countly.initWithConfig(config);
      await Countly.instance.views.startView('after_init');
      Countly.log('after init');
    }, zoneSpecification: ZoneSpecification(print: (Zone self, ZoneDelegate parent, Zone zone, String line) => printed.add(line)));

    expect(printed, isEmpty);
  });
}
