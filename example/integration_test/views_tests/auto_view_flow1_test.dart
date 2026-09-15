import 'dart:convert';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'dart:io';

import 'package:countly_flutter_np/countly_flutter.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import '../utils.dart';
import 'view_utils.dart';

///
/// This test is to check the flow of views is auto stopped and restarted
/// and also when the app is in background and then comes to foreground
/// and also to check if the previous view names are recorded
///
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('Start auto stopped views and stop views', (WidgetTester tester) async {
    // Initialize the SDK
    CountlyConfig config = CountlyConfig(SERVER_URL, APP_KEY).setLoggingEnabled(true);
    await Countly.initWithConfig(config);

    await Countly.instance.views.startView("V1");
    await Countly.instance.views.startAutoStoppedView("V2");

    FlutterForegroundTask.minimizeApp();
    await Future.delayed(const Duration(seconds: 2));

    await Countly.instance.views.startAutoStoppedView("V4");
    await Countly.instance.views.startView("V3");

    await Future.delayed(const Duration(seconds: 2));

    FlutterForegroundTask.launchApp();
    if (Platform.isIOS) {
      printMessageMultipleTimes('waiting for 3 seconds, now go to foreground', 3);
    }

    sleep(Duration(seconds: 5));

    // REQUESTS: begin session, events before going in to the background, and end session
    // EVENTS: end view for V1, V2, start view of V4, end view for V4, start view V3, orientation, start view for V1, V2
    List<String> requestList = await getRequestQueue();
    List<String> eventList = await getEventQueue();

    printQueues(requestList, eventList);
    expect(requestList.length, 4);
    expect(eventList.length, Platform.isAndroid ? anyOf(8, 9) : anyOf(6, 7));
    validateBeginSessionRequest(requestList[0]); // validate begin session on 0th idx

    Map<String, List<String>> queryParams = Uri.parse('?${requestList[1]}').queryParametersAll;
    var rqEvents = jsonDecode(queryParams['events']![0]);
    expect(rqEvents.length, Platform.isAndroid ? 3 : 4);
    int index = 0;
    if (Platform.isAndroid) {
      validateEvent("[CLY]_orientation", <String, dynamic>{'mode': 'portrait'}, eventGiven: rqEvents[index++]);
    }
    validateView("V1", true, true, viewGiven: rqEvents[index++]);
    validateView("V2", false, true, viewGiven: rqEvents[index++]);
    if (Platform.isIOS) {
      int iCached = index;
      try {
        validateView("V1", false, false, viewGiven: rqEvents[index++]);
        validateView("V2", false, false, viewGiven: rqEvents[index++]);
      } catch (e) {
        index = iCached;
        validateView("V2", false, false, viewGiven: rqEvents[index++]);
        validateView("V1", false, false, viewGiven: rqEvents[index++]);
      }
    }

    validateEndSessionRequest(requestList[2]); // validate end session on 2nd idx
    validateBeginSessionRequest(requestList[3]); // validate begin session on 3rd idx

    index = 0;
    if (Platform.isAndroid) {
      try {
        validateView("V1", false, false, viewStr: eventList[index++]);
        validateView("V2", false, false, viewStr: eventList[index++]);
      } catch (e) {
        index = 0;
        validateView("V2", false, false, viewStr: eventList[index++]);
        validateView("V1", false, false, viewStr: eventList[index++]);
      }
    }

    validateView("V4", false, true, viewStr: eventList[index++]);
    validateView("V4", false, false, viewStr: eventList[index++]);
    validateView("V3", false, true, viewStr: eventList[index++]);
    validateEvent("[CLY]_orientation", <String, dynamic>{'mode': 'portrait'}, eventStr: eventList[index++]);

    int iCached = index;
    try {
      validateView("V2", true, true, viewStr: eventList[index++]);
      validateView("V2", false, false, viewStr: eventList[index++]);
      validateView("V1", false, true, viewStr: eventList[index++]);
    } catch (e) {
      index = iCached;
      validateView("V1", true, true, viewStr: eventList[index++]);
      validateView("V2", false, true, viewStr: eventList[index++]);
    }
  });
}
