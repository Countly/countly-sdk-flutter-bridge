import 'dart:convert';
import 'package:countly_flutter/countly_flutter.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'utils.dart';

const MethodChannel _channel = MethodChannel('countly_flutter');

/// Check if we can get stored queues from native side
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('Init SDK and get stored queues from native side', (WidgetTester tester) async {
    // Initialize the SDK
    CountlyConfig config = CountlyConfig(SERVER_URL, APP_KEY).setLoggingEnabled(true);
    await Countly.initWithConfig(config);
    // Create some events
    Countly.instance.views.startAutoStoppedView('test');
    Countly.instance.views.startAutoStoppedView('test2');
    // Get request and event queues from native side
    String? rq = await _channel.invokeMethod('getRequestQueue');
    String? eq = await _channel.invokeMethod('getEventQueue');
    List<dynamic> requestList = json.decode(rq!); // List of strings
    List<dynamic> eventList = json.decode(eq!); // List of json objects

    // Some logs for debugging
    print('RQ: $requestList');
    print('EQ: $eventList');
    print('RQ length: ${requestList.length}');
    print('EQ length: ${eventList.length}');

    // Verify the request queue for a single request
    Uri uri = Uri.parse("?" + requestList[0]);
    Map<String, List<String>> queryParams = uri.queryParametersAll;
    testCommonRequestParams(queryParams); // tests

    // Verify some parameters of a single event
    Map<String, dynamic> event = json.decode(eventList[0]);
    expect("[CLY]_view", event['key']);
    expect(1, event['count']);
    expect(3, eventList.length);
  });
}
