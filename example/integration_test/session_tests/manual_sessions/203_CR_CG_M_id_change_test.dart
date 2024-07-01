import 'dart:convert';
import 'dart:io';
import 'package:countly_flutter/countly_flutter.dart';
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

    await Countly.changeDeviceId('newID_2', false);

    await Countly.instance.sessions.beginSession();
    await Countly.instance.sessions.endSession();

    await Countly.giveAllConsent();
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
    // - consent information, true
    // - device ID change
    // - begin session
    // - end session
    // - location (android only)
    // - consent information, true
    // - begin session
    // - end session (android only)
    // - location (android only)
    expect(requestList.length, Platform.isAndroid ? 9 : 6);

    var i = 0;
    for (var element in requestList) {
      Map<String, List<String>> queryParams = Uri.parse("?" + element).queryParametersAll;
      testCommonRequestParams(queryParams); // tests
      if (i == 0 || (Platform.isAndroid && i == 5) || (Platform.isIOS && i == 4)) {
        // example:
        // consent: [{"sessions":true,"crashes":true,"users":true,"push":true,"feedback":true,"scrolls":true,"remote-config":true,"attribution":true,"clicks":true,"location":true,"star-rating":true,"events":true,"views":true,"apm":true}]
        Map<String, dynamic> consentInRequest = jsonDecode(queryParams['consent']![0]);
        for (var key in ['push', 'feedback', 'crashes', 'attribution', 'users', 'events', 'remote-config', 'sessions', 'location', 'views', 'apm']) {
          expect(consentInRequest[key], true);
        }
        expect(consentInRequest.length, Platform.isAndroid ? 14 : 11);
      } else if (i == 1) {
        expect(queryParams['device_id']?[0], 'newID');
        expect(queryParams['old_device_id']?[0].isNotEmpty, true);
      } else if (i == 2 || (Platform.isAndroid && i == 6) || (Platform.isIOS && i == 5)) {
        expect(queryParams['begin_session']?[0], '1');
      } else if (i == 3 || (Platform.isAndroid && i == 7)) {
        expect(queryParams['end_session']?[0], '1');
        expect(queryParams['session_duration']?[0], '2');
      } else if (Platform.isAndroid && (i == 4 || i == 8)) {
        expect(queryParams['location'], ['']);
        expect(queryParams['device_id']?[0], i == 4 ? 'newID' : 'newID_2');
      }

      print('RQ.$i: $queryParams');
      print('========================');
      i++;
    }
  });
}
