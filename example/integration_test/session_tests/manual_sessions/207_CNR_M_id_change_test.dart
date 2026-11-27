import 'dart:io';

import 'package:countly_flutter/countly_flutter.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import '../../utils.dart';

/// Check when no consent is required and manual session handling is enabled, the behavior of the SDK
/// details of the requests are mentioned below
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('207_CNR_M_id_change', (WidgetTester tester) async {
    // Initialize the SDK
    CountlyConfig config = CountlyConfig(SERVER_URL, APP_KEY).setLoggingEnabled(true).enableManualSessionHandling();
    await Countly.initWithConfig(config);

    // These calls should not work
    await Countly.instance.sessions.endSession();
    await Countly.instance.sessions.updateSession();
    await Countly.instance.sessions.updateSession();

    await Future.delayed(Duration(seconds: 2));

    await Countly.changeDeviceId('newID', true); // should not reporty session duration

    await Countly.instance.sessions.beginSession(); // should work
    await Future.delayed(Duration(seconds: 2));
    await Countly.instance.sessions.endSession(); // should work

    await Countly.changeDeviceId('newID_2', false);

    await Countly.instance.sessions.endSession(); // should not work
    await Countly.instance.sessions.beginSession();
    await Future.delayed(Duration(seconds: 2));
    await Countly.changeDeviceId('newID_3', false);

    // Get request and event queues from native side
    List<String> requestList = await getRequestQueue(); // List of strings
    List<String> eventList = await getEventQueue(); // List of json objects

    // Some logs for debugging
    print('RQ: $requestList');
    print('EQ: $eventList');
    print('RQ length: ${requestList.length}');
    print('EQ length: ${eventList.length}');

    // There should be the device ID change, begin session (newID), end session, begin session (newID_2) and the
    // orientation. The orientation event: iOS SDK 26.8.1 records it once, when the SDK starts, while the SDK guide and Android record it at begin_session. So Android records it at both begin sessions, and iOS once,
    // under the first device ID, before the device ID change.
    final List<String> expected = Platform.isIOS ? ['orientation', 'change', 'begin newID', 'end', 'begin newID_2'] : ['change', 'begin newID', 'orientation', 'end', 'begin newID_2', 'orientation'];
    expect(requestList.length, expected.length);
    var i = 0;
    for (var element in requestList) {
      Map<String, List<String>> queryParams = Uri.parse("?" + element).queryParametersAll;
      testCommonRequestParams(queryParams); // tests
      if (expected[i] == 'change') {
        expect(queryParams['device_id']?[0], 'newID');
        expect(queryParams['old_device_id']?[0].isNotEmpty, true);
      } else if (expected[i].startsWith('begin ')) {
        expect(queryParams['begin_session']?[0], '1');
        expect(queryParams['device_id']?[0], expected[i].substring('begin '.length));
      } else if (expected[i] == 'orientation') {
        expect(queryParams['events']?[0].contains('[CLY]_orientation'), true);
      } else if (expected[i] == 'end') {
        expect(queryParams['end_session']?[0], '1');
        expect(queryParams['session_duration']?[0], '2');
        expect(queryParams['device_id']?[0], 'newID');
      }

      print('RQ.$i: $queryParams');
      print('========================');
      i++;
    }

    // expect(i, 4); // counter must be only 4
  });
}
