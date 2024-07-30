import 'dart:convert';
import 'dart:io';
import 'package:countly_flutter/countly_flutter.dart';
import 'package:flutter/services.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:flutter_test/flutter_test.dart';

const MethodChannel _channelTest = MethodChannel('countly_flutter');

// Base config options for tests
final String SERVER_URL = 'https://xxx.count.ly';
final String SERVER_URL_RC = 'https://xxx.count.ly';
final String APP_KEY = 'SHOULD_BE_YOUR_APP_KEY';
final String APP_KEY_RC = 'SHOULD_BE_YOUR_APP_KEY';

/// Get request queue from native side (list of strings)
Future<List<String>> getRequestQueue() async {
  final List<dynamic> rq = await _channelTest.invokeMethod('getRequestQueue');
  return rq.cast<String>();
}

/// Get event queue from native side (list of json objects)
Future<List<String>> getEventQueue() async {
  final List<dynamic> eq = await _channelTest.invokeMethod('getEventQueue');
  return eq.cast<String>();
}

/// Verify the common request queue parameters
void testCommonRequestParams(Map<String, List<String>> requestObject) {
  expect(requestObject['app_key']?[0], APP_KEY);
  expect(requestObject['sdk_name']?[0], "dart-flutterb-${Platform.isIOS ? "ios" : "android"}");
  expect(requestObject['sdk_version']?[0], '24.7.0');
  expect(requestObject['av']?[0], Platform.isIOS ? '0.0.1' : '1.0.0');
  assert(requestObject['timestamp']?[0] != null);

  expect(requestObject['hour']?[0], DateTime.now().hour.toString());
  expect(requestObject['dow']?[0], DateTime.now().weekday.toString());
  expect(requestObject['tz']?[0], DateTime.now().timeZoneOffset.inMinutes.toString());
}

/// Verify custom request queue parameters
/// This method checks if the provided parameter key matches the parameter value in the request queue
Future<void> testLastRequestParams(Map<String, dynamic> params) async {
  print('params: $params');

  // Get request and event queues from native side
  final requestList = await getRequestQueue(); // List of strings

  // Some logs for debugging
  print('RQ: $requestList');
  print('RQ length: ${requestList.length}');

  // Verify the request queue for a single request
  if (requestList.length > 0) {
    final queryParams = Uri.parse('?' + requestList.last).queryParametersAll;
    print('queryParams: $queryParams');
    testCommonRequestParams(queryParams);
    for (final param in params.keys) {
      expect(queryParams[param]?[0], params[param]);
    }
  } else {
    if (params.isNotEmpty) {
      // test failed.
      expect(requestList.length, 'Test failed because request queue should not be empty');
    }
  }
}

/// Verify custom request queue parameters
/// This method checks if the provided parameter key matches the parameter value in the request queue
Future<String> testDeviceID(dynamic deviceIDMatcher) async {
  // Get the device ID
  String? id = await Countly.getCurrentDeviceId();
  String? newModuleId = await Countly.instance.deviceId.getID();
  // Verify the device ID
  expect(id, deviceIDMatcher);
  expect(newModuleId, deviceIDMatcher);
  expect(id, newModuleId);
  return id!;
}

/// Verify custom request queue parameters
/// This method checks if the provided parameter key matches the parameter value in the request queue
Future<DeviceIdType> testDeviceIDType(DeviceIdType givenType) async {
  // Get the device ID type
  DeviceIdType? type = await Countly.getDeviceIDType();
  DeviceIdType? newModuleType = await Countly.instance.deviceId.getIDType();
  // Verify the device ID type
  expect(type, givenType);
  expect(newModuleType, givenType);
  if (givenType == DeviceIdType.SDK_GENERATED) {
    String? id = await Countly.getCurrentDeviceId();
    String? newModuleId = await Countly.instance.deviceId.getID();
    expect(id!.length, Platform.isIOS ? 36 : 16);
    expect(newModuleId!.length, Platform.isIOS ? 36 : 16);
    expect(id, newModuleId);
  }
  return type!;
}

