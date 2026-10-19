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

  // Runs first, as the Web SDK keeps the segmentation of the first track_errors call on a page.
  test('Handled exceptions carry the crash logs and their own segmentation, or else the custom crash segment', () async {
    await Countly.initWithConfig(testConfig()
      ..enableCrashReporting()
      ..setCustomCrashSegment({'build': 'ci', 'screen': 'unknown'}));

    await Countly.addCrashLog('opened the cart');
    await Countly.addCrashLog('tapped pay');
    await Countly.logException('StateError: payment failed\n#0 pay (cart.dart:12)', true, {'screen': 'cart'});
    await Countly.logException('StateError: refund failed', false);
    await waitForHeartbeat();

    final List<Map<String, dynamic>> crashes = await queuedCrashes();
    expect(crashes, hasLength(2));
    expect(crashes[0]['_nonfatal'], isTrue);
    expect(crashes[0]['_error'], contains('payment failed'));
    expect(crashes[0]['_custom'], {'screen': 'cart'});
    expect(crashes[0]['_logs'], contains('opened the cart'));
    expect(crashes[0]['_logs'], contains('tapped pay'));
    expect(crashes[1]['_nonfatal'], isFalse);
    expect(crashes[1]['_error'], contains('refund failed'));
    expect(crashes[1]['_custom'], {'build': 'ci', 'screen': 'unknown'});
  });

  test('throwNativeException raises an error that unhandled crash reporting records as fatal', () async {
    await Countly.initWithConfig(testConfig()..enableCrashReporting());

    await Countly.throwNativeException();
    await waitForHeartbeat();

    final Map<String, dynamic> crash = (await queuedCrashes()).single;
    expect(crash['_nonfatal'], isFalse);
    expect(crash['_error'], contains('A test crash requested through Countly.throwNativeException'));
  });

  test('A custom crash segment in the config turns on unhandled crash reporting, as the Web SDK takes the segmentation with it', () async {
    await Countly.initWithConfig(testConfig()..setCustomCrashSegment({'build': 'ci'}));

    await Countly.throwNativeException();
    await waitForHeartbeat();

    expect((await queuedCrashes()).single['_nonfatal'], isFalse);
  });
}
