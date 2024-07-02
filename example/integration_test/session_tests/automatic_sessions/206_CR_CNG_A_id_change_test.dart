import 'dart:convert';
import 'dart:io';

import 'package:countly_flutter_np/countly_flutter.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import '../../utils.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('206_CR_CNG_A_id_change', (WidgetTester tester) async {
    // Initialize the SDK
    CountlyConfig config = CountlyConfig(SERVER_URL, APP_KEY).setLoggingEnabled(true).setRequiresConsent(true);
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

    await tester.pump(Duration(seconds: 1));
    await Countly.changeDeviceId('newID', true);

    // Get request and event queues from native side
    List<String> requestList = await getRequestQueue(); // List of strings
    List<String> eventList = await getEventQueue(); // List of json objects

    // Some logs for debugging
    print('RQ: $requestList');
    print('EQ: $eventList');
    print('RQ length: ${requestList.length}');
    print('EQ length: ${eventList.length}');

    // Currently
    // - consents (android only)
    // - location (android only)
    // - change ID
    // - change ID
    // - change ID
    expect(requestList.length, Platform.isAndroid ? 5 : 3);

    var i = 0;
    for (var element in requestList) {
      Map<String, List<String>> queryParams = Uri.parse("?" + element).queryParametersAll;
      testCommonRequestParams(queryParams); // tests
      if (Platform.isAndroid && i == 0) {
        // example:
        // consent: [{"sessions":true,"crashes":true,"users":true,"push":true,"feedback":true,"scrolls":true,"remote-config":true,"attribution":true,"clicks":true,"location":true,"star-rating":true,"events":true,"views":true,"apm":true}]
        Map<String, dynamic> consentInRequest = jsonDecode(queryParams['consent']![0]);
        for (var key in ['push', 'feedback', 'crashes', 'attribution', 'users', 'events', 'remote-config', 'sessions', 'location', 'views', 'apm']) {
          expect(consentInRequest[key], false);
        }
        expect(consentInRequest.length, Platform.isAndroid ? 14 : 11);
      } else if ((Platform.isAndroid && (i == 2 || i == 3 || i == 4)) || (Platform.isIOS && (i == 0 || i == 1 || i == 2))) {
        expect(queryParams['old_device_id']?[0].isNotEmpty, true);
        expect(queryParams['device_id']?[0], 'newID');
      } else if (Platform.isAndroid && (i == 1)) {
        expect(queryParams['location'], ['']);
        expect(queryParams['device_id']?[0] != 'newID', true);
      }

      print('RQ.$i: $queryParams');
      print('========================');
      i++;
    }
  });
}
