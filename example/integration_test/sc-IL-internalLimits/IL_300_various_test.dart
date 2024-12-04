import 'dart:io';

import 'package:countly_flutter_np/countly_flutter.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import '../utils.dart';

/// Check if setting:
/// .setMaxBreadcrumbCount()
/// .setMaxStackTraceLineLength()
/// .setMaxStackTraceLinesPerThread()
/// creates a crash or error
/// TODO: Replace this tests with individual tests for each method

const int MAX_RANDOM = 1;
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('Init SDK with some limits', (WidgetTester tester) async {
    // Initialize the SDK
    CountlyConfig config = CountlyConfig(SERVER_URL, APP_KEY).setLoggingEnabled(true);
    config.sdkInternalLimits.setMaxBreadcrumbCount(MAX_RANDOM).setMaxStackTraceLineLength(MAX_RANDOM).setMaxStackTraceLinesPerThread(MAX_RANDOM);
    await Countly.initWithConfig(config);

    // Create truncable events
    await createTruncableEvents();

    // Get request and event queues from native side
    List<String> requestList = await getRequestQueue();
    List<String> eventList = await getEventQueue();

    // Some logs for debugging
    print('RQ: $requestList');
    print('EQ: $eventList');
    print('RQ length: ${requestList.length}');
    print('EQ length: ${eventList.length}');

    expect(requestList.length, Platform.isIOS ? 8 : 7); // user properties and custom user properties are separately sent in iOS
    expect(eventList.length, 0);

    // TODO: refactor this part (move to utils and make it more generic)
    // 0: begin session
    // 1: custom APM with segmentation
    // 2: network Trace
    // 3: custom fatality crash with segmentation
    // 4: custom mortal crash with segmentation
    // 5: custom view and events with segmentation
    // 6: custom user properties
    var a = 0;
    for (var element in requestList) {
      Map<String, List<String>> queryParams = Uri.parse('?' + element).queryParametersAll;
      testCommonRequestParams(queryParams); // checks general params
      // some logs for debugging
      print('RQ.$a: $queryParams');
      print('========================');
      a++;
    }
  });
}
