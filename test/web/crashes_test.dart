@TestOn('browser')
library crashes_test;

import 'dart:convert';

import 'package:countly_flutter/countly_flutter.dart';
import 'package:flutter_test/flutter_test.dart';

import 'web_test_utils.dart';

/// Every crash report in the request queue, decoded.
Future<List<Map<String, dynamic>>> queuedCrashes() async {
  return (await requestsWith('crash')).map((Map<String, dynamic> request) => jsonDecode(request['crash'] as String) as Map<String, dynamic>).toList();
}

void main() {
  setUpWebPlugin();

  test('Handled exceptions carry the crash logs and the config and call segmentation', () async {
    await Countly.initWithConfig(testConfig()
      ..enableCrashReporting()
      ..setCustomCrashSegment({'build': 'ci', 'screen': 'unknown'}));

    await Countly.addCrashLog('opened the cart');
    await Countly.addCrashLog('tapped pay');
    await Countly.logException('StateError: payment failed\n#0 pay (cart.dart:12)', true, {'screen': 'cart'});
    await waitForHeartbeat();

    final Map<String, dynamic> crash = (await queuedCrashes()).single;
    expect(crash['_nonfatal'], isTrue);
    expect(crash['_error'], contains('payment failed'));
    expect(crash['_custom'], {'build': 'ci', 'screen': 'cart'});
    expect(crash['_logs'], contains('opened the cart'));
    expect(crash['_logs'], contains('tapped pay'));
  });

  test('throwNativeException raises an error that unhandled crash reporting records as fatal', () async {
    await Countly.initWithConfig(testConfig()..enableCrashReporting());

    await Countly.throwNativeException();
    await waitForHeartbeat();

    final Map<String, dynamic> crash = (await queuedCrashes()).single;
    expect(crash['_nonfatal'], isFalse);
    expect(crash['_error'], contains('A test crash requested through Countly.throwNativeException'));
  });
}
