import 'dart:async';
import 'dart:convert';
import 'dart:html';
import 'dart:js' as js;
import 'dart:js_interop';
import 'dart:js_util';

import 'package:countly_flutter/countly_flutter.dart' as cly;
import 'package:countly_flutter/src/web/countly_sdk_web_interop.dart';
import 'package:countly_flutter/src/web/json_interop.dart';
import 'package:countly_flutter/src/web/plugin_config.dart';
import 'package:flutter/services.dart';
import 'package:flutter_web_plugins/flutter_web_plugins.dart';

class CountlyFlutterPlugin {
  MethodChannel? methodChannel;

  /// The widgets each instance last listed, keyed by instance, so a widget ID is presented on the
  /// instance that fetched it.
  final Map<String, List<Map<Object?, Object?>>> _retrievedWidgetLists = {};

  /// The custom traces each instance has running, keyed by instance and then by trace key, holding
  /// the start time in milliseconds. The Web SDK only takes finished traces, so the timing is kept here.
  final Map<String, Map<String, int>> _runningTraces = {};

  /// Every instance this plugin initialized, keyed by the name the Dart side gave it.
  /// The default instance is kept under the reserved name, which no named instance can take.
  static const String _defaultInstanceKey = cly.Countly.defaultInstanceName;
  final Map<String, Countly> _instances = {};

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
      await _importLibrary();
    }
    List<dynamic> data = List.empty();
    if (call.arguments != null && call.arguments['data'] != null) {
      data = jsonDecode(call.arguments['data']);
    }
    final String instanceKey = _instanceKeyOf(call);

    // INIT RELATED
    if (call.method == 'init') {
      _initialize(instanceKey, data[0]);
      return Future.value();
    } else if (call.method == 'isInitialized') {
      return Future(() => _instances.containsKey(instanceKey) ? 'true' : 'false');
    } else if (call.method == 'removeInstance') {
      _removeInstance(instanceKey);
      return Future.value();
    } else if (call.method == 'haltAllInstances') {
      for (final Countly registered in _instances.values) {
        registered.halt();
      }
      _instances.clear();
      _retrievedWidgetLists.clear();
      _runningTraces.clear();
      return Future.value();
    }

    final Countly? countly = _instances[instanceKey];
    if (countly == null) {
      cly.Countly.log('[CountlyFlutterPluginWeb] handleMethodCall, "${call.method}" was called before the instance was initialized', logLevel: cly.LogLevel.ERROR);
      if (call.method == 'getRequestQueue' || call.method == 'getEventQueue') {
        return Future.value(<String>[]);
      }
      return Future.value();
    }

    // EVENTS
    if (call.method == 'recordEvent') {
      _recordEvent(countly, data);
    } else if (call.method == 'startEvent') {
      countly.start_event(data[0]);
    } else if (call.method == 'endEvent') {
      _endEvent(countly, data);
    } else if (call.method == 'cancelEvent') {
      countly.cancel_event(data[0]);
    }

    // SESSIONS
    else if (call.method == 'beginSession') {
      countly.begin_session();
    } else if (call.method == 'endSession') {
      countly.end_session();
    }

    // DEVICE ID MANAGEMENT
    else if (call.method == 'getID') {
      return Future(() => countly.get_device_id());
    } else if (call.method == 'setID') {
      countly.set_id(data[0]);
    } else if (call.method == 'getIDType') {
      return Future(() => _getDeviceIDType(countly.get_device_id_type()));
    } else if (call.method == 'changeWithMerge') {
      countly.change_id(data[0], true);
    } else if (call.method == 'changeWithoutMerge') {
      countly.change_id(data[0], false);
    } else if (call.method == 'enableTemporaryIDMode') {
      countly.enable_offline_mode();
      // there is also disable offine mode call, but it is not needed for now
    }

    // CONSENT
    else if (call.method == 'giveConsent') {
      countly.add_consent(data.jsify()!);
    } else if (call.method == 'removeConsent') {
      countly.remove_consent(data.jsify()!);
    } else if (call.method == 'giveAllConsent') {
      countly.add_consent(countlyGlobal.features.jsify()!);
    } else if (call.method == 'removeAllConsent') {
      countly.remove_consent(countlyGlobal.features.jsify()!);
    }

    // VIEWS
    else if (call.method == 'startAutoStoppedView') {
      _recordView(countly, data);
    }

    // CRASHES
    else if (call.method == 'setCustomCrashSegment') {
      Map<String, dynamic> segments = _extractMap(data);

      if (segments.isNotEmpty) {
        countly.track_errors(segments.jsify()!);
      }
    } else if (call.method == 'logException') {
      String exceptionString = data[0];
      bool nonfatal = data[1] == 'true';

      Map<String, dynamic> segments = _extractMap(data, idxStart: 2);
      countly.recordError({'stack': exceptionString}.jsify()!, nonfatal, segments.jsify()!);
    } else if (call.method == 'addCrashLog') {
      countly.add_log(data[0]);
    }

    // INTERNALS
    else if (call.method == 'getRequestQueue') {
      dynamic object = countly.internals.getRequestQueue();
      List<String> requestList = [];
      for (dynamic item in object) {
        requestList.add(JSON.stringify(item)); // will get from config
      }
      return Future(() => requestList);
    } else if (call.method == 'getEventQueue') {
      dynamic object = countly.internals.getEventQueue();
      List<String> eventList = [];
      for (dynamic item in object) {
        eventList.add(JSON.stringify(item));
      }
      return Future(() => eventList);
    } else if (call.method == 'halt') {
      // The instance is dropped as well, so the same name can be initialized again afterwards.
      countly.halt();
      _instances.remove(instanceKey);
    }

    // USER PROFILES
    else if (call.method == 'setuserdata') {
      _reportUserDetails(countly, data[0]);
    } else if (call.method.startsWith('userData_')) {
      _userDataOps(countly, call.method, data);
    } else if (call.method.startsWith('userProfile_')) {
      _userProfileOps(countly, call.method, data);
    }

    // FEEDBACK
    else if (call.method == 'presentNPS') {
      countly.feedback.showNPS(data[0]);
    } else if (call.method == 'presentSurvey') {
      countly.feedback.showSurvey(data[0]);
    } else if (call.method == 'presentRating') {
      countly.feedback.showRating(data[0]);
    } else if (call.method == 'getAvailableFeedbackWidgets') {
      final List<Map<Object?, Object?>> retrievedWidgetList = _retrievedWidgetLists[instanceKey] = [];
      // Create a Completer to manage the Future
      final completer = Completer<dynamic>();

      // Wrap the Dart function using allowInterop
      var callback = allowInterop((JSAny? widgets, String? error) {
        if (error != null) {
          // Complete with an error if one is returned
          cly.Countly.log('[CountlyFlutterPluginWeb] getAvailableFeedbackWidgets $error', logLevel: cly.LogLevel.ERROR);
          completer.complete(error);
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
      countly.get_available_feedback_widgets(callback.jsify());

      // Return the Future from the Completer
      return completer.future;
    } else if (call.method == 'presentFeedbackWidget' || call.method == 'presentRatingWidgetWithID') {
      String widgetId = data[0];
      Map<Object?, Object?> widget = _findWidget(instanceKey, widgetId);
      if (widget.isEmpty) {
        String message = "[CountlyFlutterPluginWeb] presentFeedbackWidget, No feedbackWidget is found against widget id: '$widgetId', always call 'getFeedbackWidgets' to get updated list of feedback widgets.";
        cly.Countly.log(message, logLevel: cly.LogLevel.ERROR);
        return Future.value(message);
      }
      countly.present_feedback_widget(widget.jsify(), null, null, null);
    } else if (call.method == 'getFeedbackWidgetData') {
      String widgetId = data[0];
      Map<Object?, Object?> widget = _findWidget(instanceKey, widgetId);
      final completer = Completer<dynamic>();

      if (widget.isEmpty) {
        String errorInit = "[getFeedbackWidgetData], No feedbackWidget is found against widget id: '$widgetId', always call 'getFeedbackWidgets' to get updated list of feedback widgets.";
        Map<String, Object?> callbackData = prepareCallbackData(instanceKey, null, errorInit);
        await methodChannel?.invokeMethod('feedbackWidgetDataCallback', callbackData);
        completer.complete([callbackData]);
      }

      // Wrap the Dart function using allowInterop
      var callback = allowInterop((JSAny? feedbackWidgetData, String? error) {
        Map<String, Object?> returnedObject = prepareCallbackData(instanceKey, feedbackWidgetData?.dartify(), error);

        methodChannel?.invokeMethod('feedbackWidgetDataCallback', returnedObject);
        // Complete the Future with the widgets data
        completer.complete([returnedObject]);
      });

      countly.getFeedbackWidgetData(widget.jsify(), callback.jsify());
      return completer.future;
    } else if (call.method == 'reportFeedbackWidgetManually') {
      List<dynamic> widgetInfo = data[0];
      Map<String, dynamic> widgetData = data[1];
      Map<String, dynamic>? widgetResult = data[2];
      String widgetId = widgetInfo[0];

      Map<Object?, Object?> widget = _findWidget(instanceKey, widgetId);
      if (widget.isEmpty) {
        String message = "[CountlyFlutterPluginWeb] reportFeedbackWidgetManually, No feedbackWidget is found against widget id: '$widgetId', always call 'getFeedbackWidgets' to get updated list of feedback widgets.";
        cly.Countly.log(message, logLevel: cly.LogLevel.ERROR);
        return Future.value(message);
      }

      countly.reportFeedbackWidgetManually(widget.jsify(), widgetData.jsify(), widgetResult.jsify());
    }

    // REMOTE CONFIG
    else if (call.method == 'remoteConfigDownloadValues') {
      int requestID = data[0];
      countly.fetch_remote_config(
          null,
          null,
          allowInterop((JSAny? error, JSAny? remoteConfigs) {
            if (requestID == requestIDNoCallback) {
              return;
            }
            _notifyRemoteConfigDownloadCallback(instanceKey, error, remoteConfigs, true, requestID);
          }).jsify());
    } else if (call.method == 'remoteConfigGetAllValues') {
      return Future.value(_convertMapToRCData(countly.get_remote_config()?.dartify()));
    } else if (call.method == 'getRemoteConfigValueForKey') {
      String key = data[0];
      return Future.value(countly.get_remote_config(key).dartify());
    } else if (call.method == 'remoteConfigDownloadSpecificValue') {
      int requestID = data[0];
      countly.fetch_remote_config(
          data[1],
          null,
          allowInterop((JSAny? error, JSAny? remoteConfigs) {
            if (requestID == requestIDNoCallback) {
              return;
            }
            _notifyRemoteConfigDownloadCallback(instanceKey, error, remoteConfigs, false, requestID);
          }).jsify());
    } else if (call.method == 'remoteConfigDownloadOmittingValues') {
      int requestID = data[0];
      countly.fetch_remote_config(
          null,
          data[1],
          allowInterop((JSAny? error, JSAny? remoteConfigs) {
            if (requestID == requestIDNoCallback) {
              return;
            }
            _notifyRemoteConfigDownloadCallback(instanceKey, error, remoteConfigs, false, requestID);
          }).jsify());
    } else if (call.method == 'remoteConfigGetValue') {
      String key = data[0];
      return Future.value({'value': countly.get_remote_config(key)?.dartify(), 'isCurrentUsersData': true});
    } else if (call.method == 'getRemoteConfigValueForKey') {
      String key = data[0];
      return Future.value({'value': countly.get_remote_config(key)?.dartify()?.toString(), 'isCurrentUsersData': true});
    }

    // LEGACY REMOTE CONFIG
    else if (call.method == 'updateRemoteConfigForKeysOnly') {
      return _updateValuesRC(countly, data.jsify(), null);
    } else if (call.method == 'updateRemoteConfigExceptKeys') {
      return _updateValuesRC(countly, null, data.jsify());
    } else if (call.method == 'remoteConfigUpdate') {
      return _updateValuesRC(countly, null, null);
    }

    // A/B TESTING
    else if (call.method == 'remoteConfigGetValueAndEnroll') {
      String key = data[0];
      dynamic value = countly.get_remote_config(key).dartify();
      countly.enrollUserToAb([key].jsify());
      return Future.value({'value': value, 'isCurrentUsersData': true});
    } else if (call.method == 'remoteConfigGetAllValuesAndEnroll') {
      Map<String, Map<String, dynamic>> rcValues = _convertMapToRCData(countly.get_remote_config(null).dartify());
      countly.enrollUserToAb(rcValues.keys.toList().jsify());
      return Future.value(rcValues);
    } else if (call.method == 'remoteConfigEnrollIntoABTestsForKeys') {
      countly.enrollUserToAb(data[0]);
    }

    // LOCATION
    else if (call.method == 'setUserLocation' || call.method == 'disableLocation') {
      cly.Countly.log('[CountlyFlutterPluginWeb] ${call.method}, the Web SDK only takes the location at init, through "CountlyConfig.setLocation"', logLevel: cly.LogLevel.WARNING);
    }

    // PERFORMANCE MONITORING
    else if (call.method == 'startTrace') {
      _runningTraces.putIfAbsent(instanceKey, () => {})[data[0] as String] = DateTime.now().millisecondsSinceEpoch;
    } else if (call.method == 'cancelTrace') {
      _runningTraces[instanceKey]?.remove(data[0] as String);
    } else if (call.method == 'clearAllTraces') {
      _runningTraces.remove(instanceKey);
    } else if (call.method == 'endTrace') {
      _endTrace(countly, instanceKey, data);
    } else if (call.method == 'recordNetworkTrace') {
      _recordNetworkTrace(countly, data);
    } else if (call.method == 'appLoadingFinished') {
      cly.Countly.log('[CountlyFlutterPluginWeb] appLoadingFinished, app start time tracking is not supported on web', logLevel: cly.LogLevel.WARNING);
    }

    // ATTRIBUTION
    else if (call.method == 'recordDirectAttribution') {
      _recordDirectAttribution(countly, data[0] as String, data[1] as String);
    } else if (call.method == 'recordIndirectAttribution') {
      cly.Countly.log('[CountlyFlutterPluginWeb] recordIndirectAttribution, indirect attribution is not supported on web', logLevel: cly.LogLevel.WARNING);
    }

    // CONTENT ZONE
    else if (call.method == 'enterContentZone') {
      countly.content.enterContentZone();
    } else if (call.method == 'exitContentZone') {
      countly.content.exitContentZone();
    } else {
      cly.Countly.log('[CountlyFlutterPluginWeb] handleMethodCall, The method ${call.method} does not implemented', logLevel: cly.LogLevel.ERROR);
    }
    return Future.value();
  }

  /// Reads the registry key a method call is meant for. Calls from the default instance carry no name.
  String _instanceKeyOf(MethodCall call) {
    final Object? arguments = call.arguments;
    final Object? name = arguments is Map ? arguments['instanceName'] : null;
    if (name is String && name.isNotEmpty && name != _defaultInstanceKey) {
      return name;
    }
    return _defaultInstanceKey;
  }

  /// Drops the named instance from the registry, keeping what it stored.
  /// The Web SDK's only teardown is "halt", which erases the instance's stored data, so the instance
  /// is dropped rather than stopped. It stays in memory until the page is unloaded.
  void _removeInstance(String instanceKey) {
    if (instanceKey == _defaultInstanceKey) {
      cly.Countly.log('[CountlyFlutterPluginWeb] removeInstance, the default instance can not be removed', logLevel: cly.LogLevel.WARNING);
      return;
    }
    if (_instances.remove(instanceKey) == null) {
      cly.Countly.log('[CountlyFlutterPluginWeb] removeInstance, no instance registered under [$instanceKey]', logLevel: cly.LogLevel.WARNING);
    }
    _retrievedWidgetLists.remove(instanceKey);
    _runningTraces.remove(instanceKey);
  }

  /// Reports a custom trace the instance started, with its duration and the given metrics.
  /// [List<dynamic> data] - the trace key followed by metric name and value pairs
  void _endTrace(Countly countly, String instanceKey, List<dynamic> data) {
    final String traceKey = data[0] as String;
    final int? startTime = _runningTraces[instanceKey]?.remove(traceKey);
    if (startTime == null) {
      cly.Countly.log('[CountlyFlutterPluginWeb] endTrace, no trace named [$traceKey] was started', logLevel: cly.LogLevel.WARNING);
      return;
    }
    final int endTime = DateTime.now().millisecondsSinceEpoch;
    final Map<String, num> metrics = {'duration': endTime - startTime};
    for (int i = 1; i + 1 < data.length; i += 2) {
      final num? value = num.tryParse(data[i + 1].toString());
      if (value != null) {
        metrics[data[i].toString()] = value;
      }
    }
    countly.report_trace({'type': 'device', 'name': traceKey, 'stz': startTime, 'etz': endTime, 'apm_metrics': metrics}.jsify()!);
  }

  /// Reports a finished network request.
  /// [List<dynamic> data] - the trace key, response code, request and response payload sizes, start and end time
  void _recordNetworkTrace(Countly countly, List<dynamic> data) {
    final int responseCode = int.tryParse(data[1].toString()) ?? 0;
    final int requestPayloadSize = int.tryParse(data[2].toString()) ?? 0;
    final int responsePayloadSize = int.tryParse(data[3].toString()) ?? 0;
    final int startTime = int.tryParse(data[4].toString()) ?? 0;
    final int endTime = int.tryParse(data[5].toString()) ?? 0;
    final Map<String, num> metrics = {
      'response_time': endTime - startTime,
      'response_code': responseCode,
      'request_payload_size': requestPayloadSize,
      'response_payload_size': responsePayloadSize,
    };
    countly.report_trace({'type': 'network', 'name': data[0] as String, 'stz': startTime, 'etz': endTime, 'apm_metrics': metrics}.jsify()!);
  }

  /// Reports a Countly campaign. The Web SDK takes the campaign ID and the user's click ID directly, the
  /// mobile SDKs take them as the "cid" and "cuid" fields of the campaign data.
  void _recordDirectAttribution(Countly countly, String campaignType, String campaignData) {
    if (campaignType != 'countly') {
      cly.Countly.log('[CountlyFlutterPluginWeb] recordDirectAttribution, only the "countly" campaign type is supported on web, got [$campaignType]', logLevel: cly.LogLevel.WARNING);
      return;
    }
    dynamic campaign;
    try {
      campaign = jsonDecode(campaignData);
    } catch (e) {
      campaign = null;
    }
    if (campaign is! Map || campaign['cid'] == null) {
      cly.Countly.log('[CountlyFlutterPluginWeb] recordDirectAttribution, campaignData has to be a JSON object with a "cid" field', logLevel: cly.LogLevel.WARNING);
      return;
    }
    countly.recordDirectAttribution(campaign['cid'].toString(), campaign['cuid']?.toString());
  }

  /// The widget the instance listed under the given ID, or an empty map when it listed none.
  Map<Object?, Object?> _findWidget(String instanceKey, String widgetId) {
    return _retrievedWidgetLists[instanceKey]?.firstWhere((element) => element['_id'] == widgetId, orElse: () => {}) ?? {};
  }

  Map<String, Object?> prepareCallbackData(String instanceKey, Object? data, String? error) {
    Map<String, Object?> returnedObject = {};
    returnedObject['instanceName'] = instanceKey;
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
  Future<void> _importLibrary() async {
    final head = querySelector('head');

    // try this as module
    final scriptTag = _createScriptTag(CountlyFlutterPluginConfig.WEB_SDK_URL);
    head?.children.add(scriptTag);
    await scriptTag.onLoad.first;

    return Future.value();
  }

  void _reportUserDetails(Countly countly, Map<String, dynamic> userData) {
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
      countly.user_details(bundle.jsify()!);
    }
  }

  void _userProfileOps(Countly countly, String method, List<dynamic> data) {
    if (method == 'userProfile_setProperties') {
      _reportUserDetails(countly, data[0]);
    } else if (method == 'userProfile_setProperty') {
      String keyName = data[0];
      Object keyValue = data[1];
      countly.userData.set(keyName, keyValue.jsify());
    } else if (method == 'userProfile_increment') {
      String keyName = data[0];
      countly.userData.increment(keyName);
    } else if (method == 'userProfile_incrementBy') {
      String key = data[0];
      int value = data[1];
      countly.userData.increment_by(key, value);
    } else if (method == 'userProfile_multiply') {
      String key = data[0];
      int value = data[1];
      countly.userData.multiply(key, value);
    } else if (method == 'userProfile_saveMax') {
      String key = data[0];
      int value = data[1];
      countly.userData.max(key, value);
    } else if (method == 'userProfile_saveMin') {
      String key = data[0];
      int value = data[1];
      countly.userData.min(key, value);
    } else if (method == 'userProfile_setOnce') {
      String key = data[0];
      Object value = data[1];
      countly.userData.set_once(key, value.jsify());
    } else if (method == 'userProfile_pushUnique') {
      String key = data[0];
      Object value = data[1];
      countly.userData.push_unique(key, value.jsify());
    } else if (method == 'userProfile_push') {
      String key = data[0];
      Object value = data[1];
      countly.userData.push(key, value.jsify());
    } else if (method == 'userProfile_pull') {
      String key = data[0];
      Object value = data[1];
      countly.userData.pull(key, value.jsify());
    } else if (method == 'userProfile_save') {
      countly.userData.save();
    } else {
      cly.Countly.log("The countly_flutter plugin for web doesn't implement the method $method", logLevel: cly.LogLevel.ERROR);
    }
  }

  void _userDataOps(Countly countly, String method, List<dynamic> data) {
    if (method == 'userData_setProperty') {
      String keyName = data[0];
      String keyValue = data[1];
      countly.userData.set(keyName, keyValue.jsify());
      countly.userData.save();
    } else if (method == 'userData_increment') {
      String keyName = data[0];
      countly.userData.increment(keyName);
      countly.userData.save();
    } else if (method == 'userData_incrementBy') {
      String keyName = data[0];
      int value = data[1];
      countly.userData.increment_by(keyName, value);
      countly.userData.save();
    } else if (method == 'userData_saveMax') {
      String keyName = data[0];
      int value = data[1];
      countly.userData.max(keyName, value);
      countly.userData.save();
    } else if (method == 'userData_saveMin') {
      String keyName = data[0];
      int value = data[1];
      countly.userData.min(keyName, value);
      countly.userData.save();
    } else if (method == 'userData_setOnce') {
      String keyName = data[0];
      String value = data[1];
      countly.userData.set_once(keyName, value.jsify());
      countly.userData.save();
    } else if (method == 'userData_pushUniqueValue') {
      String keyName = data[0];
      String value = data[1];
      countly.userData.push_unique(keyName, value.jsify());
      countly.userData.save();
    } else if (method == 'userData_pushValue') {
      String keyName = data[0];
      String value = data[1];
      countly.userData.push(keyName, value.jsify());
      countly.userData.save();
    } else if (method == 'userData_pullValue') {
      String keyName = data[0];
      String value = data[1];
      countly.userData.pull(keyName, value.jsify());
      countly.userData.save();
    } else {
      cly.Countly.log("The countly_flutter plugin for web doesn't implement the method $method", logLevel: cly.LogLevel.ERROR);
    }
  }

  void _recordEvent(Countly countly, List<dynamic> event) {
    assert(event.length >= 4);
    // first 4 parameters are sent always
    // ket, count, sum, dur, segmentation might be sent
    countly.add_event({'key': event[0], 'count': event[1], 'sum': event[2], 'dur': event[3], 'segmentation': event.length > 4 ? event[4] : null}.jsify()!);
  }

  void _endEvent(Countly countly, List<dynamic> event) {
    assert(event.length >= 3);
    // first parameter is key
    countly.end_event({'key': event[0], 'count': event[1], 'sum': event[2], 'segmentation': event.length > 3 ? event[3] : null}.jsify()!);
  }

  void _recordView(Countly countly, List<dynamic> view) {
    assert(view.isNotEmpty);
    // first parameter is view name
    String viewName = view[0];
    var segments = {};

    int il = view.length;
    if (il == 2) {
      segments = view[1];
    } else if (il > 2) {
      segments = _extractMap(view, idxStart: 1);
    }
    // ignore list and segmentation might be sent
    countly.track_pageview(viewName, null, segments.jsify()!);
  }

  String _getDeviceIDType(int type) {
    switch (type) {
      case 0: // DEVELOPER_SUPPLIED
        return 'DS';
      case 2: // TEMPORARY_ID
        return 'TID';
      default: // 1 and default are SDK_GENERATED
        return 'SG';
    }
  }

  Future<dynamic> _updateValuesRC(Countly countly, JSAny? included, JSAny? excluded) {
    final completer = Completer<dynamic>();
    countly.fetch_remote_config(
        included,
        excluded,
        allowInterop((JSAny? error, JSAny? remoteConfigs) {
          bool isError = error != null && error.dartify() as bool;
          if (error != null && (isError || error is! bool)) {
            completer.complete('Error: $error');
          } else {
            completer.complete('Success: ${remoteConfigs?.dartify()}');
          }
        }).jsify());
    return completer.future;
  }

  Map<String, dynamic> _extractMap(List<dynamic> data, {int idxStart = 0}) {
    Map<String, dynamic> map = {};
    for (int i = 0; i < data.length; i += 2) {
      map[data[i]] = data[i + 1];
    }
    return map;
  }

  Map<String, Map<String, dynamic>> _convertMapToRCData(dynamic rcData) {
    if (rcData == null) {
      return {};
    }
    Map<String, Map<String, dynamic>> data = {};
    rcData.forEach((key, value) {
      data[key] = {'value': value, 'isCurrentUsersData': true};
    });
    return data;
  }

  void _notifyRemoteConfigDownloadCallback(String instanceKey, JSAny? error, JSAny? remoteConfigs, bool fullValueUpdate, int id) {
    Map<String, dynamic> data = {};
    data['instanceName'] = instanceKey;
    dynamic errorDart = error?.dartify();
    data['error'] = errorDart is bool ? null : errorDart;
    data['requestResult'] = remoteConfigs != null ? 0 : 2;
    data['downloadedValues'] = _convertMapToRCData(remoteConfigs?.dartify());
    data['fullValueUpdate'] = fullValueUpdate;
    data['id'] = id;

    methodChannel?.invokeMethod('remoteConfigDownloadCallback', data);
  }

  void _initialize(String instanceKey, Map<String, dynamic> config) {
    if (_instances.containsKey(instanceKey)) {
      cly.Countly.log('[CountlyFlutterPluginWeb] init, the instance [$instanceKey] is already initialized', logLevel: cly.LogLevel.ERROR);
      return;
    }
    Map<String, dynamic> configMap = {
      'app_key': config['appKey'],
      'url': config['serverURL'],
      'sdk_name': CountlyFlutterPluginConfig.SDK_NAME,
      'sdk_version': CountlyFlutterPluginConfig.SDK_VERSION_STRING,
      'debug': config['loggingEnabled'],
      'session_update': config['sessionUpdateTimerDelay'],
      'max_events': config['eventQueueSizeThreshold'],
      'queue_size': config['maxRequestQueueSize'],
      'force_post': config['httpPostForced'] ?? false,
      'require_consent': config['shouldRequireConsent'],
      'salt': config['tamperingProtectionSalt'],
      'disable_sdk_behavior_settings_updates': config['sdkBehaviorSettingsUpdatesDisabled'] ?? false,
      'disable_backoff_mechanism': config['backoffMechanismDisabled'] ?? false,
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
      configMap['remote_config'] = allowInterop((JSAny? error, JSAny? remoteConfigs) => _notifyRemoteConfigDownloadCallback(instanceKey, error, remoteConfigs, true, requestIDGlobalCallback)).jsify();
    }

    configMap['behavior_settings'] = config['sdkBehaviorSettings'];
    configMap['disable_behavior_settings_updates'] = config['sdkBehaviorSettingsUpdatesDisabled'];

    configMap['headers'] = config['customNetworkRequestHeaders'];

    configMap.removeWhere((key, value) => value == null);

    if (config['disableLocation'] != null && config['disableLocation'] == true) {
      configMap['ip_address'] = null;
      configMap['country_code'] = null;
      configMap['city'] = null;
    }

    final Countly countly;
    if (instanceKey == _defaultInstanceKey) {
      // "init" registers the default with the Web SDK and copies its members onto the global object.
      countly = countlyGlobal.init(configMap.jsify()!);
    } else {
      // Named instances are namespaced by name, because the Web SDK keys its own registry by app key.
      configMap['namespace'] = instanceKey;
      countly = CountlyClass(configMap.jsify()!) as Countly;
    }
    _instances[instanceKey] = countly;

    if (config['manualSessionEnabled'] == null || config['manualSessionEnabled'] == false) {
      countly.track_sessions();
    }

    if (config['consents'] != null) {
      countly.add_consent(config['consents'].jsify()!);
    }

    // The Web SDK's window error hook lives on its own registry, which only knows the default instance.
    // Unhandled Dart errors still reach a named instance through the Dart side handlers.
    if (instanceKey != _defaultInstanceKey) {
      if (config['enableUnhandledCrashReporting'] != null || config['customCrashSegment'] != null) {
        cly.Countly.log('[CountlyFlutterPluginWeb] init, unhandled JavaScript error tracking is only available on the default instance', logLevel: cly.LogLevel.WARNING);
      }
    } else if (config['customCrashSegment'] != null) {
      countly.track_errors(config['customCrashSegment'].jsify());
    } else if (config['enableUnhandledCrashReporting'] != null) {
      countly.track_errors(null);
    }
  }
}
