import 'dart:convert';
import 'dart:io';

import 'package:countly_flutter_np/countly_flutter.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import '../utils.dart';

/// Check if setting setMaxKeyLength to 1 truncates the keys (except internal keys)
/// Tested keys are:
/// - Event names and Event segmentation keys
/// - View names and View segmentation keys
/// - Custom APM trace keys and their segmentation keys
/// - Custom Crash segmentation keys
/// - Global View segmentation keys
/// - Custom User Property names and their modifications (with mul, push, pull, set, increment, etc)

const int MAX_KEY_LENGTH = 1;
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('Init SDK with setMaxKeyLength', (WidgetTester tester) async {
    // Initialize the SDK
    CountlyConfig config = CountlyConfig(SERVER_URL, APP_KEY).setLoggingEnabled(true);
    config.sdkInternalLimits.setMaxKeyLength(MAX_KEY_LENGTH);
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

    // TODO: refactor this part (mote to utils and make it more generic)
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
        expect(apm['name'], 'Trace'.substring(0, MAX_KEY_LENGTH));
      } else if (a == 2) {
        Map<String, dynamic> apm = json.decode(queryParams['apm']![0]);
        expect(apm['name'], 'Network Trace'.substring(0, MAX_KEY_LENGTH));
      } else if (a == 3 || a == 4) {
        Map<String, dynamic> crash = json.decode(queryParams['crash']![0]);
        expect(crash['_custom']['Cats'.substring(0, MAX_KEY_LENGTH)], '12345');
        expect(crash['_custom']['Moose'.substring(0, MAX_KEY_LENGTH)], 'Deer');
        // merges with moose if limit is small
        // expect(crash['_custom']['Moons'.substring(0, MAX_KEY_LENGTH)], '9.9866');
      } else if (a == 5) {
        // 0) Custom Event
        var eventRaw = json.decode(queryParams['events']![0]);
        Map<String, dynamic> event = eventRaw[0];
        expect(event['key'], 'Event With Sum And Segment'.substring(0, MAX_KEY_LENGTH));
        expect(event['segmentation']['Country'.substring(0, MAX_KEY_LENGTH)], 'Turkey');
        expect(event['segmentation']['Age'.substring(0, MAX_KEY_LENGTH)], '28884');
        // 1) View Start (legacy)
        Map<String, dynamic> view = eventRaw[1];
        expect(view['key'], '[CLY]_view');
        expect(view['segmentation']['Cats'.substring(0, MAX_KEY_LENGTH)], '12345');
        // merges with moose if limit is small
        // expect(view['segmentation']['Moons'.substring(0, MAX_KEY_LENGTH)], '9.9866');
        expect(view['segmentation']['segment'], Platform.isIOS ? 'iOS' : 'Android');
        expect(view['segmentation']['start'], Platform.isIOS ? 1 : '1');
        expect(view['segmentation']['name'], 'HomePage'.substring(0, MAX_KEY_LENGTH));
        expect(view['segmentation']['Camel'.substring(0, MAX_KEY_LENGTH)], '12345'); // merges with cat
        expect(view['segmentation']['visit'], Platform.isIOS ? 1 : '1');
        expect(view['segmentation']['NotCamel'.substring(0, MAX_KEY_LENGTH)], 'Deerz');
        expect(view['segmentation']['Moose'.substring(0, MAX_KEY_LENGTH)], 'Deer');
        // 2) View End (legacy)
        view = eventRaw[2];
        expect(view['key'], '[CLY]_view');
        expect(view['segmentation']['segment'], Platform.isIOS ? 'iOS' : 'Android');
        expect(view['segmentation']['name'], 'HomePage'.substring(0, MAX_KEY_LENGTH));
        expect(view['segmentation']['Camel'.substring(0, MAX_KEY_LENGTH)], 666);
        expect(view['segmentation']['NotCamel'.substring(0, MAX_KEY_LENGTH)], 'Deerz');
        // 3) View Start (AutoStopped)
        view = eventRaw[3];
        expect(view['key'], '[CLY]_view');
        expect(view['segmentation']['Cats'.substring(0, MAX_KEY_LENGTH)], 12345);
        // expect(view['segmentation']['Moons'.substring(0, MAX_KEY_LENGTH)], 9.9866); // merges with moose
        expect(view['segmentation']['segment'], Platform.isIOS ? 'iOS' : 'Android');
        expect(view['segmentation']['name'], 'hawk'.substring(0, MAX_KEY_LENGTH));
        expect(view['segmentation']['Camel'.substring(0, MAX_KEY_LENGTH)], 12345); // merges with cat
        expect(view['segmentation']['visit'], Platform.isIOS ? 1 : '1');
        expect(view['segmentation']['NotCamel'.substring(0, MAX_KEY_LENGTH)], 'Deerz');
        expect(view['segmentation']['Moose'.substring(0, MAX_KEY_LENGTH)], 'Deer');
      } else if (a == 6) {
        Map<String, dynamic> userDetails = json.decode(queryParams['user_details']![0]);
        expect(userDetails['custom']['special_value'.substring(0, MAX_KEY_LENGTH)], 'something special');
        expect(userDetails['custom']['not_special_value'.substring(0, MAX_KEY_LENGTH)], 'something special cooking');
        checkUnchangingUserPropeties(userDetails, null);

        if (Platform.isAndroid) {
          checkUnchangingUserData(userDetails, MAX_KEY_LENGTH, null);
        }
      } else if (Platform.isIOS && a == 7) {
        Map<String, dynamic> userDetails = json.decode(queryParams['user_details']![0]);
        checkUnchangingUserData(userDetails, MAX_KEY_LENGTH, null);
      }

      // some logs for debugging
      print('RQ.$a: $queryParams');
      print('========================');
      a++;
    }
  });
}
