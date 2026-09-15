import 'dart:io';
import 'dart:math';

import 'package:countly_flutter_np/countly_flutter.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../utils.dart';

/**
 * Tests for adding custom network request headers before and after SDK initialization.
 * Verifies that the headers are correctly sent with network requests.
 * Covers scenarios of initial headers set during config and additional headers added later.
 * Checks for header overriding and empty header values.
 * Uses a local test server to capture and validate request headers.
 */
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('addCustomNetworkRequestHeaders_test', (WidgetTester tester) async {
    List<HttpHeaders> headersArray = <HttpHeaders>[];
    createServer(
      <Map<String, List<String>>>[],
      customHandler: (req, queryParams, res) async {
        // Print request headers for debugging
        headersArray.add(req.headers);
      },
    );
    // Initialize the SDK
    CountlyConfig config = CountlyConfig(TEST_SERVER_URL, APP_KEY).enableManualSessionHandling().setLoggingEnabled(true);
    config.setCustomNetworkRequestHeaders({"Initial-Header": "InitialValue"});
    await Countly.initWithConfig(config);
    await Future.delayed(const Duration(seconds: 1));
    for (var headers in headersArray) {
      expect('InitialValue', headers.value('Initial-Header'));
      expect(null, headers.value('X-Custom-Header-1'));
      expect(null, headers.value('X-Custom-Header-2'));
      expect(null, headers.value('X-Custom-Header-3'));
    }
    headersArray.clear();
    // Add custom headers
    await Countly.instance.addCustomNetworkRequestHeaders({"X-Custom-Header-1": "", "": "CustomValue2", "X-Custom-Header-3": "CustomValue3", "Initial-Header": "OverriddenValue"});
    // Make a request to trigger headers being sent
    await Countly.instance.sessions.beginSession();
    await Future.delayed(const Duration(seconds: 2));

    for (var headers in headersArray) {
      expect('OverriddenValue', headers.value('Initial-Header'));
      expect('', headers.value('X-Custom-Header-1'));
      expect(null, headers.value(''));
      expect('CustomValue3', headers.value('X-Custom-Header-3'));
    }
  });
}
