import 'package:countly_flutter_np/countly_flutter.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'dart:io';
import '../utils.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('BM_202A_normalDelay', (WidgetTester tester) async {
    List<Map<String, List<String>>> requestArray = <Map<String, List<String>>>[];

    // Initialize the SDK
    CountlyConfig config = CountlyConfig(TEST_SERVER_URL, APP_KEY).enableManualSessionHandling().setLoggingEnabled(true).setMaxRequestQueueSize(10);
    await Countly.initWithConfig(config);

    storeRequest({
      "azd": "begin_session",
      "timestamp": "1747083600000",
      "app_key": APP_KEY,
      "device_id": "1234567890",
    });

    storeRequest({
      "yuz": "ttf",
      "timestamp": "1747083600000",
      "app_key": APP_KEY,
      "device_id": "1234567890",
    });

    storeRequest({
      "hgj": "sss",
      "timestamp": "1747083600000",
      "app_key": APP_KEY,
      "device_id": "1234567890",
    });

    storeRequest({
      "ffg": "aaa",
      "timestamp": "1747083600000",
      "app_key": APP_KEY,
      "device_id": "1234567890",
    });

    Countly.instance.sessions.beginSession();
    Countly.instance.sessions.updateSession();
    Countly.instance.sessions.endSession();
    await Future.delayed(const Duration(seconds: 10));

    List<String> requestList = await getRequestQueue(); // List of strings
    List<String> eventList = await getEventQueue(); // List of json objects
    expect(requestList.length, Platform.isAndroid ? 7 : 8);
    expect(eventList.length, 0);

    createServer(requestArray, delay: 1);
    Countly.instance.attemptToSendStoredRequests();
    await Future.delayed(const Duration(seconds: 20));
    requestList = await getRequestQueue(); // List of strings
    eventList = await getEventQueue(); // List of json objects
    expect(requestList.length, 0); // 3 requests sent
    expect(eventList.length, 0); // no events sent
  });
}
