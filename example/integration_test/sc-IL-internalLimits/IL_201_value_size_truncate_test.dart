import 'dart:convert';
import 'dart:io';

import 'package:countly_flutter/countly_flutter.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import '../utils.dart';

/// Check if setting setMaxValueSize to 1 truncates the values
/// Tested values are:
/// - Event and View segmentation values
/// - Custom Crash segmentation values
/// - Global View and Crash segmentation values
/// - Custom User Property values and their modifications (with mul, push, pull, set, increment, etc)
/// - User Profile named key (username, email, etc) values (except the "picture" field, which has a limit of 4096 chars)
/// - Breadcrumb value (text)
/// - TODO: Manual Feedback and Rating Widgets reporting fields

const int MAX_VALUE_SIZE = 1;
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('Init SDK with setMaxValueSize', (WidgetTester tester) async {
    // Initialize the SDK
    CountlyConfig config = CountlyConfig(SERVER_URL, APP_KEY).setLoggingEnabled(true);
    config.sdkInternalLimits.setMaxValueSize(MAX_VALUE_SIZE);
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

    expect(7, requestList.length);
    expect(0, eventList.length);

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
      } else if (a == 3 || a == 4) {
        Map<String, dynamic> crash = json.decode(queryParams['crash']![0]);
        expect(crash['_custom']['Cats'], '12345'.substring(0, MAX_VALUE_SIZE));
        expect(crash['_custom']['Moose'], 'Deer'.substring(0, MAX_VALUE_SIZE));
        expect(crash['_custom']['Moons'], '9.9866'.substring(0, MAX_VALUE_SIZE));
        expect(crash['_logs'], 'User Performed Step A'.substring(0, MAX_VALUE_SIZE) + '\n');
      } else if (a == 5) {
        // 0) Custom Event
        List<dynamic> eventList = json.decode(queryParams['events']![0]);
        var event = eventList[0];
        expect(event['key'], 'Event With Sum And Segment');
        expect(event['segmentation']['Country'], 'Turkey'.substring(0, MAX_VALUE_SIZE));
        expect(event['segmentation']['Age'], '28884'.substring(0, MAX_VALUE_SIZE));
        // 1) View Start (legacy)
        var view = eventList[1];
        expect(view['key'], '[CLY]_view');
        expect(view['segmentation']['Cats'], '12345'.substring(0, MAX_VALUE_SIZE));
        expect(view['segmentation']['Moons'], '9.9866'.substring(0, MAX_VALUE_SIZE));
        expect(view['segmentation']['segment'], Platform.isIOS ? 'iOS' : 'Android');
        expect(view['segmentation']['start'], '1');
        expect(view['segmentation']['name'], 'HomePage');
        expect(view['segmentation']['Camel'], 666);
        expect(view['segmentation']['visit'], '1');
        expect(view['segmentation']['NotCamel'], 'Deerz'.substring(0, MAX_VALUE_SIZE));
        expect(view['segmentation']['Moose'], 'Deer'.substring(0, MAX_VALUE_SIZE));
        // 2) View End (legacy)
        view = eventList[2];
        expect(view['key'], '[CLY]_view');
        expect(view['segmentation']['segment'], Platform.isIOS ? 'iOS' : 'Android');
        expect(view['segmentation']['name'], 'HomePage');
        expect(view['segmentation']['Camel'], 666);
        expect(view['segmentation']['NotCamel'], 'Deerz'.substring(0, MAX_VALUE_SIZE));
        // 3) View Start (AutoStopped)
        view = eventList[3];
        expect(view['key'], '[CLY]_view');
        expect(view['segmentation']['Cats'], 12345);
        expect(view['segmentation']['Moons'], 9.9866);
        expect(view['segmentation']['segment'], Platform.isIOS ? 'iOS' : 'Android');
        expect(view['segmentation']['name'], 'hawk');
        expect(view['segmentation']['Camel'], 666);
        expect(view['segmentation']['visit'], '1');
        expect(view['segmentation']['NotCamel'], 'Deerz'.substring(0, MAX_VALUE_SIZE));
        expect(view['segmentation']['Moose'], 'Deer'.substring(0, MAX_VALUE_SIZE));
        // 4) View End (AutoStopped)
        view = eventList[4];
        expect(view['key'], '[CLY]_view');
        expect(view['segmentation']['segment'], Platform.isIOS ? 'iOS' : 'Android');
        expect(view['segmentation']['name'], 'hawk');
        expect(view['segmentation']['Camel'], 666);
        expect(view['segmentation']['NotCamel'], 'Deerz'.substring(0, MAX_VALUE_SIZE));
      } else if (a == 6) {
        Map<String, dynamic> userDetails = json.decode(queryParams['user_details']![0]);
        checkUnchangingUserPropeties(userDetails);
        expect(userDetails['custom']['special_value'], 'something special'.substring(0, MAX_VALUE_SIZE));
        expect(userDetails['custom']['not_special_value'], 'something special cooking'.substring(0, MAX_VALUE_SIZE));
        expect(userDetails['custom']['setProperty'], 'My Property'.substring(0, MAX_VALUE_SIZE));
      }

      // some logs for debugging
      print('RQ.$a: $queryParams');
      print('========================');
      a++;
    }
  });
}
