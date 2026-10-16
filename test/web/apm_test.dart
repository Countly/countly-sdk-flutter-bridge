@TestOn('browser')
library apm_test;

import 'package:countly_flutter/countly_flutter.dart';
import 'package:flutter_test/flutter_test.dart';

import 'web_test_utils.dart';

/// The queued traces called [name].
Future<List<Map<String, dynamic>>> tracesNamed(String name) async {
  return (await queuedTraces()).where((Map<String, dynamic> trace) => trace['name'] == name).toList();
}

void main() {
  setUpWebPlugin();

  test('Custom traces report their duration and only the valid metrics', () async {
    await Countly.initWithConfig(testConfig());

    await Countly.startTrace('checkout');
    await Future<void>.delayed(const Duration(milliseconds: 300));
    await Countly.endTrace('checkout', {'items': 5, 'duration': 1, 'response_code': 2, 'this_metric_name_is_longer_than_32': 3});

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
    expect(checkout['apm_metrics'], {'duration': greaterThanOrEqualTo(300), 'items': 5});
    expect(checkout['etz'] - checkout['stz'], checkout['apm_metrics']['duration']);
  });

  test('Network traces are corrected the way the native SDKs correct them', () async {
    await Countly.initWithConfig(testConfig());

    await Countly.recordNetworkTrace('api/items', 200, 120, 2048, 1000, 1250);
    await Countly.recordNetworkTrace('api/broken', 700, -5, -1, 5000, 4000);
    await waitForHeartbeat();

    final Map<String, dynamic> items = (await tracesNamed('api/items')).single;
    expect(items['type'], 'network');
    expect(items['stz'], 1000);
    expect(items['etz'], 1250);
    expect(items['apm_metrics'], {'response_time': 250, 'response_payload_size': 2048, 'response_code': 200, 'request_payload_size': 120});

    final Map<String, dynamic> broken = (await tracesNamed('api/broken')).single;
    expect(broken['stz'], 4000);
    expect(broken['etz'], 5000);
    expect(broken['apm_metrics'], {'response_time': 1000, 'response_payload_size': 0, 'response_code': 0, 'request_payload_size': 0});
  });

  test('The app start is recorded once at init when tracking it automatically', () async {
    final int startedAt = DateTime.now().millisecondsSinceEpoch - 5000;
    final CountlyConfig config = testConfig();
    config.apm.enableAppStartTimeTracking().setAppStartTimestampOverride(startedAt);
    await Countly.initWithConfig(config);
    await Countly.appLoadingFinished();
    await waitForHeartbeat();

    final List<Map<String, dynamic>> starts = await tracesNamed('app_start');
    expect(starts, hasLength(1));
    expect(starts.single['type'], 'device');
    expect(starts.single['stz'], startedAt);
    expect(starts.single['apm_metrics']['duration'], inInclusiveRange(5000, 8000));
  });

  test('The manual app loaded trigger records the app start when the app says so', () async {
    final CountlyConfig config = testConfig();
    config.apm.enableAppStartTimeTracking().enableManualAppLoadedTrigger();
    await Countly.initWithConfig(config);
    await waitForHeartbeat();
    expect(await tracesNamed('app_start'), isEmpty);

    await Countly.appLoadingFinished();
    await Countly.appLoadingFinished();
    await waitForHeartbeat();

    final List<Map<String, dynamic>> starts = await tracesNamed('app_start');
    expect(starts, hasLength(1));
    expect(starts.single['apm_metrics']['duration'], greaterThan(0));
  });

  test('Time in the foreground and the background is reported when the page visibility changes', () async {
    final CountlyConfig config = testConfig();
    config.apm.enableForegroundBackgroundTracking();
    await Countly.initWithConfig(config);

    await Future<void>.delayed(const Duration(milliseconds: 200));
    setPageVisibility(visible: false);
    await Future<void>.delayed(const Duration(milliseconds: 300));
    setPageVisibility(visible: true);
    setPageVisibility(visible: true);
    await waitForHeartbeat();

    final List<Map<String, dynamic>> foreground = await tracesNamed('app_in_foreground');
    final List<Map<String, dynamic>> background = await tracesNamed('app_in_background');
    expect(foreground, hasLength(1));
    expect(foreground.single['apm_metrics']['duration'], greaterThanOrEqualTo(200));
    expect(background, hasLength(1));
    expect(background.single['apm_metrics']['duration'], greaterThanOrEqualTo(300));
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
