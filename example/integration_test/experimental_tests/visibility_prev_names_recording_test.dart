import 'dart:convert';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'dart:io';

import 'package:countly_flutter/countly_flutter.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import '../utils.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('Init SDK with some visibility and previous names recording', (WidgetTester tester) async {
    // Initialize the SDK
    CountlyConfig config = CountlyConfig(SERVER_URL, APP_KEY).setLoggingEnabled(true);
    config.experimental.enableVisibilityTracking().enablePreviousNameRecording();
    await Countly.initWithConfig(config);

    await createMixViewsAndEvents(inForeground: true);
    sleep(Duration(seconds: 2)); // lets add duration to session

    FlutterForegroundTask.minimizeApp();
    sleep(Duration(seconds: 2));

    // record events and views in background
    await createMixViewsAndEvents(inForeground: false);

    FlutterForegroundTask.launchApp();
    if (Platform.isIOS) {
      printMessageMultipleTimes('waiting for 3 seconds, now go to foreground', 3);
    }
    sleep(Duration(seconds: 5));

    // Get request and event queues from native side
    List<String> requestList = await getRequestQueue();
    List<String> eventList = await getEventQueue();

    // Some logs for debugging
    printQueues(requestList, eventList);

    // Begin session
    // events and views in foreground
    // end session
    // begin session
    expect(requestList.length, 4);

    // events and views in background and then after we come to foreground
    // depending on which view is started first after fg, we can have 9 or 10 events
    expect(eventList.length, anyOf([9, 10]));

    for (var entry in requestList.asMap().entries) {
      int index = entry.key;
      var element = entry.value;

      Map<String, List<String>> queryParams = Uri.parse('?' + element).queryParametersAll;
      testCommonRequestParams(queryParams);

      // start and then when to fg
      if (index == 0 || index == 3) {
        expect(queryParams['begin_session']?[0], '1');
      }
      // when going to bg
      if (index == 2) {
        expect(queryParams['end_session']?[0], '1');
        expect(queryParams['session_duration']?[0], '2');
      }
      if (index == 1) {
        var rqEvents = jsonDecode(queryParams['events']![0]);
        expect(rqEvents.length, 7);
        // events nad views at initial fg
        checkEventAndViews(rqEvents, true);
        // events and views after going to bg and coming back to fg
        checkEventAndViews(eventList, false);
      }

      print('RQ.$index: $queryParams');
      print('========================');
    }
  });
}

void checkEventAndViews(eventArray, isFGEvents) {
  if (isFGEvents) {
    expect(eventArray[0]['key'], 'E1_FG');
    expect(eventArray[1]['segmentation']['name'], 'V1_FG');
    expect(eventArray[2]['key'], 'E2_FG');
    expect(eventArray[3]['segmentation']['name'], 'V2_FG');
    expect(eventArray[4]['key'], 'E3_FG');
    // closed in random order
    try {
      expect(eventArray[5]['segmentation']['name'], 'V2_FG');
      expect(eventArray[6]['segmentation']['name'], 'V1_FG');
    } catch (e) {
      expect(eventArray[5]['segmentation']['name'], 'V1_FG');
      expect(eventArray[6]['segmentation']['name'], 'V2_FG');
    }
  } else {
    expect(jsonDecode(eventArray[0])['key'], 'E1_BG');
    expect(jsonDecode(eventArray[1])['segmentation']['name'], 'V1_BG');
    expect(jsonDecode(eventArray[2])['key'], 'E2_BG');
    expect(jsonDecode(eventArray[3])['segmentation']['name'], 'V2_BG');
    expect(jsonDecode(eventArray[4])['key'], 'E3_BG');
    expect(jsonDecode(eventArray[5])['key'], '[CLY]_orientation');
    expect(jsonDecode(eventArray[6])['segmentation']['name'], 'V2_BG');
    // this part is random as autoStopped or normal view can start first
    try {
      expect(jsonDecode(eventArray[7])['segmentation']['name'], 'V2_BG');
      expect(jsonDecode(eventArray[8])['segmentation']['name'], 'V2_FG');
      expect(jsonDecode(eventArray[9])['segmentation']['name'], 'V1_FG');
    } catch (e) {
      expect(jsonDecode(eventArray[7])['segmentation']['name'], 'V1_FG');
      expect(jsonDecode(eventArray[8])['segmentation']['name'], 'V2_FG');
    }
  }
}
