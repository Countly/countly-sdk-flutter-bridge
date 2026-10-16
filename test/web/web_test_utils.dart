import 'dart:async';
import 'dart:convert';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:countly_flutter/countly_flutter.dart';
import 'package:countly_flutter/src/web/countly_flutter_plugin.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// The channel the Dart API and the web plugin talk over.
const MethodChannel countlyChannel = MethodChannel('countly_flutter');

/// A server address nothing answers on, so every request stays in the Web SDK's queue where the
/// tests can read it.
const String deadServerUrl = 'http://127.0.0.1:9';

/// The web plugin the tests drive, created by [setUpWebPlugin].
late CountlyFlutterPlugin webPlugin;

/// Calls the web plugin makes back into the Dart API, as the platform would deliver them.
class _ToDartChannel extends MethodChannel {
  const _ToDartChannel() : super('countly_flutter');

  @override
  Future<T?> invokeMethod<T>(String method, [dynamic arguments]) async {
    final ByteData message = codec.encodeMethodCall(MethodCall(method, arguments));
    await TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.handlePlatformMessage(name, message, (ByteData? reply) {});
    return null;
  }
}

/// Makes the headless test browser look like a regular one, since the Web SDK ignores visits whose
/// user agent names a headless browser.
void _pretendToBeARegularBrowser() {
  final JSObject navigator = globalContext['navigator'] as JSObject;
  final String userAgent = (navigator['userAgent'] as JSString).toDart.replaceAll('HeadlessChrome', 'Chrome');
  final JSObject object = globalContext['Object'] as JSObject;

  final JSObject userAgentGetter = JSObject();
  userAgentGetter['get'] = (() => userAgent.toJS).toJS;
  object.callMethod('defineProperty'.toJS, navigator, 'userAgent'.toJS, userAgentGetter);

  final JSObject userAgentDataGetter = JSObject();
  userAgentDataGetter['get'] = (() => null).toJS;
  object.callMethod('defineProperty'.toJS, navigator, 'userAgentData'.toJS, userAgentDataGetter);
}

/// Routes the Dart API to a new web plugin instance, the way the plugin registrant does in an app,
/// and starts every test from an empty browser storage.
void setUpWebPlugin() {
  TestWidgetsFlutterBinding.ensureInitialized();
  _pretendToBeARegularBrowser();
  setUp(() {
    clearBrowserStorage();
    webPlugin = CountlyFlutterPlugin();
    webPlugin.methodChannel = const _ToDartChannel();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(countlyChannel, webPlugin.handleMethodCall);
  });
  tearDown(() async {
    await Countly.instance.halt();
    clearBrowserStorage();
  });
}

/// Removes everything the Web SDK stored in the browser. Newer Web SDK versions keep the queues of a
/// tab in its sessionStorage.
void clearBrowserStorage() {
  (globalContext['localStorage'] as JSObject).callMethod('clear'.toJS);
  (globalContext['sessionStorage'] as JSObject).callMethod('clear'.toJS);
}

/// The address of a Web SDK build to test instead of the version the plugin loads, given with
/// `--dart-define=COUNTLY_WEB_SDK_URL=<address>`, or empty.
const String webSdkUrlOverride = String.fromEnvironment('COUNTLY_WEB_SDK_URL');

/// A config for an app that sends its requests nowhere, so they stay queued.
CountlyConfig testConfig({String appKey = 'web_test_app'}) {
  final CountlyConfig config = CountlyConfig(deadServerUrl, appKey)..setLoggingEnabled(true);
  if (webSdkUrlOverride.isNotEmpty) {
    config.setWebSDKUrl(webSdkUrlOverride);
  }
  return config;
}

/// Every request the Web SDK holds for [appKey], decoded, oldest first: its queue, and before it the
/// requests that Web SDK versions keeping a queue per tab move into localStorage after a failed send.
Future<List<Map<String, dynamic>>> requestQueue({String appKey = 'web_test_app'}) async {
  final List<dynamic> queued = await countlyChannel.invokeMethod('getRequestQueue') as List<dynamic>;
  final List<Map<String, dynamic>> requests = queued.map((dynamic request) => jsonDecode(request as String) as Map<String, dynamic>).toList();
  final String key = '$appKey/cly_queue';
  final String? left = _storageItem('localStorage', key);
  if (_storageItem('sessionStorage', key) != null && left != null) {
    requests.insertAll(0, (jsonDecode(left) as List<dynamic>).cast<Map<String, dynamic>>());
  }
  return requests;
}

