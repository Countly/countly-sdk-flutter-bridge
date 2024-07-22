import 'package:countly_flutter/countly_flutter.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import '../../utils.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('211_CNR_MS_init_in_background_test', (WidgetTester tester) async {
    FlutterForegroundTask.minimizeApp();
    await tester.pump(Duration(seconds: 1));

    // Initialize the SDK
    CountlyConfig config = CountlyConfig(SERVER_URL, APP_KEY).setLoggingEnabled(true).enableManualSessionHandling();
    await Countly.initWithConfig(config);
    await Future.delayed(const Duration(seconds: 5));
    FlutterForegroundTask.launchApp();

    // Get request and event queues from native side
    List<String> requestList = await getRequestQueue(); // List of strings
    List<String> eventList = await getEventQueue(); // List of json objects

    // Some logs for debugging
    print('RQ: $requestList');
    print('RQ length: ${requestList.length}');
    print('EQ: $eventList');
    print('EQ length: ${eventList.length}');

    expect(requestList.length, 0);
    expect(eventList.length, 0);
  });
}

// iOS
// RQ: []
// RQ length: 0
// EQ: []
// EQ length: 0

// Android
// RQ: []
// RQ length: 0
// EQ: []
// EQ length: 0
