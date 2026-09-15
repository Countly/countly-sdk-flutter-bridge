import 'package:countly_flutter_np/countly_flutter.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../utils.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('BM_201C_backoffDelay_oldRequests', (WidgetTester tester) async {
    List<Map<String, List<String>>> requestArray = <Map<String, List<String>>>[];

    // Initialize the SDK
    CountlyConfig config = CountlyConfig(TEST_SERVER_URL, APP_KEY).enableManualSessionHandling().setLoggingEnabled(true);
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

    // Get request and event queues from native side
    List<String> requestList = await getRequestQueue(); // List of strings
    List<String> eventList = await getEventQueue(); // List of json objects

    expect(requestList.length, 5);
    expect(eventList.length, 1);

    createServer(requestArray, delay: 11);
    Countly.instance.attemptToSendStoredRequests();

    await Future.delayed(const Duration(seconds: 90));
    requestList = await getRequestQueue();
    eventList = await getEventQueue();
    expect(requestList.length, 1); // backed off after session req
    expect(eventList.length, 0);
  });
}
