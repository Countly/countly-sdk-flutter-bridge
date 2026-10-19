@TestOn('browser')
library events_test;

import 'package:countly_flutter/countly_flutter.dart';
import 'package:flutter_test/flutter_test.dart';

import 'web_test_utils.dart';

void main() {
  setUpWebPlugin();

  test('Recorded and timed events reach the request queue with their values', () async {
    await Countly.initWithConfig(testConfig());

    await Countly.instance.events.recordEvent('purchase', {'item': 'book', 'price': 12}, 2, 19.5, 3);
    await Countly.instance.events.startEvent('timed');
    await Future<void>.delayed(const Duration(milliseconds: 1100));
    await Countly.instance.events.endEvent('timed', {'step': 'done'}, 1, 0);
    await Countly.instance.events.startEvent('cancelled');
    await Countly.instance.events.cancelEvent('cancelled');
    await waitForHeartbeat();

    final List<Map<String, dynamic>> events = await queuedEvents();
    final Map<String, dynamic> purchase = events.firstWhere((e) => e['key'] == 'purchase');
    expect(purchase['count'], 2);
    expect(purchase['sum'], 19.5);
    expect(purchase['dur'], 3);
    expect(purchase['segmentation'], {'item': 'book', 'price': 12});

    final Map<String, dynamic> timed = events.firstWhere((e) => e['key'] == 'timed');
    expect(timed['dur'], greaterThanOrEqualTo(1));
    expect(timed['segmentation'], {'step': 'done'});

    expect(events.where((e) => e['key'] == 'cancelled'), isEmpty);
  });
}
