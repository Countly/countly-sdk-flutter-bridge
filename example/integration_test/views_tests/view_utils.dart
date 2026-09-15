import 'package:flutter_test/flutter_test.dart';
import 'dart:io';
import 'dart:convert';
import '../utils.dart';

void validateView(String name, bool start, bool visit, {String? viewStr, Map<String, dynamic>? viewGiven}) {
  Map<String, dynamic> segmentation = <String, dynamic>{'name': name, 'segment': Platform.isAndroid ? 'Android' : 'iOS'};

  if (visit) {
    segmentation['visit'] = Platform.isAndroid ? '1' : 1;
  }
  if (start) {
    segmentation['start'] = Platform.isAndroid ? '1' : 1;
  }
  validateEvent("[CLY]_view", segmentation, eventGiven: viewGiven, eventStr: viewStr);
}

void validateEvent(String key, Map<String, dynamic> segmentation, {String? eventStr, Map<String, dynamic>? eventGiven}) {
  Map<String, dynamic> event = eventStr != null ? jsonDecode(eventStr) : eventGiven!;
  print("================");
  print(event);
  expect(event['key'], key);
  expect(segmentation.length, event['segmentation'].length);
  for (var key in segmentation.keys) {
    expect(event['segmentation'][key], segmentation[key]);
  }
}

void validateBeginSessionRequest(String request) {
  Map<String, List<String>> queryParams = Uri.parse('?$request').queryParametersAll;
  testCommonRequestParams(queryParams);

  expect(queryParams['begin_session'], ['1']);
  expect(queryParams['metrics'], isNotNull);
}

void validateEndSessionRequest(String request) {
  Map<String, List<String>> queryParams = Uri.parse('?$request').queryParametersAll;
  testCommonRequestParams(queryParams);

  expect(queryParams['end_session'], ['1']);
  expect(queryParams['metrics'], isNull);
}
