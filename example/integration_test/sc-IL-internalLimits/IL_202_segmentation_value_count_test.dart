import 'dart:convert';
import 'dart:io';

import 'package:countly_flutter/countly_flutter.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import '../utils.dart';

/// Check if setting setMaxSegmentationValues to 1 limits the segmentation value count
/// Tested values are:
/// - Event and View segmentation count
/// - Custom Crash segmentation count
/// - Global View and Crash segmentation count

const int MAX_SEGMENTATION_COUNT = 1;
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('Init SDK with setMaxSegmentationValues', (WidgetTester tester) async {
    // Initialize the SDK
    CountlyConfig config = CountlyConfig(SERVER_URL, APP_KEY).setLoggingEnabled(true);
    config.sdkInternalLimits.setMaxSegmentationValues(MAX_SEGMENTATION_COUNT);
    await Countly.initWithConfig(config);

    // Create truncable events
    await createTruncableEvents();

    // Get request and event queues from native side
    List<String> requestList = await getRequestQueue();
    List<String> eventList = await getEventQueue();

    // Some logs for debugging
    print('RQ: $requestList');
    print('EQ: $eventList');
    print('RQ length: ${requestList.length}');
    print('EQ length: ${eventList.length}');

    expect(requestList.length, Platform.isIOS ? 8 : 7); // user properties and custom user properties are separately sent in iOS
    expect(eventList.length, 0);

    // TODO: refactor this part (move to utils and make it more generic)
    // 0: begin session
    // 1: custom APM with segmentation
    // 2: network Trace
    // 3: custom fatality crash with segmentation
    // 4: custom mortal crash with segmentation
    // 5: custom view and events with segmentation
    // 6: custom user properties
    var a = 0;
    for (var element in requestList) {
      Map<String, List<String>> queryParams = Uri.parse('?' + element).queryParametersAll;
      testCommonRequestParams(queryParams); // checks general params
      if (a == 1) {
        Map<String, dynamic> apm = json.decode(queryParams['apm']![0]);
        expect(apm['name'], 'Trace');
        expect(apm['apm_metrics']['C44CCC'], null);
        expect(apm['apm_metrics']['ABCDEF'], 1233);
      } else if (a == 2) {
        Map<String, dynamic> apm = json.decode(queryParams['apm']![0]);
        expect(apm['name'], 'Network Trace');
        expect(apm['apm_metrics']['response_code'], 200);
      } else if (a == 3 || a == 4) {
        Map<String, dynamic> crash = json.decode(queryParams['crash']![0]);
        expect(crash['_custom'].length, MAX_SEGMENTATION_COUNT);
        var dateSizeIOS = a == 3 ? 21 : 43;
        var dateSizeAndroid = a == 3 ? 22 : 44;
        expect(crash['_logs'].length, Platform.isIOS ? dateSizeIOS : dateSizeAndroid); // adding date in iOS
      } else if (a == 5) {
        // 0) Custom Event
        List<dynamic> eventList = json.decode(queryParams['events']![0]);
        int eventIdx = Platform.isAndroid ? 1 : 0; // why 1 for android, because android adds orientation
        var event = eventList[eventIdx];
        expect(event['key'], 'Event With Sum And Segment');
        expect(event['segmentation'].length, MAX_SEGMENTATION_COUNT);
        // 1) View Start (legacy)
        var view = eventList[eventIdx + 1];
        expect(view['key'], '[CLY]_view');
        expect(view['segmentation']['segment'], Platform.isIOS ? 'iOS' : 'Android');
        expect(view['segmentation']['start'], Platform.isIOS ? 1 : '1');
        expect(view['segmentation']['name'], 'HomePage');
        expect(view['segmentation']['visit'], Platform.isIOS ? 1 : '1');
        expect(view['segmentation'].length, MAX_SEGMENTATION_COUNT + 4);
        // 2) View End (legacy)
        view = eventList[eventIdx + 2];
        expect(view['key'], '[CLY]_view');
        expect(view['segmentation']['segment'], Platform.isIOS ? 'iOS' : 'Android');
        expect(view['segmentation']['name'], 'HomePage');
        expect(view['segmentation'].length, MAX_SEGMENTATION_COUNT + 2);

        // 3) View Start (AutoStopped)
        view = eventList[eventIdx + 3];
        expect(view['key'], '[CLY]_view');
        expect(view['segmentation']['segment'], Platform.isIOS ? 'iOS' : 'Android');
        expect(view['segmentation']['name'], 'hawk');
        expect(view['segmentation']['visit'], Platform.isIOS ? 1 : '1');
        expect(view['segmentation'].length, MAX_SEGMENTATION_COUNT + 3);
      } else if (a == 6) {
        Map<String, dynamic> userDetails = json.decode(queryParams['user_details']![0]);
        expect(userDetails['custom'].length, Platform.isAndroid ? 10 : MAX_SEGMENTATION_COUNT); // Android does not filter custom mods
        checkUnchangingUserPropeties(userDetails, null);

        if (Platform.isAndroid) {
          checkUnchangingUserData(userDetails, null, null);
        }
      } else if (Platform.isIOS && a == 7) {
        Map<String, dynamic> userDetails = json.decode(queryParams['user_details']![0]);
        checkUnchangingUserData(userDetails, null, null);
        expect(userDetails['custom'].length, 10);
      }

      // some logs for debugging
      print('RQ.$a: $queryParams');
      print('========================');
      a++;
    }
  });
}
