import 'dart:convert';
import 'dart:io';
import 'package:countly_flutter_np/countly_flutter.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import '../utils.dart';

/// A simple user property save test
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('Very simple test', (WidgetTester tester) async {
    // Initialize the SDK
    CountlyConfig config = CountlyConfig(SERVER_URL, APP_KEY).setLoggingEnabled(true).setRequiresConsent(true).giveAllConsents();
    await Countly.initWithConfig(config);

    await Countly.recordEvent({'key': 'event1'});
    await Countly.recordEvent({'key': 'event2'});
    // string list
    List<String> list = ['value1', 'value2', 'value3'];
    // int list
    List<int> intList = [1, 2, 3];
    // double list
    List<double> doubleList = [1.1, 2.2, 3.3];
    // bool list
    List<bool> boolList = [true, false, true];
    // mixed list
    List<dynamic> mixedList = ['value1', 2, 3.3, true];
    // map list
    List<Map<String, dynamic>> mapList = [
      {'key1': 'value1', 'key2': 2},
      {'key1': 'value2', 'key2': 3},
      {'key1': 'value3', 'key2': 4}
    ];
    // nested list
    List<List<String>> nestedList = [
      ['value1', 'value2'],
      ['value3', 'value4'],
      ['value5', 'value6']
    ];
    var segment = {
      'stringList': list,
      'intList': intList,
      'doubleList': doubleList,
      'boolList': boolList,
      'mixedList': mixedList,
      'mapList': mapList,
      'nestedList': nestedList,
      'normalString': 'normalString',
      'normalInt': 1,
      'normalDouble': 1.1,
      'normalBool': true,
    };
    await Countly.recordEvent({
      'key': 'event3',
      'segmentation': segment,
    });

    Countly.instance.userProfile.setProperty('key1', 'on');
    Countly.instance.userProfile.setProperty('key1', 'off');
    Countly.instance.userProfile.setProperty('key1', 'on');

    // Get request and event queues from native side
    List<String> requestList = await getRequestQueue(); // List of strings
    List<String> eventList = await getEventQueue(); // List of json objects

    // Some logs for debugging
    print('RQ: $requestList');
    print('EQ: $eventList');
    print('RQ length: ${requestList.length}');
    print('EQ length: ${eventList.length}');

    expect(requestList.length, 2);
    expect(eventList.length, 3);

    // Create some events
    await Countly.instance.views.startAutoStoppedView('test', segment);
    await Countly.instance.views.startAutoStoppedView('test2');
    await Countly.recordEvent({'key': 'event4'});

    // Get request and event queues from native side
    requestList = await getRequestQueue(); // List of strings
    eventList = await getEventQueue(); // List of json objects

    // Some logs for debugging
    print('RQ: $requestList');
    print('EQ: $eventList');
    print('RQ length: ${requestList.length}');
    print('EQ length: ${eventList.length}');

    await Countly.instance.userProfile.setProperty('key2', 'on');
    await Countly.instance.userProfile.setProperty('key2', 'off');
    await Countly.instance.userProfile.setProperty('key2', 'on');

    expect(requestList.length, 4);
    expect(eventList.length, 4);

    // Currently
    // - consent information, true (first in android, second in ios )
    // - begin session (first in ios, second in android)
    // - events
    // - user details
    var i = 0;
    for (var element in requestList) {
      Map<String, List<String>> queryParams = Uri.parse("?" + element).queryParametersAll;
      testCommonRequestParams(queryParams); // tests
      if ((Platform.isAndroid && i == 0) || (Platform.isIOS && i == 1)) {
        // example:
        // consent: [{"sessions":true,"crashes":true,"users":true,"push":true,"feedback":true,"scrolls":true,"remote-config":true,"attribution":true,"clicks":true,"location":true,"star-rating":true,"events":true,"views":true,"apm":true}]
        Map<String, dynamic> consentInRequest = jsonDecode(queryParams['consent']![0]);
        for (var key in ['push', 'feedback', 'crashes', 'attribution', 'users', 'events', 'remote-config', 'sessions', 'location', 'views', 'apm']) {
          expect(consentInRequest[key], true);
        }
        expect(consentInRequest.length, Platform.isAndroid ? 14 : 11);
      } else if ((Platform.isAndroid && i == 1) || (Platform.isIOS && i == 0)) {
        expect(queryParams['begin_session']?[0], '1');
      } else if (i == 2) {
        expect(queryParams['events']?[0].contains('event1'), true);
        expect(queryParams['events']?[0].contains('event2'), true);
        expect(queryParams['events']?[0].contains('event3'), true);
        if (Platform.isAndroid) {
          var seg = '"normalInt":1,"stringList":["value1","value2","value3"],"intList":[1,2,3],"doubleList":[1.1,2.2,3.3],"normalString":"normalString","normalDouble":1.1,"boolList":[true,false,true],"normalBool":true';
          expect(queryParams['events']?[0].contains('seg'), true);
        } else {
          expect(queryParams['events']?[0].contains('normalInt'), true);
          expect(queryParams['events']?[0].contains('stringList'), true);
          expect(queryParams['events']?[0].contains('intList'), true);
          expect(queryParams['events']?[0].contains('doubleList'), true);
          expect(queryParams['events']?[0].contains('normalString'), true);
          expect(queryParams['events']?[0].contains('normalDouble'), true);
          expect(queryParams['events']?[0].contains('boolList'), true);
          expect(queryParams['events']?[0].contains('normalBool'), true);
        }
      } else if (i == 3) {
        expect(queryParams['user_details']?[0], '{"custom":{"key1":"on"}}');
      }

      print('RQ.$i: $queryParams');
      print('========================');
      i++;
    }
  });
}
