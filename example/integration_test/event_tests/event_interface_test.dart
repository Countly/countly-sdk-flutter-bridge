import 'package:countly_flutter/countly_flutter.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import '../utils.dart';
import 'event_utils.dart';
import 'dart:convert';
import 'dart:io';

void main() {
  const int MAX_INT = -1 >>> 1;

  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('Init SDK record some events and check what is in the queues with new interface', (WidgetTester tester) async {
    // Initialize the SDK
    CountlyConfig config = CountlyConfig(SERVER_URL, APP_KEY).setLoggingEnabled(true);
    await Countly.initWithConfig(config);

    Map<String, Object> segmentation = {
      'nar': 'uto',
      'sasuke': MAX_INT,
      'sakura': false,
      'itachi': double.maxFinite,
      'kakaski': double.minPositive,
      'hashirama': -MAX_INT,
      'tobi': {'obito': 'uchiha', 'zetsu': 'white'},
      'stringList': ['value1', 'value2', 'value3'],
      'intList': [1, 2, 3],
      'doubleList': [1.1, 2.2, 3.3],
      'boolList': [true, false, true],
      'mixedList': ['value1', 2, 3.3, true],
      'mapList': [
        {'key1': 'value1', 'key2': 2},
        {'key1': 'value2', 'key2': 3},
        {'key1': 'value3', 'key2': 4}
      ],
    };
    await Countly.instance.events.recordEvent('event');
    await Countly.instance.events.recordEvent('event_s', segmentation);
    await Countly.instance.events.recordEvent('event_s_c_s', segmentation, 23, 90.1);
    await Countly.instance.events.recordEvent('event_s_c_s_d', segmentation, 98, 13.2, 123);

    await Countly.instance.events.startEvent('timed_event');
    await Future.delayed(const Duration(milliseconds: 250));
    await Countly.instance.events.endEvent('timed_event', segmentation);

    await Countly.instance.events.startEvent('timed_event_s_c_s');
    await Future.delayed(const Duration(milliseconds: 250));
    await Countly.instance.events.endEvent('timed_event_s_c_s', segmentation, 45, 65.6);

    // Get request and event queues from native side
    List<String> requestList = await getRequestQueue(); // List of strings
    List<String> eventList = await getEventQueue(); // List of json objects

    // Some logs for debugging
    print('RQ: $requestList');
    print('EQ: $eventList');
    print('RQ length: ${requestList.length}');
    print('EQ length: ${eventList.length}');

    expect(requestList.length, 1);
    expect(eventList.length, Platform.isAndroid ? 7 : 6);

    // begin session
    Map<String, List<String>> queryParams = Uri.parse("?" + requestList[0]).queryParametersAll;
    testCommonRequestParams(queryParams);

    int n = 0;
    Map<String, dynamic> currentEvent;
    if (Platform.isAndroid) {
      currentEvent = json.decode(eventList[n]);
      // 1. orientation event
      expect("[CLY]_orientation", currentEvent['key']);
      expect(1, currentEvent['count']);
      n++;
    }

    Map<String, Object> expectedSegmentation = {
      "sasuke": MAX_INT,
      "sakura": false,
      "mapList": [],
      "intList": [1, 2, 3],
      "doubleList": [1.1, 2.2, 3.3],
      "boolList": [true, false, true],
      "mixedList": ["value1", 2, 3.3, true],
      "itachi": double.maxFinite,
      "stringList": ["value1", "value2", "value3"],
      "kakaski": double.minPositive,
      "nar": "uto",
      "hashirama": -MAX_INT,
    };

    // 2. event
    currentEvent = json.decode(eventList[n++]);
    validateEvent(event: currentEvent, key: 'event');

    // 3. event_s
    currentEvent = json.decode(eventList[n++]);
    validateEvent(event: currentEvent, key: 'event_s', segmentation: expectedSegmentation);

    // 4. event_s_c_s
    currentEvent = json.decode(eventList[n++]);
    validateEvent(event: currentEvent, key: 'event_s_c_s', segmentation: expectedSegmentation, count: 23, sum: 90.1);

    // 5. event_s_c_s_d
    currentEvent = json.decode(eventList[n++]);
    validateEvent(event: currentEvent, key: 'event_s_c_s_d', segmentation: expectedSegmentation, count: 98, sum: 13.2, dur: 123);

    // 6. timed_event
    currentEvent = json.decode(eventList[n++]);
    validateEvent(event: currentEvent, key: 'timed_event', segmentation: expectedSegmentation, isTimed: true);

    // 7. timed_event_s_c_s
    currentEvent = json.decode(eventList[n++]);
    validateEvent(event: currentEvent, key: 'timed_event_s_c_s', segmentation: expectedSegmentation, count: 45, sum: 65.6, isTimed: true);
  });
}
