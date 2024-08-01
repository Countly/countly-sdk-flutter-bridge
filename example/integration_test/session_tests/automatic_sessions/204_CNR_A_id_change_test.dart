import 'dart:convert';
import 'dart:io';

import 'package:countly_flutter_np/countly_flutter.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import '../../utils.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('204_CNR_A_id_change', (WidgetTester tester) async {
    // Initialize the SDK
    CountlyConfig config = CountlyConfig(SERVER_URL, APP_KEY).setLoggingEnabled(true);
    await Countly.initWithConfig(config); // generates 0.begin_session

    await Future.delayed(Duration(seconds: 1));
    await Countly.instance.deviceId.changeWithMerge('newID'); // generates 1.change_id

    // useless manual calls
    await Countly.instance.sessions.beginSession();
    await Countly.instance.sessions.updateSession();
    await Countly.instance.sessions.endSession();

    await Future.delayed(Duration(seconds: 2));
    await Countly.instance.deviceId.changeWithoutMerge('newID_2');
    // generates 2.end_session, 3.begin_session

    // useless manual calls
    await Countly.instance.sessions.beginSession();
    await Countly.instance.sessions.updateSession();
    await Countly.instance.sessions.endSession();

    FlutterForegroundTask.minimizeApp(); // generates 4.end_session
    if (Platform.isIOS) {
      printMessageMultipleTimes('will now go to background, get ready to go foreground manually', 3);
    }
    await tester.pump(Duration(seconds: 3));
    FlutterForegroundTask.launchApp(); // generates 5.begin_session
    if (Platform.isIOS) {
      printMessageMultipleTimes('waiting for 3 seconds, now go to foreground', 3);
    }
    await tester.pump(Duration(seconds: 3));

    await Countly.instance.deviceId.changeWithMerge('newID'); // generates 6.change_id

    // Get request and event queues from native side
    List<String> requestList = await getRequestQueue(); // List of strings
    List<String> eventList = await getEventQueue(); // List of json objects

    // Some logs for debugging
    printQueues(requestList, eventList);

    // Currently
    // 0- begin_session
    // 1- change ID
    // 2- end session
    // 3- begin_session
    // 4- end session
    // 5- begin_session (auto fg in ios not working)
    // 6- change ID
    // EQ: orientation (android only)
    expect(requestList.length, Platform.isAndroid ? 9 : 8);
    expect(eventList.length, Platform.isAndroid ? 1 : 0);

    if (Platform.isAndroid) {
      Map<String, dynamic> event = json.decode(eventList[0]);
      expect("[CLY]_orientation", event['key']);
    }

    var i = 0;
    var androidBeginSession = [0, 4, 7];
    var iosBeginSession = [0, 3, 6];
    var androidMerge = [1, 8];
    var iosMerge = [1, 7];
    var androidOrientation = [2, 5];
    var iosOrientation = [4];
    var androidEndSession = [3, 6];
    var iosEndSession = [2, 5];
    for (var element in requestList) {
      Map<String, List<String>> queryParams = Uri.parse("?" + element).queryParametersAll;
      testCommonRequestParams(queryParams); // tests
      if ((Platform.isAndroid && androidBeginSession.contains(i)) || (Platform.isIOS && iosBeginSession.contains(i))) {
        checkBeginSession(queryParams);
      } else if ((Platform.isAndroid && androidMerge.contains(i)) || (Platform.isIOS && iosMerge.contains(i))) {
        checkMerge(queryParams, deviceID: 'newID', oldDeviceID: i != 1 ? 'newID_2' : '');
      } else if ((Platform.isAndroid && androidEndSession.contains(i)) || (Platform.isIOS && iosEndSession.contains(i))) {
        checkEndSession(queryParams, deviceID: i == 3 || i == 2 ? 'newID' : 'newID_2');
      } else if ((Platform.isAndroid && androidOrientation.contains(i)) || (Platform.isIOS && iosOrientation.contains(i))) {
        expect(queryParams['events']?[0].contains('[CLY]_orientation'), true);
      }

      print('RQ.$i: $queryParams');
      print('========================');
      i++;
    }
  });
}
