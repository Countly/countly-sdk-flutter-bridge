@TestOn('browser')
library apm_test;

import 'package:countly_flutter/countly_flutter.dart';
import 'package:flutter_test/flutter_test.dart';

import 'web_test_utils.dart';

void main() {
  setUpWebPlugin();

  test('Custom traces report their measured duration with the given metrics', () async {
    await Countly.initWithConfig(testConfig());

    await Countly.startTrace('checkout');
    await Future<void>.delayed(const Duration(milliseconds: 300));
    await Countly.endTrace('checkout', {'items': 5, 'duration': 1});

    await Countly.startTrace('cancelled');
    await Countly.cancelTrace('cancelled');
    await Countly.startTrace('cleared');
    await Countly.clearAllTraces();
    await Countly.endTrace('cleared', null);
    await Countly.endTrace('never_started', {'items': 1});
    await waitForHeartbeat();

    final List<Map<String, dynamic>> traces = await queuedTraces();
    expect(traces.map((t) => t['name']).toList(), ['checkout']);
    final Map<String, dynamic> checkout = traces.single;
    expect(checkout['type'], 'device');
    expect(checkout['apm_metrics'], {'items': 5, 'duration': greaterThanOrEqualTo(300)});
    expect(checkout['etz'] - checkout['stz'], checkout['apm_metrics']['duration']);
  });

  test('Network traces are reported with the given values', () async {
    await Countly.initWithConfig(testConfig());

    await Countly.recordNetworkTrace('api/items', 200, 120, 2048, 1000, 1250);
    await waitForHeartbeat();

    final Map<String, dynamic> items = (await queuedTraces()).single;
    expect(items['name'], 'api/items');
    expect(items['type'], 'network');
    expect(items['stz'], 1000);
    expect(items['etz'], 1250);
    expect(items['apm_metrics'], {'response_time': 250, 'response_payload_size': 2048, 'response_code': 200, 'request_payload_size': 120});
  });

  test('No trace is sent without the apm consent', () async {
    await Countly.initWithConfig(testConfig()
      ..setRequiresConsent(true)
      ..setConsentEnabled(['events']));

    await Countly.startTrace('blocked');
    await Countly.endTrace('blocked', null);
    await Countly.recordNetworkTrace('blocked', 200, 1, 1, 1, 2);
    await waitForHeartbeat();

    expect(await queuedTraces(), isEmpty);
  });
}
