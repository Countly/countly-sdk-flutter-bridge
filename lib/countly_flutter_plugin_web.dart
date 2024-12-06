import 'dart:html';
import 'dart:js_interop';
import 'dart:js' as js;
import 'dart:convert';
import 'dart:js';
import 'dart:html' as html;
import 'dart:js_interop';
import 'dart:js_interop_unsafe';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_web_plugins/flutter_web_plugins.dart';
import 'dart:js_util' as js_util;

@JS('Countly') // Bind to the global 'Countly' object
@staticInterop
class Countly {
  external static void init(JSAny config);
  external static void add_event(JSAny event);

  // Session Management
  external static void begin_session();
  external static void track_sessions(); // Auto session tracking

  // Device ID Management
  external static String get_device_id();
  external static void set_id(String id);

  // View Management
  external static void track_view(String viewName, JSArray? ignoreList, JSAny? segments);
}

@JS('Countly.content') // Bind to 'Countly.content'
@staticInterop
class CountlyContent {
  external static void enterContentZone();
  external static void exitContentZone();
}

class CountlyFlutterPluginWeb {
  static const String TAG = "CountlyFlutterPlugin";
  static const String COUNTLY_FLUTTER_SDK_VERSION_STRING = "24.11.2";
  static const String COUNTLY_FLUTTER_SDK_NAME = "dart-flutterb-web";

  // Register the plugin with Flutter Web
  static void registerWith(Registrar registrar) {
    final MethodChannel channel = MethodChannel('countly_flutter', const StandardMethodCodec(), registrar.messenger);
    final CountlyFlutterPluginWeb instance = CountlyFlutterPluginWeb();
    channel.setMethodCallHandler(instance.handleMethodCall);
  }

  // insert module as package
  Future<dynamic> handleMethodCall(MethodCall call) async {
    if (!js.context.hasProperty('Countly')) {
      await importLibrary();
    }
    List<dynamic> data = List.empty();
    if (call.arguments != null && call.arguments['data'] != null) {
      data = jsonDecode(call.arguments['data']);
    }
    if (call.method == 'init') {
      initialize(data[0]);
    } else if (call.method == 'isInitialized') {
      //TODO: implement isInitialized
      return Future(() => "false");
    } else if (call.method == 'recordEvent') {
      recordEvent(data);
    } else if (call.method == 'beginSession') {
      Countly.begin_session();
    } else if (call.method == 'getID') {
      return Future(() => Countly.get_device_id());
    } else if (call.method == 'setID') {
      Countly.set_id(data[0]);
    } else if (call.method == 'startView' || call.method == 'startAutoStoppedView' || call.method == 'recordView') {
      recordView(data);
    } else if(call.method == 'enterContentZone'){
      CountlyContent.enterContentZone();
    } else if(call.method == 'exitContentZone'){
      CountlyContent.exitContentZone();
    } else {
      //throw PlatformException(code: 'Unimplemented', details: "The countly_flutter plugin for web doesn't implement the method '${call.method}'");
    }
    return Future.value();
  }

  ScriptElement _createScriptTag(String library) {
    final ScriptElement script = ScriptElement()
      ..type = "application/javascript"
      ..charset = "utf-8"
      ..async = true
      //..defer = true
      ..src = library;
    return script;
  }

  /// Injects a bunch of libraries in the <head> and returns a
  /// Future that resolves when all load.
  Future<void> importLibrary() {
    final List<Future<void>> loading = <Future<void>>[];
    final head = querySelector('head');

    // try this as module
    final scriptTag = _createScriptTag('https://cdn.jsdelivr.net/npm/countly-sdk-web@latest/lib/countly.min.js');
    head?.children.add(scriptTag);
    loading.add(scriptTag.onLoad.first);

    return Future.wait(loading);
  }

  void recordEvent(List<dynamic> event) {
    assert(event.length >= 4);
    // first 4 parameters are sent always
    // ket, count, sum, dur, segmentation might be sent
    Countly.add_event({'key': event[0], 'count': event[1], 'sum': event[2], 'dur': event[3], 'segmentation': event.length > 4 ? event[4] : null}.jsify()!);
  }

  void recordView(List<dynamic> view) {
    assert(view.isNotEmpty);
    // first parameter is view name
    String viewName = view[0];
    var segments = {};

    int il = view.length;
    if(il == 2){
      segments = view[1];
    }
    else if(il > 2) {
      for (int i = 1; i < il; i += 2) {
        try {
          segments[view[i]] = view[i + 1];
        } catch (e) {
          //TODO print("recordView: could not parse segments, skipping it. Error: $e");
        }
      }
    }
    // ignore list and segmentation might be sent
    Countly.track_view(viewName, null, segments.jsify()!);
  }

  void initialize(Map<String, dynamic> config) {
    Map<String, dynamic> configMap = {
      'app_key': config['appKey'],
      'url': config['serverURL'],
      'sdk_name': COUNTLY_FLUTTER_SDK_NAME,
      'sdk_version': COUNTLY_FLUTTER_SDK_VERSION_STRING,
      'debug': config['loggingEnabled'],
      'session_update': config['sessionUpdateTimerDelay'],
      'max_events': config['eventQueueSizeThreshold'],
      'queue_size': config['maxRequestQueueSize']
    };

    configMap.removeWhere((key, value) => value == null);
    Countly.init(configMap.jsify()!);
    if(config['manualSessionEnabled'] == null || config['manualSessionEnabled'] == false){
      print(configMap);
      Countly.track_sessions();
    }
  }
}
