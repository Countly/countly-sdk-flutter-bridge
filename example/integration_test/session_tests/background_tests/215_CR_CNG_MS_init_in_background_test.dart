import 'package:countly_flutter/countly_flutter.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import '../../utils.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('215_CR_CG_init_in_background_test', (WidgetTester tester) async {
    FlutterForegroundTask.minimizeApp();
    await tester.pump(Duration(seconds: 1));

    // Initialize the SDK
    CountlyConfig config = CountlyConfig(SERVER_URL, APP_KEY).setLoggingEnabled(true).enableManualSessionHandling().setRequiresConsent(true);
    await Countly.initWithConfig(config);
    await Future.delayed(const Duration(seconds: 5));
    FlutterForegroundTask.launchApp();

    // Get request and event queues from native side
    List<String> requestList = await getRequestQueue(); // List of strings
    List<String> eventList = await getEventQueue(); // List of json objects

    // Some logs for debugging
    print('RQ: $requestList');
    print('EQ: $eventList');
    print('RQ length: ${requestList.length}');
    print('EQ length: ${eventList.length}');

    expect(requestList.length, 2);
    expect(eventList.length, 0);
  });
}

// iOS
// RQ: []
// EQ: []
// RQ length: 0
// EQ length: 0

// Android
// RQ: [app_key=SHOULD_BE_YOUR_APP_KEY&device_id=8d96618c730fd640&timestamp=1721639781636&sdk_version=24.7.0&sdk_name=dart-flutterb-android&av=1.0.0&hour=10&dow=1&tz=60&consent=%7B%22sessions%22%3Afalse%2C%22crashes%22%3Afalse%2C%22users%22%3Afalse%2C%22push%22%3Afalse%2C%22feedback%22%3Afalse%2C%22scrolls%22%3Afalse%2C%22remote-config%22%3Afalse%2C%22attribution%22%3Afalse%2C%22clicks%22%3Afalse%2C%22location%22%3Afalse%2C%22star-rating%22%3Afalse%2C%22events%22%3Afalse%2C%22views%22%3Afalse%2C%22apm%22%3Afalse%7D, app_key=SHOULD_BE_YOUR_APP_KEY&device_id=8d96618c730fd640&timestamp=1721639781646&sdk_version=24.7.0&sdk_name=dart-flutterb-android&av=1.0.0&hour=10&dow=1&tz=60&location=]
// EQ: []
// RQ length: 2
// EQ length: 0
