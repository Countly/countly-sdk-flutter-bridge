import 'dart:async';
import 'dart:convert';
import 'dart:html';
import 'dart:js' as js;
import 'dart:js_interop';
import 'dart:js_util';

import 'package:countly_flutter/countly_flutter.dart' as cly;
import 'package:countly_flutter/web/countly_sdk_web_interop.dart';
import 'package:countly_flutter/web/json_interop.dart';
import 'package:flutter/services.dart';
import 'package:flutter_web_plugins/flutter_web_plugins.dart';

class CountlyFlutterPlugin {
  static const String TAG = "CountlyFlutterPlugin";
  static const String COUNTLY_FLUTTER_SDK_VERSION_STRING = "24.11.2";
  static const String COUNTLY_FLUTTER_SDK_NAME = "dart-flutterb-web";
  List<Map<Object?, Object?>> retrievedWidgetList = [];
  MethodChannel? methodChannel;

  static const int requestIDNoCallback = -1;
  static const int requestIDGlobalCallback = -2;

  // Register the plugin with Flutter Web
  static void registerWith(Registrar registrar) {
    final MethodChannel channel = MethodChannel('countly_flutter', const StandardMethodCodec(), registrar.messenger);
    final CountlyFlutterPlugin instance = CountlyFlutterPlugin();
    instance.methodChannel = channel;
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
      return Future(() => 'false');
    }

    // EVENTS
    else if (call.method == 'recordEvent') {
      recordEvent(data);
    } else if (call.method == 'startEvent') {
      Countly.start_event(data[0]);
    } else if (call.method == 'endEvent') {
      endEvent(data);
    }

    // SESSIONS
    else if (call.method == 'beginSession') {
      Countly.begin_session();
    } else if (call.method == 'endSession') {
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
      Countly.add_consent(data.jsify()!);
    } else if (call.method == 'removeConsent') {
      Countly.remove_consent(data.jsify()!);
    } else if (call.method == 'giveAllConsent') {
      Countly.add_consent(Countly.features.jsify()!);
    } else if (call.method == 'removeAllConsent') {
      Countly.remove_consent(Countly.features.jsify()!);
    }

    // VIEWS
    else if (call.method == 'startAutoStoppedView') {
      recordView(data);
    } else if (call.method == 'setGlobalViewSegmentation' || call.method == 'updateGlobalViewSegmentation') {
      Countly.track_pageview(null, null, data[0].jsify());
    }

    // CRASHES
    else if (call.method == 'setCustomCrashSegment') {
      Map<String, dynamic> segments = extractMap(data);

      if (segments.isNotEmpty) {
        Countly.track_errors(segments.jsify()!);
      }
    } else if (call.method == 'logException') {
      String exceptionString = data[0];
      bool nonfatal = data[1];

      Map<String, dynamic> segments = extractMap(data, idxStart: 2);
      Countly.recordError({'stack': exceptionString}.jsify()!, nonfatal, segments.jsify()!);
    } else if (call.method == 'addCrashLog') {
      Countly.add_log(data[0]);
    }

    // INTERNALS
    else if (call.method == 'getRequestQueue') {
      dynamic object = CountlyInternal.getRequestQueue();
      List<String> requestList = [];
      for (dynamic item in object) {
        requestList.add(JSON.stringify(item)); // will get from config
      }
      return Future(() => requestList);
    } else if (call.method == 'getEventQueue') {
      dynamic object = CountlyInternal.getEventQueue();
      List<String> eventList = [];
      for (dynamic item in object) {
        eventList.add(JSON.stringify(item));
      }
      return Future(() => eventList);
    }

    // USER PROFILES
    else if (call.method == 'setuserdata') {
      reportUserDetails(data[0]);
    } else if (call.method.startsWith('userData_')) {
      userDataOps(call.method, data);
    } else if (call.method.startsWith('userProfile_')) {
      userProfileOps(call.method, data);
    }

