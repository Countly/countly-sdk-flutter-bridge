import 'package:countly_flutter/countly_flutter.dart';
import 'package:flutter_test/flutter_test.dart';
import 'dart:io';

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

var expectedSegmentation = {
  'stringList': list,
  'intList': intList,
  'doubleList': doubleList,
  'boolList': boolList,
  'mixedList': mixedList,
  'normalString': 'normalString',
  'normalInt': 1,
  'normalDouble': 1.1,
  'normalBool': true,
};

var event = {'key': 'event'};
var event_c = {'key': 'event_c', 'count': 1};
var event_c_s = {'key': 'event_c_s', 'count': 1, 'sum': 3};
var event_c_d = {'key': 'event_c_d', 'count': 1, 'duration': 3};
var event_c_se = {'key': 'event_c_se', 'count': 1, 'segmentation': segment};
var event_c_s_d = {'key': 'event_c_s_d', 'count': 1, 'sum': 3, 'duration': 3};
var event_c_s_se = {'key': 'event_c_s_se', 'count': 1, 'sum': 3, 'segmentation': segment};
var event_c_d_se = {'key': 'event_c_d_se', 'count': 1, 'duration': 3, 'segmentation': segment};
var event_c_s_d_se = {'key': 'event_c_s_d_se', 'count': 1, 'sum': 3, 'duration': 3, 'segmentation': segment};
var event_s = {'key': 'event_s', 'sum': 3};
var event_s_d = {'key': 'event_s_d', 'sum': 3, 'duration': 3};
var event_s_se = {'key': 'event_s_se', 'sum': 3, 'segmentation': segment};
var event_s_d_se = {'key': 'event_s_d_se', 'sum': 3, 'duration': 3, 'segmentation': segment};
var event_d = {'key': 'event_d', 'duration': 3};
var event_d_se = {'key': 'event_d_se', 'duration': 3, 'segmentation': segment};
var event_se = {'key': 'event_se', 'segmentation': segment};
var timed_event = {'key': 'timed_event'};
var timed_event_c = {'key': 'timed_event_c', 'count': 1};
var timed_event_c_s = {'key': 'timed_event_c_s', 'count': 1, 'sum': 3};
var timed_event_c_d = {'key': 'timed_event_c_d', 'count': 1, 'duration': 3};
var timed_event_c_se = {'key': 'timed_event_c_se', 'count': 1, 'segmentation': segment};
var timed_event_c_s_d = {'key': 'timed_event_c_s_d', 'count': 1, 'sum': 3, 'duration': 3};
var timed_event_c_s_se = {'key': 'timed_event_c_s_se', 'count': 1, 'sum': 3, 'segmentation': segment};
var timed_event_c_d_se = {'key': 'timed_event_c_d_se', 'count': 1, 'duration': 3, 'segmentation': segment};
var timed_event_c_s_d_se = {'key': 'timed_event_c_s_d_se', 'count': 1, 'sum': 3, 'duration': 3, 'segmentation': segment};
var timed_event_s = {'key': 'timed_event_s', 'sum': 3};
var timed_event_s_d = {'key': 'timed_event_s_d', 'sum': 3, 'duration': 3};
var timed_event_s_se = {'key': 'timed_event_s_se', 'sum': 3, 'segmentation': segment};
var timed_event_s_d_se = {'key': 'timed_event_s_d_se', 'sum': 3, 'duration': 3, 'segmentation': segment};
var timed_event_d = {'key': 'timed_event_d', 'duration': 3};
var timed_event_d_se = {'key': 'timed_event_d_se', 'duration': 3, 'segmentation': segment};
var timed_event_se = {'key': 'timed_event_se', 'segmentation': segment};

Future<void> recordTimedEvent(eventObj) async {
  await Countly.startEvent(eventObj['key']);
  await Future.delayed(const Duration(milliseconds: 250));
  await Countly.endEvent(eventObj);
  await Future.delayed(const Duration(milliseconds: 250));
}

Future<void> generateEvents() async {
  await Countly.recordEvent(event);
  await Countly.recordEvent(event_c);
  await Countly.recordEvent(event_c_s);
  await Countly.recordEvent(event_c_d);
  await Countly.recordEvent(event_c_se);
  await Countly.recordEvent(event_c_s_d);
  await Countly.recordEvent(event_c_s_se);
  await Countly.recordEvent(event_c_d_se);
  await Countly.recordEvent(event_c_s_d_se);
  await Countly.recordEvent(event_s);
  await Countly.recordEvent(event_s_d);
  await Countly.recordEvent(event_s_se);
  await Countly.recordEvent(event_s_d_se);
  await Countly.recordEvent(event_d);
  await Countly.recordEvent(event_d_se);
  await Countly.recordEvent(event_se);
  await recordTimedEvent(timed_event);
  await recordTimedEvent(timed_event_c);
  await recordTimedEvent(timed_event_c_s);
  await recordTimedEvent(timed_event_c_d);
  await recordTimedEvent(timed_event_c_se);
  await recordTimedEvent(timed_event_c_s_d);
  await recordTimedEvent(timed_event_c_s_se);
  await recordTimedEvent(timed_event_c_d_se);
  await recordTimedEvent(timed_event_c_s_d_se);
  await recordTimedEvent(timed_event_s);
  await recordTimedEvent(timed_event_s_d);
  await recordTimedEvent(timed_event_s_se);
  await recordTimedEvent(timed_event_s_d_se);
  await recordTimedEvent(timed_event_d);
  await recordTimedEvent(timed_event_d_se);
  await recordTimedEvent(timed_event_se);
}

String idCounter = "";
void validateEvent({dynamic event, String? key, int? count = 1, int? sum = 0, int? dur, dynamic segmentation, String? cvid = "", bool isTimed = false}) {
  expect(event['key'], key);
  expect(event['count'], count);
  expect(event['sum'], sum);
  expect(event['dur'], isTimed || Platform.isIOS ? isNotNull : dur);
  expect(event['segmentation'], segmentation);
  expect(event['timestamp'], isNotNull);
  expect(event['hour'], DateTime.now().hour);
  expect(event['dow'], DateTime.now().weekday);
  expect(event['cvid'], cvid);
  expect(event['id'], isNotNull);
  if (idCounter != "") {
    expect(event['peid'], idCounter);
  }
  idCounter = event['id'];
}
