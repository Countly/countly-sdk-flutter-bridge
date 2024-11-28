import 'dart:convert';
import 'dart:io';

import 'package:countly_flutter/countly_flutter.dart';
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
    await Countly.instance.deviceId.changeWithMerge('newID');
    await Countly.instance.sessions.beginSession();
    await Countly.instance.sessions.updateSession();
    await Countly.instance.sessions.endSession();

    goBackgroundAndForeground();

    await tester.pump(Duration(seconds: 1));
    await Countly.instance.deviceId.changeWithoutMerge('newID_2');
    await Countly.instance.sessions.beginSession();
    await Countly.instance.sessions.updateSession();
    await Countly.instance.sessions.endSession();

    await tester.pump(Duration(seconds: 1));
    await Countly.instance.deviceId.changeWithMerge('newID');

    await tester.pump(Duration(seconds: 1));
    await Countly.instance.deviceId.changeWithoutMerge('newID_2');

    await tester.pump(Duration(seconds: 1));
    await Countly.instance.deviceId.changeWithMerge('newID');

    // Get request and event queues from native side
    List<String> requestList = await getRequestQueue(); // List of strings
    List<String> eventList = await getEventQueue(); // List of json objects

    // Some logs for debugging
    printQueues(requestList, eventList);

    // Currently
    // - consents (begin ses in ios)
    // - begin_session (consent in ios)
    // - change ID
    // - orientation (android only)
    // - end session (orientation in ios)
    // - begin_session (end session in ios)
    // - orientation (begin session in ios)
    // - end session
    // - location
    // - change ID
    // - change ID
    expect(requestList.length, Platform.isAndroid ? 11 : 10);
    expect(eventList.length, 0);

    var i = 0;
    for (var element in requestList) {
      Map<String, List<String>> queryParams = Uri.parse("?" + element).queryParametersAll;
      testCommonRequestParams(queryParams); // tests
      if ((Platform.isAndroid && i == 0) || (Platform.isIOS && i == 1)) {
        // example:
        // consent: [{"sessions":true,"crashes":true,"users":true,"push":true,"feedback":true,"scrolls":true,"remote-config":true,"attribution":true,"clicks":true,"location":true,"star-rating":true,"events":true,"views":true,"apm":true}]
        Map<String, dynamic> consentInRequest = jsonDecode(queryParams['consent']![0]);
        for (var key in ['push', 'feedback', 'crashes', 'attribution', 'users', 'events', 'remote-config', 'sessions', 'location', 'views', 'apm', 'content']) {
          expect(consentInRequest[key], true);
        }
        expect(consentInRequest.length, Platform.isAndroid ? 15 : 12);
      } else if ((Platform.isAndroid && (i == 1 || i == 5)) || (Platform.isIOS && (i == 0 || i == 5))) {
        expect(queryParams['begin_session']?[0], '1');
      } else if (i == 2 || (Platform.isAndroid && (i == 10 || i == 9)) || (Platform.isIOS && (i == 8 || i == 9))) {
        expect(queryParams['old_device_id']?[0].isNotEmpty, true);
        expect(queryParams['device_id']?[0], 'newID');
      } else if ((Platform.isAndroid && (i == 4 || i == 7)) || (Platform.isIOS && (i == 4 || i == 6))) {
        expect(queryParams['end_session']?[0], '1');
        expect(queryParams['session_duration']?[0].isNotEmpty, true);
        expect(queryParams['device_id']?[0], 'newID');
      } else if ((Platform.isAndroid && (i == 3 || i == 6)) || (Platform.isIOS && i == 3)) {
        expect(queryParams['events']?[0].contains('[CLY]_orientation'), true);
        expect(queryParams['device_id']?[0], 'newID');
      } else if (Platform.isAndroid && (i == 8)) {
        expect(queryParams['location'], ['']);
        expect(queryParams['device_id']?[0], 'newID');
      }

      print('RQ.$i: $queryParams');
      print('========================');
      i++;
    }
  });
}
