import 'dart:convert';
import 'dart:io';

import 'package:countly_flutter_np/countly_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../utils.dart';
import '../views_tests/view_utils.dart';

/// Tests for recording custom metrics using the Countly SDK.
/// Verifies that metrics are correctly sent in the network request.
/// Covers scenarios with normal key-value pairs and edge cases like empty keys/values.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('recordMetrics_test', (WidgetTester tester) async {
    CountlyConfig config = CountlyConfig(SERVER_URL, APP_KEY).setLoggingEnabled(true);
    await Countly.initWithConfig(config);
    await Future.delayed(const Duration(seconds: 2));

    // Add custom headers
    await Countly.instance.recordMetrics({'metric1': '100', 'metric2': '200', '_device': 'custom_device', '': 'empty_key', 'empty_value': ''});

    var requestQueue = await getRequestQueue();
    expect(requestQueue.length, 2);
    validateBeginSessionRequest(requestQueue[0]);

    Map<String, List<String>> queryParams = Uri.parse('?${requestQueue[1]}').queryParametersAll;
    var rqMetrics = jsonDecode(queryParams['metrics']![0]);
    Map<String, dynamic> customMetrics = {
      'metric1': '100',
      'metric2': '200',
      '_device': 'custom_device',
      '': 'empty_key',
      'empty_value': '',
    };

    if (Platform.isAndroid) {
      // Android SDK ignores empty key metrics
      customMetrics.remove('');
    }

    validateMetrics(rqMetrics, customMetrics);
  });
}

const _androidMetricKeys = {
  '_os',
  '_os_version',
  '_app_version',
  '_device',
  '_device_type',
  '_resolution',
  '_density',
  '_locale',
  '_manufacturer',
  '_carrier',
  '_has_hinge',
};

const _iosMetricKeys = {'_os', '_os_version', '_app_version', '_device', '_device_type', '_resolution', '_density', '_locale'};

const _webMetricKeys = {
  '_os',
  '_os_version',
  '_app_version',
  '_device',
  '_locale',
  '_browser',
  '_browser_version',
  '_ua',
};

void validateMetrics(Map<String, dynamic> metrics, Map<String, dynamic>? customMetrics) {
  late Set<String> expectedKeys;

  if (kIsWeb) {
    expectedKeys = _webMetricKeys;
  } else if (Platform.isAndroid) {
    expectedKeys = _androidMetricKeys;
  } else if (Platform.isIOS) {
    expectedKeys = _iosMetricKeys;
  } else {
    throw UnsupportedError('Unknown platform in metric validation');
  }

  expectedKeys = expectedKeys.union(customMetrics?.keys.toSet() ?? {});

  expect(metrics.length, equals(expectedKeys.length), reason: 'Metric key count mismatch');

  for (final key in expectedKeys) {
    if (customMetrics != null && customMetrics.containsKey(key)) {
      expect(metrics[key], customMetrics[key]);
    } else {
      expect(
        metrics.containsKey(key),
        true,
        reason: 'Missing metric key: $key',
      );
    }
  }

  for (final entry in (customMetrics ?? {}).entries) {
    expect(
      metrics[entry.key],
      entry.value,
      reason: 'Custom metric key-value mismatch for key: ${entry.key}',
    );
  }
}
