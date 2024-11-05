import 'dart:convert';
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

    await createMixViewsAndEvents(true);

    sleep(Duration(seconds: 1));
    goBackground();

    sleep(Duration(seconds: 1));
    await createMixViewsAndEvents(false);

    sleep(Duration(seconds: 1));
    // goForeground();

    // Get request and event queues from native side
    List<String> requestList = await getRequestQueue();
    List<String> eventList = await getEventQueue();

    // Some logs for debugging
    print('RQ: $requestList');
    print('EQ: $eventList');
    print('RQ length: ${requestList.length}');
    print('EQ length: ${eventList.length}');

    // Process each filtered request
    List<dynamic> events = await getEventsFromEventQueueAndRequestList();

    print('Filtered Events Both Request & Events List: ${events.length}');

    // Filter events based on keys
    var views = events.where((event) => event['key'] == '[CLY]_view').toList();
    print('Filtered Views: ${views.length}');

    var filteredEvents = events.where((event) => event['key'] != '[CLY]_view').toList();
    print('Filtered Events: ${filteredEvents.length}');

    var eventBG = filteredEvents.where((event) => event['key'].contains('_BG')).toList();
    var eventFG = filteredEvents.where((event) => event['key'].contains('_FG')).toList();

    // Filter views based on name segmentation
    var viewBG = views.where((view) => view['segmentation']['name'].contains('_BG')).toList();
    var viewFG = views.where((view) => view['segmentation']['name'].contains('_FG')).toList();


    // Some logs for debugging
    print('Filtered Views (BG): ${viewBG.length}');
    print('Filtered Views (FG): ${viewFG.length}');
    print('Filtered Events (BG): ${eventBG.length}');
    print('Filtered Events (FG): ${eventFG.length}');

    for (var view in viewFG) {
      print('ViewFG : $view');
      var viewName = view['segmentation']['name'];
      var viewVisit = view['segmentation']['visit'];

      if(viewVisit == null && (viewName == 'V1_FG' || viewName == 'V4_FG'))
      {
        expect(view['segmentation']['cly_v'], 0);
        expect(view['segmentation']['cly_pvn'], 'V3_FG');
      }
      else {
        expect(view['segmentation']['cly_v'], Platform.isIOS ? 1 : 0);
        if(viewName != 'V1_FG')
        {
          var currentNumber = int.parse(viewName.split('_')[0].substring(1));
          final expectedPrevName = 'V${currentNumber - 1}_FG';
          expect(view['segmentation']['cly_pvn'], equals(expectedPrevName));
        }
      }
    }

    for (var view in viewBG) {
      var viewName = view['segmentation']['name'];

      expect(view['segmentation']['cly_v'], 0);
      if(viewName != 'V1_BG')
      {
        var currentNumber = int.parse(viewName.split('_')[0].substring(1));
        final expectedPrevName = 'V${currentNumber - 1}_BG';
        expect(view['segmentation']['cly_pvn'], equals(expectedPrevName));
      }
      else {

        expect(view['segmentation']['cly_pvn'], 'V4_FG');
      }
    }

    for (var event in eventFG) {
      var eventName = event['key'];
      expect(event['segmentation']['cly_v'], Platform.isIOS ? 1 : 0);
      if(eventName != 'E1_FG')
      {
        var currentNumber = int.parse(eventName.split('_')[0].substring(1));
        final expectedPrevEventName = 'E${currentNumber - 1}_FG';
        final expectedCurrentViewName = 'V${currentNumber - 1}_FG';
        expect(event['segmentation']['cly_pen'], equals(expectedPrevEventName));
        expect(event['segmentation']['cly_cvn'], equals(expectedCurrentViewName));
      }
      else
      {
        expect(event['segmentation']['cly_pen'], "");
        expect(event['segmentation']['cly_cvn'], "");
      }
    }

    for (var event in eventBG) {
      var eventName = event['key'];
      expect(event['segmentation']['cly_v'], 0);
      if(eventName != 'E1_BG')
      {
        var currentNumber = int.parse(eventName.split('_')[0].substring(1));
        final expectedPrevEventName = 'E${currentNumber - 1}_BG';
        final expectedCurrentViewName = 'V${currentNumber - 1}_BG';
        expect(event['segmentation']['cly_pen'], equals(expectedPrevEventName));
        expect(event['segmentation']['cly_cvn'], equals(expectedCurrentViewName));
      }
      else
      {
        expect(event['segmentation']['cly_pen'], "E5_FG");
        expect(event['segmentation']['cly_cvn'], "V4_FG");
      }
    }

    var a = 0;
    for (var element in requestList) {
      Map<String, List<String>> queryParams = Uri.parse('?' + element).queryParametersAll;
      testCommonRequestParams(queryParams); // checks general params
      // some logs for debugging
      print('RQ.$a: $queryParams');
      print('========================');
      a++;
    }
  });
}