/// Start a server to receive the requests from the SDK and store them in a provided List
/// Use http://0.0.0.0:8080 as the server url
void creatServer(List requestArray) async {
  // Start a server to receive the requests from the SDK
  var server = await HttpServer.bind(InternetAddress.anyIPv4, 8080);
  server.listen((HttpRequest request) {
    print(request.uri.queryParametersAll.toString());

    // Store the request parameters for later verification
    requestArray.add(request.uri.queryParametersAll);

    // Send a response
    request.response.statusCode = HttpStatus.ok;
    request.response.headers.contentType = ContentType.json;
    request.response.headers.set('Access-Control-Allow-Origin', '*');
    request.response.write(jsonEncode({'result': 'Success'}));
    request.response.close();
  });
}

/// halts the sdk
/// to use this add the following code snippert to your test after ensureInitialized()
//   setUpAll(() async {
//     await halt();
//   });
// Currently it seems like the app is destroyed after each test, so this is not needed
Future<void> halt() async {
  await _channelTest.invokeMethod('halt');
}

/// Get and print elements with wanted param from event queue
/// [String param] - wanted param
Future<List<String>> getAndPrintWantedElementsWithParamFromEventQueue(String param) async {
  List<String> wantedElements = [];
  List<String> eventQueue = await getEventQueue();
  eventQueue.forEach((element) {
    if (element.contains(param)) {
      wantedElements.add(element);
      print('event:[' + element + ']');
    }
  });
  return wantedElements;
}

/// Get and print elements with wanted param from request queue
/// [String param] - wanted param
Future<List<String>> getAndPrintWantedElementsWithParamFromRequestQueue(String param) async {
  List<String> wantedElements = [];
  List<String> requestQueue = await getRequestQueue();
  requestQueue.forEach((element) {
    if (element.contains(param)) {
      wantedElements.add(element);
      print('request:[' + element + ']');
    }
  });
  return wantedElements;
}

/// Get and print elements with wanted param from all queues
/// [String param] - wanted param
Future<List<String>> getAndPrintWantedElementsWithParamFromAllQueues(String param) async {
  List<String> requestQueue = await getAndPrintWantedElementsWithParamFromRequestQueue(param);
  List<String> eventQueue = await getAndPrintWantedElementsWithParamFromEventQueue(param);
  return requestQueue + eventQueue;
}

/// Get apm params from request
/// [String request] - request
Future<Map<String, dynamic>> getApmParamsFromRequest(String request) async {
  Map<String, List<String>> queryParams = Uri.parse("?" + request).queryParametersAll;
  Map<String, dynamic> apmParams = json.decode(queryParams['apm']![0]);
  return apmParams;
}

/// Go to background and foreground
void goBackgroundAndForeground() {
  FlutterForegroundTask.minimizeApp();
  if (Platform.isIOS) {
    printMessageMultipleTimes('will now go to background, get ready to go foreground manually', 3);
  }
  sleep(Duration(seconds: 2));
  FlutterForegroundTask.launchApp();
  if (Platform.isIOS) {
    printMessageMultipleTimes('waiting for 3 seconds, now go to foreground', 3);
  }
  sleep(Duration(seconds: 3));
}

/// Print message x times
/// [String message] - message
/// [int times] - times
void printMessageMultipleTimes(String message, int times) {
  for (int i = 0; i < times; i++) {
    print(message);
  }
}

