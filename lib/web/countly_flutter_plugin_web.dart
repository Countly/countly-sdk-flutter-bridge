import 'dart:convert';
import 'dart:html';
import 'dart:js' as js;
import 'dart:js_interop';

import 'package:countly_flutter/web/countly_flutter_web_interop.dart';
import 'package:flutter/services.dart';
import 'package:flutter_web_plugins/flutter_web_plugins.dart';

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

    // INIT RELATED
    if (call.method == 'init') {
      initialize(data[0]);
    } else if (call.method == 'isInitialized') {
      //TODO: implement isInitialized
      return Future(() => "false");
    }

    // EVENTS
    else if (call.method == 'recordEvent') {
      recordEvent(data);
    }

    // SESSIONS
    else if (call.method == 'beginSession') {
      Countly.begin_session();
    } else if (call.method == 'updateSession') {
      //TODO: implement updateSession
    } else if(call.method == 'endSession'){
      Countly.end_session();
    }

    // DEVICE ID MANAGEMENT
    else if (call.method == 'getID') {
      return Future(() => Countly.get_device_id());
    } else if (call.method == 'setID') {
      Countly.set_id(data[0]);
    } else if (call.method == 'getIDType') {
      return Future(() => getDeviceIDType(Countly.get_device_id_type()));
    } else if (call.method == 'changeWithMerge') {
      Countly.change_id(data[0], true);
    } else if (call.method == 'changeWithoutMerge') {
      Countly.change_id(data[0], false);
    } else if (call.method == 'enableTemporaryIDMode') {
      Countly.enable_offline_mode();
      // there is also disable offine mode call, but it is not needed for now
    }

    // CONSENT
    else if (call.method == 'giveConsent') {
      Countly.add_consent(data[0].jsify()!);
    } else if (call.method == 'removeConsent') {
      Countly.remove_consent(data[0].jsify()!);
    } else if (call.method == 'giveAllConsent') {
      Countly.add_consent(Countly.features.jsify()!);
    } else if (call.method == 'removeAllConsent') {
      Countly.remove_consent(Countly.features.jsify()!);
    }

    // VIEWS
    else if (call.method == 'startView' || call.method == 'startAutoStoppedView' || call.method == 'recordView') {
      recordView(data);
    }

    // CONTENT ZONE
    else if (call.method == 'enterContentZone') {
      CountlyContent.enterContentZone();
    } else if (call.method == 'exitContentZone') {
      CountlyContent.exitContentZone();
    } else {
      //throw PlatformException(code: 'Unimplemented', details: "The countly_flutter plugin for web doesn't implement the method '${call.method}'");
    }
    return Future.value();
  }

  ScriptElement _createScriptTag(String library) {
    final ScriptElement script = ScriptElement()
      ..type = 'application/javascript'
      ..charset = 'utf-8'
      ..async = true
      ..noModule = false
      ..src = library;
    return script;
  }

  /// Injects a bunch of libraries in the <head> and returns a
  /// Future that resolves when all load.
  Future<void> importLibrary() {
    final List<Future<void>> loading = <Future<void>>[];
    final head = querySelector('head');

    // try this as module
    final scriptTag = _createScriptTag('http://127.0.0.1:5500/dist/countly_umd.js');
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
    if (il == 2) {
      segments = view[1];
    } else if (il > 2) {
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

  String getDeviceIDType(int type) {
    switch (type) {
      case 0: // DEVELOPER_SUPPLIED
        return 'DS';
      case 2: // TEMPORARY_ID
        return 'TID';
      default: // 1 and default are SDK_GENERATED
        return 'SG';
    }
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
      'queue_size': config['maxRequestQueueSize'],
      'device_id': config['deviceID'],
      'force_post': config['httpPostForced'],
      'require_consent': config['shouldRequireConsent'],
      'salt': config['tamperingProtectionSalt'],
    };

    // Internal Limits
    configMap['max_key_length'] = config['maxKeyLength'];
    configMap['max_value_size'] = config['maxValueSize'];
    configMap['max_segmentation_values'] = config['maxSegmentationValues'];
    configMap['max_breadcrumb_count'] = config['maxBreadcrumbCount'];
    configMap['max_stack_trace_lines_per_thread'] = config['maxStackTraceLinesPerThread'];
    configMap['max_stack_trace_line_length'] = config['maxStackTraceLineLength'];

    // Location
    configMap['ip_address'] = config['locationIpAddress'];
    configMap['country_code'] = config['locationCountryCode'];
    configMap['city'] = config['locationCity'];

    configMap['remote_config'] = config['remoteConfigAutomaticTriggers'];

    configMap.removeWhere((key, value) => value == null);

    if (config['disableLocation'] != null && config['disableLocation'] == true) {
      configMap['ip_address'] = null;
      configMap['country_code'] = null;
      configMap['city'] = null;
    }

    Countly.init(configMap.jsify()!);
    if (config['manualSessionEnabled'] == null || config['manualSessionEnabled'] == false) {
      print(configMap);
      Countly.track_sessions();
    }

    if (config['consents'] != null) {
      Countly.add_consent(config['consents'].jsify()!);
    }
  }
}
