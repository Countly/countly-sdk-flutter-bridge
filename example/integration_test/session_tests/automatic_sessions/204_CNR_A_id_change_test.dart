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
    // 0- begin_session
    // 1- change ID
    // 2- end session
    // 3- begin_session
    // 4- end session
    // 5- begin_session
    // 6- change ID
    // EQ: orientation (android only)
    expect(requestList.length, Platform.isAndroid ? 7 : 6);
    expect(eventList.length, 1);

    var i = 0;
    for (var element in requestList) {
      Map<String, List<String>> queryParams = Uri.parse("?" + element).queryParametersAll;
      testCommonRequestParams(queryParams); // tests
      if (i == 0 || i == 3 || i == 5) {
        expect(queryParams['begin_session']?[0], '1');
        if (i == 3) {
          expect(queryParams['device_id']?[0], 'newID_2');
        }
      } else if (i == 1 || (Platform.isAndroid && i == 6) || (Platform.isIOS && i == 5)) {
        expect(queryParams['old_device_id']?[0].isNotEmpty, true);
        if (i == 5) {
          expect(queryParams['old_device_id']?[0], 'newID_2');
        }
        expect(queryParams['device_id']?[0], 'newID');
      } else if (i == 2 || (Platform.isIOS && i == 4)) {
        expect(queryParams['end_session']?[0].isNotEmpty, true);
        expect(queryParams['session_duration']?[0].isNotEmpty, true);
        expect(queryParams['device_id']?[0], i == 4 ? 'newID_2' : 'newID');
      }

      print('RQ.$i: $queryParams');
      print('========================');
      i++;
    }
  });
}