/// The value [key] has in the browser storage [storage], or null when it has none.
String? _storageItem(String storage, String key) {
  final JSAny? value = (globalContext[storage] as JSObject).callMethod('getItem'.toJS, key.toJS);
  if (value == null || !value.typeofEquals('string')) {
    return null;
  }
  return (value as JSString).toDart;
}

/// Every event still waiting in the Web SDK's event queue.
Future<List<Map<String, dynamic>>> eventQueue() async {
  final List<dynamic> events = await countlyChannel.invokeMethod('getEventQueue') as List<dynamic>;
  return events.map((dynamic event) => jsonDecode(event as String) as Map<String, dynamic>).toList();
}

/// Every event the queued requests carry, in order.
Future<List<Map<String, dynamic>>> queuedEvents() async {
  final List<Map<String, dynamic>> events = [];
  for (final Map<String, dynamic> request in await requestQueue()) {
    if (request['events'] is String) {
      events.addAll((jsonDecode(request['events'] as String) as List<dynamic>).cast<Map<String, dynamic>>());
    }
  }
  return events;
}

/// Waits until the Web SDK's heartbeat has moved recorded events into the request queue.
Future<void> waitForHeartbeat() {
  return Future<void>.delayed(const Duration(milliseconds: 1200));
}

/// The queued requests that carry the parameter [name].
Future<List<Map<String, dynamic>>> requestsWith(String name) async {
  return (await requestQueue()).where((Map<String, dynamic> request) => request.containsKey(name)).toList();
}

/// Every performance trace in the request queue, decoded.
Future<List<Map<String, dynamic>>> queuedTraces() async {
  return (await requestsWith('apm')).map((Map<String, dynamic> request) => jsonDecode(request['apm'] as String) as Map<String, dynamic>).toList();
}

/// The Web SDK instance the plugin created for [appKey], to read the settings it keeps.
JSObject webInstance({String appKey = 'web_test_app'}) {
  final JSObject instances = (globalContext['Countly'] as JSObject)['i'] as JSObject;
  return instances[appKey] as JSObject;
}

/// Every network request the Web SDK made outside its request queue, such as content, remote config
/// and server config fetches, as it records them for testing: each with its "url" and "params".
List<Map<String, dynamic>> generatedRequests() {
  final JSObject internals = webInstance()['_internals'] as JSObject;
  final JSArray requests = internals.callMethod('testingGetRequests'.toJS) as JSArray;
  return requests.toDart.map((JSAny? request) => Map<String, dynamic>.from((request as JSObject).dartify() as Map)).toList();
}

/// [original] wrapped so that [onCall] sees the arguments of every call before it runs.
JSObject _spy(JSFunction original, void Function(List<JSAny?> arguments) onCall) {
  final JSObject handler = JSObject();
  handler['apply'] = ((JSFunction target, JSAny? receiver, JSArray arguments) {
    onCall(arguments.toDart);
    return (globalContext['Reflect'] as JSObject).callMethod('apply'.toJS, target, receiver, arguments);
  }).toJS;
  return (globalContext['Proxy'] as JSFunction).callAsConstructor<JSObject>(original, handler);
}

/// The headers of every request the Web SDK sent from now on, each as a name to value map.
List<Map<String, String>> recordSentHeaders() {
  final List<Map<String, String>> sent = [];
  final JSObject prototype = (globalContext['XMLHttpRequest'] as JSObject)['prototype'] as JSObject;
  final JSFunction open = prototype['open'] as JSFunction;
  final JSFunction setRequestHeader = prototype['setRequestHeader'] as JSFunction;
  prototype['open'] = _spy(open, (List<JSAny?> arguments) => sent.add({}));
  prototype['setRequestHeader'] = _spy(setRequestHeader, (List<JSAny?> arguments) {
    if (sent.isNotEmpty) {
      sent.last[(arguments[0] as JSString).toDart] = (arguments[1] as JSString).toDart;
    }
  });
  addTearDown(() {
    prototype['open'] = open;
    prototype['setRequestHeader'] = setRequestHeader;
  });
  return sent;
}

/// Makes the page report itself as visible or hidden and tells it that this changed.
void setPageVisibility({required bool visible}) {
  final JSObject document = globalContext['document'] as JSObject;
  final JSObject getter = JSObject();
  final String state = visible ? 'visible' : 'hidden';
  getter['get'] = (() => state.toJS).toJS;
  getter['configurable'] = true.toJS;
  (globalContext['Object'] as JSObject).callMethod('defineProperty'.toJS, document, 'visibilityState'.toJS, getter);
  final JSObject event = (globalContext['Event'] as JSFunction).callAsConstructor<JSObject>('visibilitychange'.toJS);
  document.callMethod('dispatchEvent'.toJS, event);
}
