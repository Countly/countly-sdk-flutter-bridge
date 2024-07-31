import 'dart:convert';
import 'dart:io';
import 'package:countly_flutter/countly_flutter.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import '../../utils.dart';

/// Manual session obeys no consent rules or not
/// expected requests are below
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('200_CR_CG_M_test', (WidgetTester tester) async {
    // Initialize the SDK
    CountlyConfig config = CountlyConfig(SERVER_URL, APP_KEY).setLoggingEnabled(true).enableManualSessionHandling().setRequiresConsent(true).giveAllConsents();
    await Countly.initWithConfig(config);

    // End session calls should not work
    await Countly.instance.sessions.endSession();
    await Countly.instance.sessions.endSession();

    // Update session calls should not work
    await Countly.instance.sessions.updateSession();
    await Countly.instance.sessions.updateSession();

    await tester.pump(Duration(seconds: 2));

    // Begin session call should work
    await Countly.instance.sessions.beginSession();

    await tester.pump(Duration(seconds: 2));

    // Second begin session call should not work
    await Countly.instance.sessions.beginSession();

    // Update calls now should work
    await Countly.instance.sessions.updateSession();
    await tester.pump(Duration(seconds: 2));
    await Countly.instance.sessions.updateSession();
    await tester.pump(Duration(seconds: 2));

    // End session call should work
    await Countly.instance.sessions.endSession();

    await tester.pump(Duration(seconds: 2));

    // Second end session call should not work
    await Countly.instance.sessions.endSession();

    // Update session calls should not work
    await Countly.instance.sessions.updateSession();
    await Countly.instance.sessions.updateSession();

    // Get request and event queues from native side
    List<String> requestList = await getRequestQueue(); // List of strings
    List<String> eventList = await getEventQueue(); // List of json objects

    // Some logs for debugging
    printQueues(requestList, eventList);

    // There should be:
    // 0- consent information
    // 1- orientation
    // 2- begin_session
    // 3- update_session
    // 4- update_session
    // 5- end_session
    expect(requestList.length, 6);

    var i = 0;
    for (var element in requestList) {
      Map<String, List<String>> queryParams = Uri.parse("?" + element).queryParametersAll;
      testCommonRequestParams(queryParams); // tests
      if (i == 0) {
        // example:
        // consent: [{"sessions":true,"crashes":true,"users":true,"push":true,"feedback":true,"scrolls":true,"remote-config":true,"attribution":true,"clicks":true,"location":true,"star-rating":true,"events":true,"views":true,"apm":true}]
        Map<String, dynamic> consentInRequest = jsonDecode(queryParams['consent']![0]);
        for (var key in ['push', 'feedback', 'crashes', 'attribution', 'users', 'events', 'remote-config', 'sessions', 'location', 'views', 'apm']) {
          expect(consentInRequest[key], true);
        }
        expect(consentInRequest.length, Platform.isAndroid ? 14 : 11);
      }
      if (Platform.isIOS) {
        if (i == 1) {
          expect(queryParams['events']?[0].contains('[CLY]_orientation'), true);
        } else if (i == 2) {
          expect(queryParams['begin_session']?[0], '1');
        } else if (i == 3 || i == 4) {
          expect(queryParams['session_duration']?[0], '2');
          expect(queryParams['end_session'], null);
        }
      }
      if (Platform.isAndroid) {
        if (i == 4) {
          expect(queryParams['events']?[0].contains('[CLY]_orientation'), true);
        } else if (i == 1) {
          expect(queryParams['begin_session']?[0], '1');
        } else if (i == 2 || i == 3) {
          expect(queryParams['session_duration']?[0], '2');
          expect(queryParams['end_session'], null);
        }
      } else if (i == 5) {
        expect(queryParams['end_session']?[0], '1');
        expect(queryParams['session_duration']?[0], '2');
      }
      print('RQ.$i: $queryParams');
      print('========================');
      i++;
    }
  });
}
