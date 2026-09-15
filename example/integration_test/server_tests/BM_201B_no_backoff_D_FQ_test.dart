import 'package:countly_flutter_np/countly_flutter.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'dart:io';
import '../utils.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('BM_201B_backoffDelay_requests', (WidgetTester tester) async {
    List<Map<String, List<String>>> requestArray = <Map<String, List<String>>>[];
    // Initialize the SDK
    CountlyConfig config = CountlyConfig(TEST_SERVER_URL, APP_KEY).enableManualSessionHandling().setLoggingEnabled(true).setMaxRequestQueueSize(10);
    await Countly.initWithConfig(config);

    Countly.instance.sessions.beginSession();
    Countly.instance.sessions.updateSession();
    Countly.instance.sessions.endSession();

    Countly.instance.sessions.beginSession();
    Countly.instance.sessions.updateSession();
    Countly.instance.sessions.endSession();

    Countly.instance.sessions.beginSession();
    Countly.instance.sessions.updateSession();
    Countly.instance.sessions.endSession();

    await Future.delayed(const Duration(seconds: 10));

    // Get request and event queues from native side
    List<String> requestList = await getRequestQueue(); // List of strings
    List<String> eventList = await getEventQueue(); // List of json objects

    expect(requestList.length, Platform.isAndroid ? 9 : 10);
    expect(eventList.length, 0);

    createServer(requestArray, delay: 11);
    Countly.instance.attemptToSendStoredRequests();

    await Future.delayed(const Duration(seconds: 50));

    requestList = await getRequestQueue(); // List of strings
    eventList = await getEventQueue(); // List of json objects

    expect(requestList.length, Platform.isAndroid ? 5 : 6);
    expect(eventList.length, 0);

    await Future.delayed(const Duration(seconds: 30));
    Countly.instance.attemptToSendStoredRequests();
    Countly.instance.attemptToSendStoredRequests();
    Countly.instance.attemptToSendStoredRequests();
    await Future.delayed(const Duration(seconds: 20));

    requestList = await getRequestQueue(); // List of strings
    eventList = await getEventQueue(); // List of json objects

    expect(requestList.length, 5);
    expect(eventList.length, 0);
  });
}
