@TestOn('vm')
library native_config_options_test;

import 'package:countly_flutter/countly_flutter.dart';
import 'package:flutter_test/flutter_test.dart';

import 'config_test_utils.dart';

/// The values the platforms receive when every native config option below is set.
const Map<String, Object> expectedOptions = {
  'manualSessionControlHybridMode': true,
  'metricOverride': {'_app_version': '1.2.3', 'custom_metric': 'value'},
  'trackOrientationChanges': false,
  'clearStoredDeviceId': true,
  'sdkLoggingInProductionDisabled': true,
  'webViewDisabled': true,
  'healthCheckDisabled': true,
  'shouldIgnoreAppCrawlers': true,
  'appCrawlerNames': ['Crawler One', 'Crawler Two'],
  'recordAllThreadsWithCrash': true,
  'doNotShowAlertForNotifications': true,
  'maxValueSizePicture': 2048,
  'contentZoomDisabled': true,
  'contentRotationDisabled': true,
  'contentReloadOnStallEnabled': true,
  'contentReloadOnStallTimeout': 2500,
};

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  tearDown(() async {
    await Countly.instance.halt();
  });

  test('Native config options reach the platform as they were set', () async {
    final CountlyConfig config = CountlyConfig('https://example.com', 'app_key')
      ..enableManualSessionControlHybridMode()
      ..setMetricOverride({'_app_version': '1.2.3', 'custom_metric': 'value'})
      ..setTrackOrientationChanges(false)
      ..enableClearStoredDeviceId()
      ..disableSDKLoggingInProduction()
      ..disableWebView()
      ..disableHealthCheck()
      ..setShouldIgnoreAppCrawlers(true)
      ..setAppCrawlerNames(['Crawler One', 'Crawler Two'])
      ..enableRecordAllThreadsWithCrash()
      ..doNotShowAlertForNotifications();
    config.sdkInternalLimits.setMaxValueSizePicture(2048);
    config.content
      ..disableZoom()
      ..disableRotation()
      ..enableContentReloadOnStall()
      ..setContentReloadOnStallTimeout(2500);

    final Map<String, dynamic> sent = await initConfigSentFor(config);
    expectedOptions.forEach((String key, Object value) {
      expect(sent[key], value, reason: key);
    });
  });

  test('Options left unset or given invalid values are not sent', () async {
    final CountlyConfig config = CountlyConfig('https://example.com', 'app_key')..setMetricOverride({});
    config.content.setContentReloadOnStallTimeout(0);

    final Map<String, dynamic> sent = await initConfigSentFor(config);
    for (final String key in expectedOptions.keys) {
      expect(sent.containsKey(key), isFalse, reason: key);
    }
  });
}
