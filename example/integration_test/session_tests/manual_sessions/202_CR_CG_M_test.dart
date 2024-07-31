import 'dart:convert';
import 'package:countly_flutter_np/countly_flutter.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import '../../utils.dart';
import 'dart:io';

/// Check if no session requests generated
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('202_CR_CG_M', (WidgetTester tester) async {
    // Initialize the SDK
    CountlyConfig config = CountlyConfig(SERVER_URL, APP_KEY).setLoggingEnabled(true).enableManualSessionHandling().setRequiresConsent(true);
    await Countly.initWithConfig(config);

    // End session calls should not work
    await Countly.instance.sessions.endSession();
    await Countly.instance.sessions.endSession();

    // Update session calls should not work
    await Countly.instance.sessions.updateSession();
    await Countly.instance.sessions.updateSession();

    await tester.pump(Duration(seconds: 2));

    // Begin session call should not work
    await Countly.instance.sessions.beginSession();

    await tester.pump(Duration(seconds: 2));

    // Second begin session call should not work
    await Countly.instance.sessions.beginSession();

    // Update calls now should not work
    await Countly.instance.sessions.updateSession();
    await tester.pump(Duration(seconds: 2));
    await Countly.instance.sessions.updateSession();
    await tester.pump(Duration(seconds: 2));

    // End session call should not work
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
    print('RQ: $requestList');
    print('EQ: $eventList');
    print('RQ length: ${requestList.length}');
    print('EQ length: ${eventList.length}');

    // There should be:
    // - consent information
    // - empty location
    expect(requestList.length, 2);

    var i = 0;
    for (var element in requestList) {
      Map<String, List<String>> queryParams = Uri.parse("?" + element).queryParametersAll;
      testCommonRequestParams(queryParams); // tests
      if (i == 0) {
        // example:
        // consent: [{"sessions":true,"crashes":true,"users":true,"push":true,"feedback":true,"scrolls":true,"remote-config":true,"attribution":true,"clicks":true,"location":true,"star-rating":true,"events":true,"views":true,"apm":true}]
        Map<String, dynamic> consentInRequest = jsonDecode(queryParams['consent']![0]);
        for (var key in ['push', 'feedback', 'crashes', 'attribution', 'users', 'events', 'remote-config', 'sessions', 'location', 'views', 'apm']) {
          expect(consentInRequest[key], false);
        }
        expect(consentInRequest.length, Platform.isAndroid ? 14 : 11);
      } else if (i == 1) {
        expect(queryParams['location'], ['']);
      }
      print('RQ.$i: $queryParams');
      print('========================');
      i++;
    }
  });
}
