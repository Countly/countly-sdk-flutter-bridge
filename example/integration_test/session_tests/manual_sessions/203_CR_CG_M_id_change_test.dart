import 'dart:convert';
import 'dart:io';
import 'package:countly_flutter_np/countly_flutter.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import '../../utils.dart';

/// Check when consent is required (&given) and manual session handling is enabled, the behavior of the SDK
/// details of the requests are mentioned below
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('203_CR_CG_M_id_change', (WidgetTester tester) async {
    // Initialize the SDK
    CountlyConfig config = CountlyConfig(SERVER_URL, APP_KEY).setLoggingEnabled(true).enableManualSessionHandling().setRequiresConsent(true).giveAllConsents();
    await Countly.initWithConfig(config);

    // These calls should not work
    await Countly.instance.sessions.endSession();
    await Countly.instance.sessions.updateSession();
    await Countly.instance.sessions.updateSession();

    await tester.pump(Duration(seconds: 2));

    await Countly.changeDeviceId('newID', true);

    // Begin session call should work
    await Countly.instance.sessions.beginSession();

    await tester.pump(Duration(seconds: 2));

    // End session call should work
    await Countly.instance.sessions.endSession();

    await tester.pump(Duration(seconds: 2));

    await Countly.changeDeviceId('newID_2', false);
    await tester.pump(Duration(seconds: 1));
    await Countly.instance.sessions.beginSession();
    await tester.pump(Duration(seconds: 1));
    await Countly.instance.sessions.endSession();

    await tester.pump(Duration(seconds: 1));
    await Countly.giveAllConsent();
    await tester.pump(Duration(seconds: 1));
    await Countly.instance.sessions.beginSession();
    await tester.pump(Duration(seconds: 2));
    await Countly.changeDeviceId('newID_3', false);

    // Get request and event queues from native side
    List<String> requestList = await getRequestQueue(); // List of strings
    List<String> eventList = await getEventQueue(); // List of json objects

    // Some logs for debugging
    print('RQ: $requestList');
    print('EQ: $eventList');
    print('RQ length: ${requestList.length}');
    print('EQ length: ${eventList.length}');

    // Currently:
    // 0- consent information, true
    // 1- Orientation (iOS only)
    // 2- device ID change
    // 3- begin session
    // 4- end session
    // 5- location
    // 6- consent information, true
    // 7- begin session
    // 8- end session
    // 9- location
    expect(requestList.length, Platform.isAndroid ? 11 : 10);

    var i = 0;
    for (var element in requestList) {
      Map<String, List<String>> queryParams = Uri.parse("?" + element).queryParametersAll;
      testCommonRequestParams(queryParams); // tests
      if (i == 0 || (Platform.isAndroid && i == 6) || (Platform.isIOS && i == 6)) {
        // example:
        // consent: [{"sessions":true,"crashes":true,"users":true,"push":true,"feedback":true,"scrolls":true,"remote-config":true,"attribution":true,"clicks":true,"location":true,"star-rating":true,"events":true,"views":true,"apm":true}]
        Map<String, dynamic> consentInRequest = jsonDecode(queryParams['consent']![0]);
        for (var key in ['push', 'feedback', 'crashes', 'attribution', 'users', 'events', 'remote-config', 'sessions', 'location', 'views', 'apm', 'content']) {
          expect(consentInRequest[key], true);
        }
        expect(consentInRequest.length, Platform.isAndroid ? 15 : 12);
      } else if ((Platform.isAndroid && (i == 3 || i == 8)) || (Platform.isIOS && i == 1)) {
        expect(queryParams['events']?[0].contains('[CLY]_orientation'), true);
      } else if ((Platform.isAndroid && i == 1) || (Platform.isIOS && i == 2)) {
        expect(queryParams['device_id']?[0], 'newID');
        expect(queryParams['old_device_id']?[0].isNotEmpty, true);
      } else if ((Platform.isAndroid && (i == 7 || i == 2)) || (Platform.isIOS && (i == 7 || i == 3))) {
        expect(queryParams['begin_session']?[0], '1');
      } else if ((Platform.isIOS && (i == 4 || i == 8)) || (Platform.isAndroid && (i == 4 || i == 9))) {
        expect(queryParams['end_session']?[0], '1');
        expect(queryParams['session_duration']?[0], '2');
      } else if ((Platform.isIOS && (i == 5 || i == 9)) || (Platform.isAndroid && (i == 5 || i == 10))) {
        expect(queryParams['location'], ['']);
        if (Platform.isAndroid) {
          expect(queryParams['device_id']?[0], i == 5 ? 'newID' : 'newID_2');
        } else {
          expect(queryParams['device_id']?[0], i == 5 ? 'newID_2' : 'newID_3');
        }
      }

      print('RQ.$i: $queryParams');
      print('========================');
      i++;
    }
  });
}
