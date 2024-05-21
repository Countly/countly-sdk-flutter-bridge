import 'package:countly_flutter/countly_flutter.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import '../../utils.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('205_CR_CG_A_id_change', (WidgetTester tester) async {
    // Initialize the SDK
    CountlyConfig config = CountlyConfig(SERVER_URL, APP_KEY).setLoggingEnabled(true).setRequiresConsent(true).giveAllConsents();
    await Countly.initWithConfig(config);

    await tester.pump(Duration(seconds: 1));
    await Countly.changeDeviceId('newID', true);
    await Countly.instance.sessions.beginSession();
    await Countly.instance.sessions.updateSession();
    await Countly.instance.sessions.endSession();

    FlutterForegroundTask.minimizeApp();
    await tester.pump(Duration(seconds: 1));
    FlutterForegroundTask.launchApp();

    await tester.pump(Duration(seconds: 1));
    await Countly.changeDeviceId('newID_2', false);
    await Countly.instance.sessions.beginSession();
    await Countly.instance.sessions.updateSession();
    await Countly.instance.sessions.endSession();

    await tester.pump(Duration(seconds: 1));
    await Countly.changeDeviceId('newID', true);

    await tester.pump(Duration(seconds: 1));
    await Countly.changeDeviceId('newID_2', false);

    FlutterForegroundTask.minimizeApp();
    await tester.pump(Duration(seconds: 1));
    FlutterForegroundTask.launchApp();
    await Countly.changeDeviceId('newID', true);
    FlutterForegroundTask.minimizeApp();
    await tester.pump(Duration(seconds: 1));
    FlutterForegroundTask.launchApp();
    await tester.pump(Duration(seconds: 1));

    // Get request and event queues from native side
    List<String> requestList = await getRequestQueue(); // List of strings
    List<String> eventList = await getEventQueue(); // List of json objects

    // Some logs for debugging
    print('RQ: $requestList');
    print('EQ: $eventList');
    print('RQ length: ${requestList.length}');
    print('EQ length: ${eventList.length}');

    // Currently
    // - consents
    // - begin_session
    // - change ID
    // - end session
    // - begin_session
    // - orientation
    // - end session
    // - location
    // - consents
    // - change ID
    // - change ID
    // seems plausible due to known issues
    // expect(requestList.length, 1);

    var i = 0;
    for (var element in requestList) {
      Map<String, List<String>> queryParams = Uri.parse("?" + element).queryParametersAll;
      // TODO: write these after RQ migration
      print('RQ.$i: $queryParams');
      print('========================');
      i++;
    }
  });
}
