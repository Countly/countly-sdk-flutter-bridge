@TestOn('browser')
library init_retry_test;

import 'package:countly_flutter/countly_flutter.dart';
import 'package:flutter_test/flutter_test.dart';

import 'web_test_utils.dart';

void main() {
  setUpWebPlugin();

  test('An init whose Web SDK script cannot load reports it, and a later init can still start the SDK', () async {
    final String? failed = await Countly.initWithConfig(testConfig()..setWebSDKUrl('http://127.0.0.1:9/countly.min.js'));
    expect(failed, contains('could not be loaded from http://127.0.0.1:9/countly.min.js'));
    expect(await Countly.isInitialized(), isFalse);
    await Countly.instance.events.recordEvent('while_failed');

    final String? retried = await Countly.initWithConfig(testConfig());
    expect(retried, isNull);
    expect(await Countly.isInitialized(), isTrue);
    await Countly.instance.events.recordEvent('after_retry');
    await waitForHeartbeat();

    final List<String?> keys = (await queuedEvents()).map((Map<String, dynamic> event) => event['key'] as String?).toList();
    expect(keys, contains('after_retry'));
    expect(keys, isNot(contains('while_failed')));
  });
}
