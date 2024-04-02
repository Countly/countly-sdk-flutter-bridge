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
        expect(apm['apm_metrics']['C44CCC'], 1337);
        expect(apm['apm_metrics']['ABCDEF'], 1233);
      } else if (a == 2) {
        Map<String, dynamic> apm = json.decode(queryParams['apm']![0]);
        expect(apm['name'], 'Network Trace');
        expect(apm['apm_metrics']['response_code'], 200);
      } else if (a == 3 || a == 4) {
        Map<String, dynamic> crash = json.decode(queryParams['crash']![0]);
        expect(crash['_custom']['Cats'], null);
        expect(crash['_custom']['Moose'], null);
        expect(crash['_custom']['Moons'], '9.9866');
        expect(crash['_logs'], 'User Performed Step A' + '\n');
      } else if (a == 5) {
        // 0) Custom Event
        List<dynamic> eventList = json.decode(queryParams['events']![0]);
        var event = eventList[0];
        expect(event['key'], 'Event With Sum And Segment');
        expect(event['segmentation']['Country'], null);
        expect(event['segmentation']['Age'], '28884');
        // 1) View Start (legacy)
        var view = eventList[1];
        expect(view['key'], '[CLY]_view');
        expect(view['segmentation']['Cats'], null);
        expect(view['segmentation']['Moons'], '9.9866');
        expect(view['segmentation']['segment'], Platform.isIOS ? 'iOS' : 'Android');
        expect(view['segmentation']['start'], '1');
        expect(view['segmentation']['name'], 'HomePage');
        expect(view['segmentation']['Camel'], 666);
        expect(view['segmentation']['visit'], '1');
        expect(view['segmentation']['NotCamel'], 'Deerz');
        expect(view['segmentation']['Moose'], null);
        // 2) View End (legacy)
        view = eventList[2];
        expect(view['key'], '[CLY]_view');
        expect(view['segmentation']['segment'], Platform.isIOS ? 'iOS' : 'Android');
        expect(view['segmentation']['name'], 'HomePage');
        expect(view['segmentation']['Camel'], 666);
        expect(view['segmentation']['NotCamel'], 'Deerz');
        // 3) View Start (AutoStopped)
        view = eventList[3];
        expect(view['key'], '[CLY]_view');
        expect(view['segmentation']['Cats'], null);
        expect(view['segmentation']['Moons'], 9.9866);
        expect(view['segmentation']['segment'], Platform.isIOS ? 'iOS' : 'Android');
        expect(view['segmentation']['name'], 'hawk');
        expect(view['segmentation']['Camel'], 666);
        expect(view['segmentation']['visit'], '1');
        expect(view['segmentation']['NotCamel'], 'Deerz');
        expect(view['segmentation']['Moose'], null);
      } else if (a == 6) {
        Map<String, dynamic> userDetails = json.decode(queryParams['user_details']![0]);
        checkUnchangingUserPropeties(userDetails);
        expect(userDetails['custom']['special_value'], 'something special');
        expect(userDetails['custom']['not_special_value'], 'something special cooking');

        // TODO: this should be in a==7 for ios
        expect(userDetails['custom']['setProperty'], 'My Property');
      }

      // some logs for debugging
      print('RQ.$a: $queryParams');
      print('========================');
      a++;
    }
  });
}