/// Creates truncable events (which covers all possible truncable situations)
/// - Events with segmentation
/// - Views with segmentation
/// - Custom and Network APM traces with segmentation
/// - Custom Crash logs with segmentation
/// - Global View segmentation
/// - Custom and Named User Properties and their modifications (with mul, push, pull, set, increment, etc)
/// - Breadcrumb value
/// - Manual Feedback and Rating Widgets reporting
Future<void> createTruncableEvents() async {
  // Set global view segmentation
  Map<String, Object> viewSegmentation = {'Camel': 666, 'NotCamel': 'Deerz'};
  await Countly.instance.views.setGlobalViewSegmentation(viewSegmentation);

  // Create event with segmentation
  var event = {'key': 'Event With Sum And Segment', 'count': 1, 'sum': '0.99'};
  event['segmentation'] = {'Country': 'Turkey', 'Age': '28884'};
  await Countly.recordEvent(event);

  // Create a view with segmentation
  Map<String, Object> segments = {'Cats': 12345, 'Moons': 9.9866, 'Moose': 'Deer'};
  await Countly.recordView('HomePage', segments); // legacy code
  await Countly.instance.views.startAutoStoppedView('hawk', segments);

  // Create custom APM custom trace with segmentation
  Map<String, int> customMetric = {'ABCDEF': 1233, 'C44CCC': 1337};
  await Countly.startTrace('Trace');
  await Countly.endTrace('Trace', customMetric);

  // Create APM network trace
  await Countly.recordNetworkTrace('Network Trace', 200, 500, 600, 100, 150);

  // Log a crash with segmentation (fatal and non-fatal)
  await Countly.addCrashLog('User Performed Step A'); // breadcrumb
  await Countly.logException('This is a manually created exception', true, segments);
  await Countly.addCrashLog('User Performed Step A'); // breadcrumb
  await Countly.logException('But this is a manually created exception', false, segments);

  // Set user properties
  Map<String, Object> userProperties = {
    'name': 'Nicola Tesla',
    'username': 'nicola',
    'email': 'info@nicola.tesla',
    'organization': 'Trust Electric Ltd',
    'phone': '+90 822 140 2546',
    'picture': 'http://images2.fanpop.com/images/photos/3300000/Nikola-Tesla-nikola-tesla-3365940-600-738.jpg',
    'picturePath': '',
    'gender': 'M',
    'byear': 1919,
    'special_value': 'something special',
    'not_special_value': 'something special cooking'
  };
  await Countly.instance.userProfile.setUserProperties(userProperties);
  await Countly.instance.userProfile.setProperty('a12345', 'My Property');
  await Countly.instance.userProfile.increment('b12345');
  await Countly.instance.userProfile.incrementBy('c12345', 10);
  await Countly.instance.userProfile.multiply('d12345', 20);
  await Countly.instance.userProfile.saveMax('e12345', 100);
  await Countly.instance.userProfile.saveMin('f12345', 50);
  await Countly.instance.userProfile.setOnce('g12345', '200');
  await Countly.instance.userProfile.pushUnique('h12345', 'morning');
  await Countly.instance.userProfile.push('i12345', 'morning');
  await Countly.instance.userProfile.pull('k12345', 'morning');

  // TODO: Report feedback widgets manually (will need some extra work)
//   Map<String, Object> surSeg = {};
//   surSeg['answ-12'] = 'answ-12';
//   surSeg['answ-13'] = 'answ-13';
//   await Countly.reportFeedbackWidgetManually(new CountlyPresentableFeedback('1', 'survey', 'fake_survey'), {}, surSeg);
//   Map<String, Object> npsSeg = {'rating': 2, 'comment': 'Filled out comment'};
//   await Countly.reportFeedbackWidgetManually(new CountlyPresentableFeedback('1', 'nps', 'fake_nps'), {}, npsSeg);
//   Map<String, Object> ratSeg = {'rating': 3, 'comment': 'Filled out comment', 'email': 'test@yahoo.com'};
//   await Countly.reportFeedbackWidgetManually(new CountlyPresentableFeedback('1', 'rating', 'fake_rating'), {}, ratSeg);

  await Countly.instance.userProfile.save();
}

/// Check if the user properties are as expected for internal limit tests
/// [Map<String, dynamic>] [userDetails] - user details object parsed from the request
void checkUnchangingUserPropeties(userDetails, MAX_VALUE_SIZE) {
  expect(userDetails['name'], truncate('Nicola Tesla', MAX_VALUE_SIZE));
  expect(userDetails['username'], truncate('nicola', MAX_VALUE_SIZE));
  expect(userDetails['email'], truncate('info@nicola.tesla', MAX_VALUE_SIZE));
  expect(userDetails['organization'], truncate('Trust Electric Ltd', MAX_VALUE_SIZE));
  expect(userDetails['phone'], truncate('+90 822 140 2546', MAX_VALUE_SIZE));
  expect(userDetails['picture'], 'http:\/\/images2.fanpop.com\/images\/photos\/3300000\/Nikola-Tesla-nikola-tesla-3365940-600-738.jpg');
  expect(userDetails['gender'], truncate('M', MAX_VALUE_SIZE));
  expect(userDetails['byear'], 1919);
}

