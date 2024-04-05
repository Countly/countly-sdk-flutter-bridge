import 'dart:convert';
import 'dart:io';
import 'package:countly_flutter/countly_flutter.dart';
import 'package:flutter/services.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:flutter_test/flutter_test.dart';

const MethodChannel _channelTest = MethodChannel('countly_flutter');

// Base config options for tests
final String SERVER_URL = 'https://xxx.count.ly';
final String APP_KEY = 'FOR_IOS_THIS_SHOULD_NOT_BE_YOUR_APP_KEY';

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
  expect(requestObject['sdk_version']?[0], '24.4.0');
  expect(requestObject['av']?[0], Platform.isIOS ? '0.0.1' : '1.0.0');
  assert(requestObject['timestamp']?[0] != null);

  expect(requestObject['hour']?[0], DateTime.now().hour.toString());
  expect(requestObject['dow']?[0], DateTime.now().weekday.toString());
  expect(requestObject['tz']?[0], DateTime.now().timeZoneOffset.inMinutes.toString());
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
    'byear': '1919',
    'special_value': 'something special',
    'not_special_value': 'something special cooking'
  };
  await Countly.instance.userProfile.setUserProperties(userProperties);
  await Countly.instance.userProfile.setProperty('setProperty', 'My Property');
  await Countly.instance.userProfile.increment('increment');
  await Countly.instance.userProfile.incrementBy('incrementBy', 10);
  await Countly.instance.userProfile.multiply('multiply', 20);
  await Countly.instance.userProfile.saveMax('saveMax', 100);
  await Countly.instance.userProfile.saveMin('saveMin', 50);
  await Countly.instance.userProfile.setOnce('setOnce', '200');
  await Countly.instance.userProfile.pushUnique('pushUniqueValue', 'morning');
  await Countly.instance.userProfile.push('pushValue', 'morning');
  await Countly.instance.userProfile.pull('pushValue', 'morning');

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
void checkUnchangingUserPropeties(userDetails) {
  expect(userDetails['name'], 'Nicola Tesla');
  expect(userDetails['username'], 'nicola');
  expect(userDetails['email'], 'info@nicola.tesla');
  expect(userDetails['organization'], 'Trust Electric Ltd');
  expect(userDetails['phone'], '+90 822 140 2546');
  expect(userDetails['picture'], 'http:\/\/images2.fanpop.com\/images\/photos\/3300000\/Nikola-Tesla-nikola-tesla-3365940-600-738.jpg');
  expect(userDetails['gender'], 'M');
  expect(userDetails['byear'], 1919);
  expect(userDetails['custom']['increment'], {'\$inc': 1});
  expect(userDetails['custom']['multiply'], {'\$mul': 20});
  expect(userDetails['custom']['setOnce'], {'\$setOnce': '200'});
  expect(userDetails['custom']['saveMax'], {'\$max': 100});
  expect(userDetails['custom']['saveMin'], {'\$min': 50});
  expect(userDetails['custom']['pushUniqueValue'], {'\$addToSet': 'morning'});
  expect(userDetails['custom']['incrementBy'], {'\$inc': 10});
  expect(userDetails['custom']['pushValue'], {'\$push': 'morning', '\$pull': 'morning'});
}