    // FEEDBACK
    else if (call.method == 'presentNPS') {
      CountlyFeedback.showNPS(data[0]);
    } else if (call.method == 'presentSurvey') {
      CountlyFeedback.showSurvey(data[0]);
    } else if (call.method == 'presentRating') {
      CountlyFeedback.showRating(data[0]);
    } else if (call.method == 'getAvailableFeedbackWidgets') {
      retrievedWidgetList.clear(); // clear previous state
      // Create a Completer to manage the Future
      final completer = Completer<dynamic>();

      // Wrap the Dart function using allowInterop
      var callback = allowInterop((JSAny? widgets, String? error) {
        if (error != null) {
          // Complete with an error if one is returned
          completer.completeError(error);
          return;
        }

        List<Map<String, String>> dartFeedbackWidgets = [];

        if (widgets != null) {
          // Convert the JS object to a Dart Map
          List<dynamic> dartWidgets = widgets.dartify() as List<dynamic>;
          for (dynamic widget in dartWidgets) {
            retrievedWidgetList.add(widget);
            dartFeedbackWidgets.add({
              'id': widget['_id'].toString(),
              'type': widget['type'].toString(),
              'name': widget['name'].toString(),
            });
          }

          // Complete the Future with the widgets data
          completer.complete(dartFeedbackWidgets);
        }
      });

      // Call the JS function
      Countly.get_available_feedback_widgets(callback.jsify());

      // Return the Future from the Completer
      return completer.future;
    } else if (call.method == 'presentFeedbackWidget') {
      String widgetId = data[0];
      Map<Object?, Object?> widget = retrievedWidgetList.firstWhere((element) => element['_id'] == widgetId, orElse: () => {});
      if (widget.isEmpty) {
        return Future.error("[presentFeedbackWidget], No feedbackWidget is found against widget id: '$widgetId', always call 'getFeedbackWidgets' to get updated list of feedback widgets.");
      }
      Countly.present_feedback_widget(widget.jsify(), null, null, null);
    } else if (call.method == 'getFeedbackWidgetData') {
      String widgetId = data[0];
      Map<Object?, Object?> widget = retrievedWidgetList.firstWhere((element) => element['_id'] == widgetId, orElse: () => {});
      final completer = Completer<dynamic>();

      if (widget.isEmpty) {
        String errorInit = "[getFeedbackWidgetData], No feedbackWidget is found against widget id: '$widgetId', always call 'getFeedbackWidgets' to get updated list of feedback widgets.";

        Map<String, Object?> callbackData = prepareCallbackData(null, errorInit);
        await methodChannel?.invokeMethod('feedbackWidgetDataCallback', callbackData);
        completer.complete([callbackData]);
      }

      // Wrap the Dart function using allowInterop
      var callback = allowInterop((JSAny? feedbackWidgetData, String? error) {
        Map<String, Object?> returnedObject = prepareCallbackData(feedbackWidgetData?.dartify(), error);

        methodChannel?.invokeMethod('feedbackWidgetDataCallback', returnedObject);
        // Complete the Future with the widgets data
        completer.complete([returnedObject]);
      });

      Countly.getFeedbackWidgetData(widget.jsify(), callback.jsify());
      return completer.future;
    } else if (call.method == 'reportFeedbackWidgetManually') {
      List<dynamic> widgetInfo = data[0];
      Map<String, dynamic> widgetData = data[1];
      Map<String, dynamic>? widgetResult = data[2];
      String widgetId = widgetInfo[0];

      Map<Object?, Object?> widget = retrievedWidgetList.firstWhere((element) => element['_id'] == widgetId, orElse: () => {});
      if (widget.isEmpty) {
        return Future.error("[reportFeedbackWidgetManually], No feedbackWidget is found against widget id: '$widgetId', always call 'getFeedbackWidgets' to get updated list of feedback widgets.");
      }

      Countly.reportFeedbackWidgetManually(widget.jsify(), widgetData.jsify(), widgetResult.jsify());
    }