/// Check if the user data are as expected for internal limit tests
/// [Map<String, dynamic>] [userDetails] - user details object parsed from the request
void checkUnchangingUserData(userDetails, MAX_KEY_LENGTH, MAX_VALUE_SIZE) {
  expect(userDetails['custom'][truncate('a12345', MAX_KEY_LENGTH)], truncate('My Property', MAX_VALUE_SIZE));
  expect(userDetails['custom'][truncate('b12345', MAX_KEY_LENGTH)], {'\$inc': 1});
  expect(userDetails['custom'][truncate('c12345', MAX_KEY_LENGTH)], {'\$inc': 10});
  expect(userDetails['custom'][truncate('d12345', MAX_KEY_LENGTH)], {'\$mul': 20});
  expect(userDetails['custom'][truncate('e12345', MAX_KEY_LENGTH)], {'\$max': 100});
  expect(userDetails['custom'][truncate('f12345', MAX_KEY_LENGTH)], {'\$min': 50});
  expect(userDetails['custom'][truncate('g12345', MAX_KEY_LENGTH)], {'\$setOnce': truncate('200', MAX_VALUE_SIZE)});
  expect(userDetails['custom'][truncate('h12345', MAX_KEY_LENGTH)], {'\$addToSet': truncate('morning', MAX_VALUE_SIZE)});
  expect(userDetails['custom'][truncate('i12345', MAX_KEY_LENGTH)], {'\$push': truncate('morning', MAX_VALUE_SIZE)});
  expect(userDetails['custom'][truncate('k12345', MAX_KEY_LENGTH)], {'\$pull': truncate('morning', MAX_VALUE_SIZE)});
}

/// Truncate a string to a given limit
String truncate(string, limit) {
  var length = string.length;
  limit = limit != null ? limit : length;
  return string.substring(0, limit);
}

var rcCounter = 0;
var rcCounterInternal = 0;

void rcCallback(rResult, error, fullValueUpdate, downloadedValues) {
  print('RC callback: $rResult, $error, $fullValueUpdate, $downloadedValues, $rcCounter');
  if (rResult == RequestResult.success) {
    rcCounter++;
    print('RC download success');
  }
}

Future<void> getAndValidateAllRecordedRCValues({bool isEmpty = false, bool? isCurrentUsersData = true}) async {
  var storedRCVals = await Countly.instance.remoteConfig.getAllValues();
  expect(storedRCVals, isA<Map<String, RCData>>());
  if (isEmpty) {
    expect(storedRCVals.isEmpty, true);
    expect(rcCounter, rcCounterInternal);
    return;
  }
  expect(storedRCVals.isNotEmpty, true);
  expect(storedRCVals.length, 5);

  expect(storedRCVals['rc_1']?.value, 'val_1');
  expect(storedRCVals['rc_1']?.isCurrentUsersData, isCurrentUsersData);

  expect(storedRCVals['rc_2']?.value, 'val_2');
  expect(storedRCVals['rc_2']?.isCurrentUsersData, isCurrentUsersData);

  expect(storedRCVals['rc_3']?.value, 'val_3');
  expect(storedRCVals['rc_3']?.isCurrentUsersData, isCurrentUsersData);

  expect(storedRCVals['rc_4']?.value, 'val_4');
  expect(storedRCVals['rc_4']?.isCurrentUsersData, isCurrentUsersData);

  expect(storedRCVals['key']?.isCurrentUsersData, isCurrentUsersData);

  expect(rcCounter, rcCounterInternal);
}

