import 'package:countly_flutter_np/countly_flutter.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../utils.dart';

Future<void> verifyQueuesAfterDelay({
  required int expectedRequestCount,
  required List<String> expectedRequestContains,
  required int expectedEventCount,
  int delaySeconds = 30,
}) async {
  await Future.delayed(Duration(seconds: delaySeconds));

  final requestList = await getRequestQueue();
  final eventList = await getEventQueue();
  printQueues(requestList, eventList);

  expect(requestList.length, expectedRequestCount);
  for (int i = 0; i < expectedRequestContains.length; i++) {
    expect(requestList[i], contains(expectedRequestContains[i]));
  }
  expect(eventList.length, expectedEventCount);
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('BM_201A_backoffDelay', (WidgetTester tester) async {
    List<Map<String, List<String>>> requestArray = <Map<String, List<String>>>[];
    createServer(requestArray, delay: 11);

    // Initialize the SDK
    CountlyConfig config = CountlyConfig(TEST_SERVER_URL, APP_KEY).enableManualSessionHandling().setLoggingEnabled(true);
    await Countly.initWithConfig(config); // generates 0.begin_session

    // Perform session operations
    Countly.instance.sessions.beginSession(); // this should be sent to the server
    await Future.delayed(const Duration(seconds: 2));
    Countly.instance.sessions.updateSession(); // this should back off
    await Future.delayed(const Duration(seconds: 2));
    Countly.instance.sessions.endSession(); // this should be still backed off

    // Get initial request and event queues from native side
    await getRequestQueue();
    await getEventQueue();

    // begin session sent. backed off, 30 seconds later nothing sent
    await verifyQueuesAfterDelay(
      expectedRequestCount: 3,
      expectedRequestContains: ['session_duration', 'events', 'end_session'],
      expectedEventCount: 0,
    );

    // 30 more seconds later, still nothing sent
    await verifyQueuesAfterDelay(
      expectedRequestCount: 3,
      expectedRequestContains: ['session_duration', 'events', 'end_session'],
      expectedEventCount: 0,
    );

    // session update sent, backed off, 30 seconds later nothing sent
    await verifyQueuesAfterDelay(
      expectedRequestCount: 2,
      expectedRequestContains: ['events', 'end_session'],
      expectedEventCount: 0,
    );

    changeServerDelay(0);

    // 60 seconds later, after non delayed responses everything sent
    await verifyQueuesAfterDelay(
      expectedRequestCount: 0,
      expectedRequestContains: [],
      expectedEventCount: 0,
      delaySeconds: 60,
    );
  });
}
