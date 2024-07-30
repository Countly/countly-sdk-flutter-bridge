import 'dart:convert';

import 'package:countly_flutter/countly_flutter.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import '../../utils.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('210_CNR_AS_init_in_background_test', (WidgetTester tester) async {
    List<String> requestList = await getRequestQueue(); // List of strings
    List<String> eventList = await getEventQueue(); // List of json objects

    expect(requestList.length, 0);
    expect(eventList.length, 0);
    FlutterForegroundTask.minimizeApp();

    // Initialize the SDK
    CountlyConfig config = CountlyConfig(SERVER_URL, APP_KEY).setLoggingEnabled(true);
    await Countly.initWithConfig(config);
    await Future.delayed(const Duration(seconds: 1));

    // Get request and event queues from native side
    requestList = await getRequestQueue(); // List of strings
    eventList = await getEventQueue(); // List of json objects

    expect(requestList.length, 0);
    expect(eventList.length, 0);

    await tester.pump(Duration(seconds: 1));
    FlutterForegroundTask.launchApp();
    await tester.pump(Duration(seconds: 1));

    // Some logs for debugging
    print('RQ: $requestList');
    print('RQ length: ${requestList.length}');
    print('EQ: $eventList');
    print('EQ length: ${eventList.length}');

    requestList = await getRequestQueue(); // List of strings
    eventList = await getEventQueue(); // List of json objects

    print('RQ: $requestList');
    print('RQ length: ${requestList.length}');
    print('EQ: $eventList');
    print('EQ length: ${eventList.length}');

    expect(requestList.length, 1); // begin session
    Map<String, List<String>> queryParams = Uri.parse("?" + requestList[0]).queryParametersAll;
    testCommonRequestParams(queryParams); // tests
    expect(queryParams['begin_session']?[0], '1');

    expect(eventList.length, 1); // orientation

    Map<String, dynamic> event = json.decode(eventList[0]);
    expect("[CLY]_orientation", event['key']);
  });
}