Future<void> testConsentForRC({bool isAT = false, bool isCG = true, bool isCNR = false}) async {
  var storedRCVals = await Countly.instance.remoteConfig.getAllValues();
  if (storedRCVals.isNotEmpty) {
    await Countly.instance.remoteConfig.clearAll();
    await getAndValidateAllRecordedRCValues(isEmpty: true);
  }

  await Countly.removeConsent([CountlyConsent.remoteConfig]);
  await getAndValidateAllRecordedRCValues(isEmpty: true);

  if (isCNR) {
    await Countly.giveAllConsent();
    await Countly.giveAllConsent();
    await Countly.removeConsent([CountlyConsent.apm, CountlyConsent.crashes, CountlyConsent.events, CountlyConsent.location, CountlyConsent.sessions, CountlyConsent.views]);
    await Countly.removeConsent([CountlyConsent.remoteConfig]);
    await Countly.removeAllConsent();
    await Countly.giveConsent([CountlyConsent.apm, CountlyConsent.crashes, CountlyConsent.events, CountlyConsent.location, CountlyConsent.sessions, CountlyConsent.views]);
    await Countly.giveAllConsent();
    await Countly.giveAllConsent();
    await Future.delayed(Duration(seconds: 3));
    await getAndValidateAllRecordedRCValues(isEmpty: true);
    return;
  }

  // give all consent
  await Countly.giveAllConsent();
  await Future.delayed(Duration(seconds: 3));
  if (isAT) {
    rcCounterInternal++;
  }
  await getAndValidateAllRecordedRCValues(isEmpty: !isAT);

  // give all consent
  await Countly.giveAllConsent();
  await Future.delayed(Duration(seconds: 3));
  await getAndValidateAllRecordedRCValues(isEmpty: !isAT);

  // update for all rc values
  await Countly.instance.remoteConfig.downloadAllKeys();
  await Future.delayed(Duration(seconds: 3));
  rcCounterInternal++;
  await getAndValidateAllRecordedRCValues();

  await Countly.removeConsent([CountlyConsent.apm, CountlyConsent.crashes, CountlyConsent.events, CountlyConsent.location, CountlyConsent.sessions, CountlyConsent.views]);
  await Countly.removeConsent([CountlyConsent.remoteConfig]);
  await Countly.removeAllConsent();
  await Countly.giveConsent([CountlyConsent.apm, CountlyConsent.crashes, CountlyConsent.events, CountlyConsent.location, CountlyConsent.sessions, CountlyConsent.views]);
  await getAndValidateAllRecordedRCValues();

  if (isCG) {
    // give all consent
    await Countly.giveAllConsent();
    await Future.delayed(Duration(seconds: 3));
    if (isAT) {
      rcCounterInternal++;
    }
    await getAndValidateAllRecordedRCValues();
  }
}

// For session tests:
void checkBeginSession(Map<String, List<String>> queryParams, {String deviceID = ''}) {
  expect(queryParams['begin_session']?[0], '1');
  if (deviceID.isNotEmpty) {
    expect(queryParams['device_id']?[0], deviceID);
  }
}

void checkMerge(Map<String, List<String>> queryParams, {String deviceID = '', String oldDeviceID = ''}) {
  expect(queryParams['old_device_id']?[0].isNotEmpty, true);
  if (deviceID.isNotEmpty) {
    expect(queryParams['device_id']?[0], deviceID);
  }
  if (oldDeviceID.isNotEmpty) {
    expect(queryParams['old_device_id']?[0], oldDeviceID);
  }
}

void checkEndSession(Map<String, List<String>> queryParams, {String deviceID = ''}) {
  expect(queryParams['end_session']?[0].isNotEmpty, true);
//   expect(queryParams['session_duration']?[0].isNotEmpty, true); TODO: check this
  if (deviceID.isNotEmpty) {
    expect(queryParams['device_id']?[0], deviceID);
  }
}

void printQueues(List<String> requestList, List<String> eventList) {
  print('RQ: $requestList');
  print('RQ length: ${requestList.length}');
  print('EQ: $eventList');
  print('EQ length: ${eventList.length}');
}
