import 'package:countly_flutter/countly_flutter.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import '../../utils.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('210_CNR_AS_init_in_background_test', (WidgetTester tester) async {
    FlutterForegroundTask.minimizeApp();
    await tester.pump(Duration(seconds: 1));

    // Initialize the SDK
    CountlyConfig config = CountlyConfig(SERVER_URL, APP_KEY).setLoggingEnabled(true);
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
// RQ: [app_key=SHOULD_BE_YOUR_APP_KEY&device_id=E27B322E-B133-4847-A0EC-F660EF8540B4&t=1&timestamp=1721392584832&hour=13&dow=5&tz=60&sdk_version=24.7.0&sdk_name=dart-flutterb-ios&begin_session=1&metrics=%7B%22_device%22%3A%22x86_64%22%2C%22_device_type%22%3A%22mobile%22%2C%22_os_version%22%3A%2217.2%22%2C%22_locale%22%3A%22en_NG%22%2C%22_density%22%3A%22%403x%22%2C%22_app_version%22%3A%220.0.1%22%2C%22_resolution%22%3A%221290x2796%22%2C%22_os%22%3A%22iOS%22%7D&av=0.0.1]
// RQ length: 1
// EQ: []
// EQ length: 0

// Android
// RQ: []
// EQ: []
// RQ length: 0
// EQ length: 0
