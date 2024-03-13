import 'dart:convert';
import 'package:countly_flutter/countly_flutter.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import '../utils.dart';

/// Check if setting all internal limits to 1 and truncating the queues works
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('Init SDK with internal limits as 1', (WidgetTester tester) async {
    // Initialize the SDK
    CountlyConfig config = CountlyConfig(SERVER_URL, APP_KEY).setLoggingEnabled(true);
    config.limits.setMaxKeyLength(1).setMaxValueSize(1).setMaxSegmentationValues(1).setMaxBreadcrumbCount(1).setMaxStackTraceLineLength(1).setMaxStackTraceLinesPerThread(1);
    await Countly.initWithConfig(config);
    // Create some events
    await Countly.instance.views.startAutoStoppedView('test');
    await Countly.instance.views.startAutoStoppedView('test2');

    // Get request and event queues from native side
    List<String> requestList = await getRequestQueue(); // List of strings
    List<String> eventList = await getEventQueue(); // List of json objects

    // Some logs for debugging
    print('RQ: $requestList');
    print('EQ: $eventList');
    print('RQ length: ${requestList.length}');
    print('EQ length: ${eventList.length}');
  });
}
