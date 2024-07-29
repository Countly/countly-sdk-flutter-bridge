import 'dart:io';

import 'package:countly_flutter/countly_flutter.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import '../../utils.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('204_CNR_A_id_change', (WidgetTester tester) async {
    // Initialize the SDK
    CountlyConfig config = CountlyConfig(SERVER_URL, APP_KEY).setLoggingEnabled(true);
    await Countly.initWithConfig(config);

    await Future.delayed(Duration(seconds: 1));
    await Countly.changeDeviceId('newID', true);
    await Countly.instance.sessions.beginSession();
    await Countly.instance.sessions.updateSession();
    await Countly.instance.sessions.endSession();

    await Future.delayed(Duration(seconds: 2));
    await Countly.changeDeviceId('newID_2', false);
    await Countly.instance.sessions.beginSession();
    await Countly.instance.sessions.updateSession();
    await Countly.instance.sessions.endSession();

    FlutterForegroundTask.minimizeApp();
    await tester.pump(Duration(seconds: 2));
    FlutterForegroundTask.launchApp();

    await Future.delayed(Duration(seconds: 1));
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
    // - begin_session
    // - change ID
    // - Orientation (ios only)
    // - end session
    // - begin_session
    // - end session (ios only)
    // - begin session (ios only)
    // - change ID
    // EQ: orientation (android only)
    expect(requestList.length, Platform.isAndroid ? 5 : 8);

    var i = 0;
    for (var element in requestList) {
      Map<String, List<String>> queryParams = Uri.parse("?" + element).queryParametersAll;
      testCommonRequestParams(queryParams); // tests
      if (i == 0 || (Platform.isAndroid && i == 3) || (Platform.isIOS && (i == 4 || i == 6))) {
        expect(queryParams['begin_session']?[0], '1');
        if (i == 3 || i == 4 || i == 6) {
          expect(queryParams['device_id']?[0], 'newID_2');
        }
      } else if (i == 1 || (Platform.isAndroid && i == 4) || (Platform.isIOS && i == 7)) {
        expect(queryParams['old_device_id']?[0].isNotEmpty, true);
        if (i == 7) {
          expect(queryParams['old_device_id']?[0], 'newID_2');
        }
        expect(queryParams['device_id']?[0], 'newID');
      } else if ((Platform.isAndroid && i == 2) || (Platform.isIOS && (i == 3 || i == 5) )) {
        expect(queryParams['end_session']?[0].isNotEmpty, true);
        expect(queryParams['session_duration']?[0].isNotEmpty, true);
        expect(queryParams['device_id']?[0], i == 5 ? 'newID_2' : 'newID');
      } else if ((Platform.isIOS && i == 2)) {
        expect(queryParams['events']?[0].contains('[CLY]_orientation'), true);
      }



      print('RQ.$i: $queryParams');
      print('========================');
      i++;
    }
  });
}
