import 'package:countly_flutter_np/countly_flutter.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../utils.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('BM_000_base', (WidgetTester tester) async {
    List<Map<String, List<String>>> requestArray = <Map<String, List<String>>>[];
    createServer(requestArray);
    // Initialize the SDK
    CountlyConfig config = CountlyConfig(TEST_SERVER_URL, APP_KEY).enableManualSessionHandling().setLoggingEnabled(true);
    await Countly.initWithConfig(config);

    Countly.instance.sessions.beginSession();
    Countly.instance.events.recordEvent("test_event");

    // Get request and event queues from native side
    List<String> requestList = await getRequestQueue(); // List of strings
    List<String> eventList = await getEventQueue(); // List of json objects
    // check the queues are not empty
    printQueues(requestList, eventList);
    expect(requestList.isNotEmpty, true);
    expect(eventList.isNotEmpty, true);
    Countly.instance.attemptToSendStoredRequests();

    // check queues are empty
    await Future.delayed(const Duration(seconds: 10));
    requestList = await getRequestQueue();
    eventList = await getEventQueue();
    printQueues(requestList, eventList);
    expect(requestList.isEmpty, true);
    expect(eventList.isEmpty, true);
  });
}
