import 'dart:convert';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'dart:io';

import 'package:countly_flutter/countly_flutter.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import '../utils.dart';

var pen = "";
var cvn = "";
var cvn_end = "";
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
    // But for android, we have 11 events or 12 because end view calls are not recorded to the RQ
    expect(eventList.length, Platform.isAndroid ? anyOf([11, 12]) : anyOf([9, 10]));

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
        expect(queryParams['session_duration']?[0], anyOf(['2', '3']));
      }
      if (index == 1) {
        var rqEvents = jsonDecode(queryParams['events']![0]);
        expect(rqEvents.length, Platform.isAndroid ? 6 : 7);

        // events and views at initial fg
        checkEventAndViews(rqEvents, true);
        // events and views after going to bg and coming back to fg
        checkEventAndViews(
          eventList,
          false,
        );
      }

      print('RQ.$index: $queryParams');
      print('========================');
    }
  });
}

void checkEventAndViews(eventArray, isFGEvents) {
  if (isFGEvents) {
    int index = 0;
    if (Platform.isAndroid) {
      // in Android 0th element is orientation event
      index = 1;
      expect(eventArray[0]['key'], "[CLY]_orientation");
    }
    checkEvent(eventArray[index], 'E1_FG', true);
    checkViewStart(eventArray[index + 1], 'V1_FG', true);
    checkEvent(eventArray[index + 2], 'E2_FG', true);
    checkViewStart((eventArray[index + 3]), 'V2_FG', true);
    checkEvent((eventArray[index + 4]), 'E3_FG', true);
    // closed in random order
    if (!Platform.isAndroid) {
      try {
        checkViewEnd((eventArray[5]), 'V2_FG', true);
        checkViewEnd((eventArray[6]), 'V1_FG', true);
      } catch (e) {
        checkViewEnd((eventArray[5]), 'V1_FG', true);
        checkViewEnd((eventArray[6]), 'V2_FG', true);
      }
    }
  } else {
    int index = 0;
    if (Platform.isAndroid) {
      try {
        checkViewEnd(jsonDecode(eventArray[index]), 'V2_FG', true);
        checkViewEnd(jsonDecode(eventArray[index + 1]), 'V1_FG', true);
      } catch (e) {
        checkViewEnd(jsonDecode(eventArray[index]), 'V1_FG', true);
        checkViewEnd(jsonDecode(eventArray[index + 1]), 'V2_FG', true);
      }
      index = 2;
    }
    checkEvent(jsonDecode(eventArray[index]), 'E1_BG', false);
    checkViewStart(jsonDecode(eventArray[index + 1]), 'V1_BG', false);
    checkEvent(jsonDecode(eventArray[index + 2]), 'E2_BG', false);
    checkViewStart(jsonDecode(eventArray[index + 3]), 'V2_BG', false);
    checkEvent(jsonDecode(eventArray[index + 4]), 'E3_BG', false);
    expect(jsonDecode(eventArray[index + 5])['key'], '[CLY]_orientation');
    checkViewEnd(jsonDecode(eventArray[index + 6]), 'V2_BG', false);
    // this part is random as autoStopped or normal view can start first
    try {
      checkRestartedView(jsonDecode(eventArray[index + 7]), 'V2_FG', true, false);

      expect(jsonDecode(eventArray[index + 8])['segmentation']['name'], 'V2_FG');
      expect(jsonDecode(eventArray[index + 8])['segmentation']['fg_events'], false);
      expect(jsonDecode(eventArray[index + 8])['segmentation']['cly_v'], isNull);
      expect(jsonDecode(eventArray[index + 8])['segmentation']['visit'], isNull);
      expect(jsonDecode(eventArray[index + 8])['segmentation']['cly_pvn'], cvn_end);

      checkRestartedView(jsonDecode(eventArray[index + 9]), 'V1_FG', true, false);
    } catch (e) {
      checkRestartedView(jsonDecode(eventArray[index + 7]), 'V1_FG', true, false);
      checkRestartedView(jsonDecode(eventArray[index + 8]), 'V2_FG', true, false);
    }
  }
}

void checkEvent(event, key, isVisible) {
  expect(event['key'], key);
  expect(event['segmentation']['cly_pen'], pen);
  expect(event['segmentation']['cly_v'], isVisible ? 1 : 0);
  expect(event['segmentation']['cly_cvn'], cvn);
  pen = key;
}

void checkViewStart(view, name, isVisible) {
  expect(view['segmentation']['name'], name);
  expect(view['segmentation']['fg_events'], isVisible);
  expect(view['segmentation']['cly_v'], isVisible ? 1 : 0);
  expect(view['segmentation']['visit'], Platform.isAndroid ? '1' : 1);
  expect(view['segmentation']['cly_pvn'], cvn);
  cvn_end = cvn;
  cvn = name;
}

void checkViewEnd(view, name, isVisible) {
  expect(view['segmentation']['name'], name);
  expect(view['segmentation']['fg_events'], isVisible);
  expect(view['segmentation']['cly_v'], isNull);
  expect(view['segmentation']['visit'], isNull);
  expect(view['segmentation']['cly_pvn'], cvn_end);
}

void checkRestartedView(view, name, isVisible, globalSegmentation) {
  expect(view['segmentation']['name'], name);
  expect(view['segmentation']['fg_events'], globalSegmentation);
  expect(view['segmentation']['cly_v'], isVisible ? 1 : 0);
  expect(view['segmentation']['visit'], Platform.isAndroid ? '1' : 1);
  expect(view['segmentation']['cly_pvn'], cvn);
  cvn_end = cvn;
  cvn = name;
}
