import 'package:countly_flutter/countly_flutter.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import '../../utils.dart';
import 'dart:convert';
import 'dart:io';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('212_CR_CG_AS_init_in_background_test', (WidgetTester tester) async {
    FlutterForegroundTask.minimizeApp();
    await tester.pump(Duration(seconds: 2));

    // Initialize the SDK
    CountlyConfig config = CountlyConfig(SERVER_URL, APP_KEY).setLoggingEnabled(true).setRequiresConsent(true).giveAllConsents();
    await Countly.initWithConfig(config);
    await Future.delayed(const Duration(seconds: 1));

    // Get request and event queues from native side
    List<String> requestList = await getRequestQueue(); // List of strings
    List<String> eventList = await getEventQueue(); // List of json objects

    printQueues(requestList, eventList);

    expect(requestList.length, 1);
    expect(eventList.length, 0);

    FlutterForegroundTask.launchApp();
    printMessageMultipleTimes('go to foreground now', 3);
    await tester.pump(Duration(seconds: 4));

    // Some logs for debugging
    printQueues(requestList, eventList);

    requestList = await getRequestQueue(); // List of strings
    eventList = await getEventQueue(); // List of json objects

    printQueues(requestList, eventList);

    expect(requestList.length, 2); // begin session, consents
    Map<String, List<String>> queryParams = Uri.parse("?" + requestList[1]).queryParametersAll;
    testCommonRequestParams(queryParams); // tests
    expect(queryParams['begin_session']?[0], '1');

    Map<String, List<String>> queryParamsConsent = Uri.parse("?" + requestList[0]).queryParametersAll;
    Map<String, dynamic> consentInRequest = jsonDecode(queryParamsConsent['consent']![0]);
    for (var key in ['push', 'feedback', 'crashes', 'attribution', 'users', 'events', 'remote-config', 'sessions', 'location', 'views', 'apm', 'content']) {
      expect(consentInRequest[key], true);
    }
    expect(consentInRequest.length, Platform.isAndroid ? 15 : 12);

    expect(eventList.length, 1); // orientation

    Map<String, dynamic> event = json.decode(eventList[0]);
    expect("[CLY]_orientation", event['key']);
  });
}