    // REMOTE CONFIG
    else if (call.method == 'remoteConfigDownloadValues') {
      int requestID = data[0];
      Countly.fetch_remote_config(
          null,
          null,
          allowInterop((JSAny? error, JSAny? remoteConfigs) {
            if (requestID == requestIDNoCallback) {
              return;
            }
            notifyRemoteConfigDownloadCallback(error, remoteConfigs, true, requestID);
          }).jsify());
    } else if (call.method == 'remoteConfigGetAllValues') {
      return Future.value(convertMapToRCData(Countly.get_remote_config()?.dartify()));
    } else if (call.method == 'getRemoteConfigValueForKey') {
      String key = data[0];
      return Future.value(Countly.get_remote_config(key).dartify());
    } else if (call.method == 'remoteConfigDownloadSpecificValue') {
      int requestID = data[0];
      Countly.fetch_remote_config(
          data[1],
          null,
          allowInterop((JSAny? error, JSAny? remoteConfigs) {
            if (requestID == requestIDNoCallback) {
              return;
            }
            notifyRemoteConfigDownloadCallback(error, remoteConfigs, false, requestID);
          }).jsify());
    } else if (call.method == 'remoteConfigDownloadOmittingValues') {
      int requestID = data[0];
      Countly.fetch_remote_config(
          null,
          data[1],
          allowInterop((JSAny? error, JSAny? remoteConfigs) {
            if (requestID == requestIDNoCallback) {
              return;
            }
            notifyRemoteConfigDownloadCallback(error, remoteConfigs, false, requestID);
          }).jsify());
    } else if (call.method == 'remoteConfigGetValue') {
      String key = data[0];
      return Future.value({'value': Countly.get_remote_config(key)?.dartify(), 'isCurrentUsersData': true});
    } else if (call.method == 'getRemoteConfigValueForKey') {
      String key = data[0];
      return Future.value({'value': Countly.get_remote_config(key)?.dartify()?.toString(), 'isCurrentUsersData': true});
    }

    // LEGACY REMOTE CONFIG
    else if (call.method == 'updateRemoteConfigForKeysOnly') {
      return updateValuesRC(data.jsify(), null);
    } else if (call.method == 'updateRemoteConfigExceptKeys') {
      return updateValuesRC(null, data.jsify());
    } else if (call.method == 'remoteConfigUpdate') {
      return updateValuesRC(null, null);
    }

    // A/B TESTING
    else if (call.method == 'remoteConfigGetValueAndEnroll') {
      String key = data[0];
      dynamic value = Countly.get_remote_config(key).dartify();
      Countly.enrollUserToAb([key].jsify());
      return Future.value({'value': value, 'isCurrentUsersData': true});
    } else if (call.method == 'remoteConfigGetAllValuesAndEnroll') {
      Map<String, Map<String, dynamic>> rcValues = convertMapToRCData(Countly.get_remote_config(null).dartify());
      Countly.enrollUserToAb(rcValues.keys.toList().jsify());
      return Future.value(rcValues);
    } else if (call.method == 'remoteConfigEnrollIntoABTestsForKeys') {
      Countly.enrollUserToAb(data[0].jsify());
    }

