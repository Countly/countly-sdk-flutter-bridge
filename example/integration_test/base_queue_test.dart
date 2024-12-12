import 'dart:convert';
import 'dart:io';
import 'package:countly_flutter/countly_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'utils.dart';

/// Check if we can get stored queues from native side
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('Init SDK and get stored queues from native side', (WidgetTester tester) async {
    // Initialize the SDK
    CountlyConfig config = CountlyConfig(SERVER_URL, APP_KEY).setLoggingEnabled(true);
    await Countly.initWithConfig(config);
    // Create some events
    await Countly.instance.views.startAutoStoppedView('test');
    await Countly.instance.views.startAutoStoppedView('test2');

    // Wait for the events to be stored
    await Future.delayed(Duration(seconds: 5));

    // Get request and event queues from native side
    List<String> requestList = await getRequestQueue(); // List of strings
    List<dynamic> eventList = await getEventQueue(); // List of json objects

    // Some logs for debugging
    print('RQ: $requestList');
    print('EQ: $eventList');
    print('RQ length: ${requestList.length}');
    print('EQ length: ${eventList.length}');

    // Verify the request queue for a single request (example)
    if (requestList.length > 0) {
      Map<String, List<String>> queryParams = Uri.parse("?" + requestList[0]).queryParametersAll;
      testCommonRequestParams(queryParams); // tests
    }

    Map<String, dynamic> event;
    if (kIsWeb) {
      Map<String, List<String>> queryParams = Uri.parse('?${requestList[1]}').queryParametersAll;
      expect(0, eventList.length);
      eventList = jsonDecode(queryParams['events']![0]);
      event = eventList[0];
    } else {
      event = json.decode(eventList[0]);
    }
    // Verify some parameters of a single event
    expect(kIsWeb || Platform.isAndroid ? "[CLY]_orientation" : "[CLY]_view", event['key']);
    expect(1, event['count']);
    expect(kIsWeb || Platform.isAndroid ? 4 : 3, eventList.length);
  });
}