    // CONTENT ZONE
    else if (call.method == 'enterContentZone') {
      CountlyContent.enterContentZone();
    } else if (call.method == 'exitContentZone') {
      CountlyContent.exitContentZone();
    } else {
      cly.Countly.log("The countly_flutter plugin for web doesn't implement the method ${call.method}", logLevel: cly.LogLevel.ERROR);
    }
    return Future.value();
  }

  Map<String, Object?> prepareCallbackData(Object? data, String? error) {
    Map<String, Object?> returnedObject = {};
    returnedObject['widgetData'] = data;
    if (error != null) {
      returnedObject['error'] = error;
    }

    return returnedObject;
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
  Future<void> importLibrary() async {
    final head = querySelector('head');

    // try this as module
    final scriptTag = _createScriptTag('http://127.0.0.1:5500/dist/countly_umd.js');
    head?.children.add(scriptTag);
    await scriptTag.onLoad.first;

    return Future.value();
  }

  void reportUserDetails(Map<String, dynamic> userData) {
    Map<String, dynamic> bundle = {};
    bundle['custom'] = <String, dynamic>{};

    userData.forEach((key, value) {
      if (key == 'name') {
        bundle['name'] = value;
      } else if (key == 'username') {
        bundle['username'] = value;
      } else if (key == 'email') {
        bundle['email'] = value;
      } else if (key == 'organization') {
        bundle['organization'] = value;
      } else if (key == 'phone') {
        bundle['phone'] = value;
      } else if (key == 'picture') {
        bundle['picture'] = value;
      } else if (key == 'gender') {
        bundle['gender'] = value;
      } else if (key == 'byear') {
        bundle['byear'] = value;
      } else {
        // Add any other key-value pair to the 'custom' section
        (bundle['custom'] as Map<String, dynamic>)[key] = value;
      }
    });

    if ((bundle['custom'] as Map<String, dynamic>).isEmpty) {
      bundle.remove('custom');
    }

    if (bundle.isNotEmpty) {
      Countly.user_details(bundle.jsify()!);
    }
  }

  void userProfileOps(String method, List<dynamic> data) {
    if (method == 'userProfile_setProperties') {
      reportUserDetails(data[0]);
    } else if (method == 'userProfile_setProperty') {
      String keyName = data[0];
      Object keyValue = data[1];
      CountlyUserData.set(keyName, keyValue.jsify());
    } else if (method == 'userProfile_increment') {
      String keyName = data[0];
      CountlyUserData.increment(keyName);
    } else if (method == 'userProfile_incrementBy') {
      String key = data[0];
      int value = data[1];
      CountlyUserData.increment_by(key, value);
    } else if (method == 'userProfile_multiply') {
      String key = data[0];
      int value = data[1];
      CountlyUserData.multiply(key, value);
    } else if (method == 'userProfile_saveMax') {
      String key = data[0];
      int value = data[1];
      CountlyUserData.max(key, value);
    } else if (method == 'userProfile_saveMin') {
      String key = data[0];
      int value = data[1];
      CountlyUserData.min(key, value);
    } else if (method == 'userProfile_setOnce') {
      String key = data[0];
      Object value = data[1];
      CountlyUserData.set_once(key, value.jsify());
    } else if (method == 'userProfile_pushUnique') {
      String key = data[0];
      Object value = data[1];
      CountlyUserData.push_unique(key, value.jsify());
    } else if (method == 'userProfile_push') {
      String key = data[0];
      Object value = data[1];
      CountlyUserData.push(key, value.jsify());
    } else if (method == 'userProfile_pull') {
      String key = data[0];
      Object value = data[1];
      CountlyUserData.pull(key, value.jsify());
    } else if (method == 'userProfile_save') {
      CountlyUserData.save();
    } else {
      cly.Countly.log("The countly_flutter plugin for web doesn't implement the method $method", logLevel: cly.LogLevel.ERROR);
    }
  }

  void userDataOps(String method, List<dynamic> data) {
    if (method == 'userData_setProperty') {
      String keyName = data[0];
      String keyValue = data[1];
      CountlyUserData.set(keyName, keyValue.jsify());
      CountlyUserData.save();
    } else if (method == 'userData_increment') {
      String keyName = data[0];
      CountlyUserData.increment(keyName);
      CountlyUserData.save();
    } else if (method == 'userData_incrementBy') {
      String keyName = data[0];
      int value = data[1];
      CountlyUserData.increment_by(keyName, value);
      CountlyUserData.save();
    } else if (method == 'userData_saveMax') {
      String keyName = data[0];
      int value = data[1];
      CountlyUserData.max(keyName, value);
      CountlyUserData.save();
    } else if (method == 'userData_saveMin') {
      String keyName = data[0];
      int value = data[1];
      CountlyUserData.min(keyName, value);
      CountlyUserData.save();
    } else if (method == 'userData_setOnce') {
      String keyName = data[0];
      String value = data[1];
      CountlyUserData.set_once(keyName, value.jsify());
      CountlyUserData.save();
    } else if (method == 'userData_pushUniqueValue') {
      String keyName = data[0];
      String value = data[1];
      CountlyUserData.push_unique(keyName, value.jsify());
      CountlyUserData.save();
    } else if (method == 'userData_pushValue') {
      String keyName = data[0];
      String value = data[1];
      CountlyUserData.push(keyName, value.jsify());
      CountlyUserData.save();
    } else if (method == 'userData_pullValue') {
      String keyName = data[0];
      String value = data[1];
      CountlyUserData.pull(keyName, value.jsify());
      CountlyUserData.save();
    } else {
      cly.Countly.log("The countly_flutter plugin for web doesn't implement the method $method", logLevel: cly.LogLevel.ERROR);
    }
  }

  void recordEvent(List<dynamic> event) {
    assert(event.length >= 4);
    // first 4 parameters are sent always
    // ket, count, sum, dur, segmentation might be sent
    Countly.add_event({'key': event[0], 'count': event[1], 'sum': event[2], 'dur': event[3], 'segmentation': event.length > 4 ? event[4] : null}.jsify()!);
  }

  void endEvent(List<dynamic> event) {
    assert(event.length >= 3);
    // first parameter is key
    Countly.end_event({'key': event[0], 'count': event[1], 'sum': event[2], 'segmentation': event.length > 3 ? event[3] : null}.jsify()!);
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
      segments = extractMap(view, idxStart: 1);
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

  Future<dynamic> updateValuesRC(JSAny? included, JSAny? excluded) {
    final completer = Completer<dynamic>();
    Countly.fetch_remote_config(
        included,
        excluded,
        allowInterop((JSAny? error) {
          if (error != null) {
            completer.complete('Error: $error');
          } else {
            completer.complete('Success');
          }
        }).jsify());
    return completer.future;
  }

  Map<String, dynamic> extractMap(List<dynamic> data, {int idxStart = 0}) {
    Map<String, dynamic> map = {};
    for (int i = 0; i < data.length; i += 2) {
      map[data[i]] = data[i + 1];
    }
    return map;
  }

  Map<String, Map<String, dynamic>> convertMapToRCData(dynamic rcData) {
    if (rcData == null) {
      return {};
    }
    Map<String, Map<String, dynamic>> data = {};
    rcData.forEach((key, value) {
      data[key] = {'value': value, 'isCurrentUsersData': true};
    });
    return data;
  }

  void notifyRemoteConfigDownloadCallback(JSAny? error, JSAny? remoteConfigs, bool fullValueUpdate, int id) {
    Map<String, dynamic> data = {};
    dynamic errorDart = error?.dartify();
    data['error'] = errorDart is bool ? null : errorDart;
    data['requestResult'] = remoteConfigs != null ? 0 : 2;
    data['downloadedValues'] = convertMapToRCData(remoteConfigs?.dartify());
    data['fullValueUpdate'] = fullValueUpdate;
    data['id'] = id;

    methodChannel?.invokeMethod('remoteConfigDownloadCallback', data);
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
      'force_post': config['httpPostForced'],
      'require_consent': config['shouldRequireConsent'],
      'salt': config['tamperingProtectionSalt'],
    };

    var deviceID = config['deviceID'];
    if (deviceID != null) {
      if (deviceID == 'CLYTemporaryDeviceID') {
        configMap['offline_mode'] = true;
      } else {
        configMap['device_id'] = deviceID;
      }
    }

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

    // Remote Config
    bool? rcEnabled = config['remoteConfigAutomaticTriggers'];
    configMap['rc_automatic_optin_for_ab'] = config['autoEnrollABOnDownload'];
    configMap['use_explicit_rc_api'] = true;
    if (rcEnabled != null && rcEnabled) {
      // not feedback one, RC download one
      configMap['remote_config'] = allowInterop((JSAny? error, JSAny? remoteConfigs) => notifyRemoteConfigDownloadCallback(error, remoteConfigs, true, requestIDGlobalCallback)).jsify();
    }

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

    if (config['enableUnhandledCrashReporting'] != null) {
      Countly.track_errors(null);
    }

    if (config['customCrashSegment'] != null) {
      Countly.track_errors(config['customCrashSegment'].jsify());
    }

    if (config['globalViewSegmentation'] != null) {
      Countly.track_pageview(null, null, config['globalViewSegmentation'].jsify());
    }
  }
}
