import 'dart:async';
import 'dart:convert';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';
import 'dart:math';

import 'package:countly_flutter/countly_flutter.dart' as cly;
import 'package:countly_flutter/src/web/countly_sdk_web_interop.dart';
import 'package:countly_flutter/src/web/json_interop.dart';
import 'package:countly_flutter/src/web/plugin_config.dart';
import 'package:countly_flutter/src/web/web_apm.dart';
import 'package:countly_flutter/src/web/web_views.dart';
import 'package:flutter/services.dart';
import 'package:flutter_web_plugins/flutter_web_plugins.dart';

class CountlyFlutterPlugin {
  List<Map<Object?, Object?>> retrievedWidgetList = [];
  MethodChannel? methodChannel;

  static const int requestIDNoCallback = -1;
  static const int requestIDGlobalCallback = -2;

  /// How long init waits for the Web SDK script before it gives up on it.
  static const Duration scriptLoadTimeout = Duration(seconds: 10);

  /// How long init waits for the app's version.json before it initializes without an app version.
  static const Duration appVersionTimeout = Duration(seconds: 3);

  /// How long a call waits for a Web SDK callback. The Web SDK abandons a request after 30 seconds
  /// and drops the callback of a failed request, so this waits a little longer than that.
  static const Duration callbackTimeout = Duration(seconds: 35);

  /// The Web SDK instance init created, or null before init and when the script could not load.
  CountlyWeb? _countly;

  /// The script load shared by every init, so the script is added to the page at most once.
  Future<bool>? _scriptLoad;

  /// Segmentation added to every crash report.
  Map<String, dynamic> _customCrashSegment = {};

  /// Whether the config disabled location, which the Web SDK honours only while location consent is missing.
  bool _locationDisabled = false;

  /// Whether the config requires consent.
  bool _consentRequired = false;

  /// When the running manual session was last reported, in milliseconds since the epoch, or null when
  /// no manual session runs.
  int? _sessionReportedAt;

  /// The views this plugin started.
  WebViews _views = WebViews({});

  /// The performance traces of this plugin.
  WebApm _apm = WebApm(trackAppStartTime: false, manualAppLoadedTrigger: false);

  /// How many push notification events are kept while no "onNotification" registration waits.
  static const int maxPendingNotifications = 50;

  /// Waiting "onNotification" registrations. The Dart side registers again after every event, so an
  /// event that arrives in between is kept in [_pendingNotifications] for the next registration.
  final List<Completer<String>> _notificationWaiters = [];

  /// Push notification events no registration waited for yet, oldest first.
  final List<String> _pendingNotifications = [];

  /// Calls the Countly Web SDK has no equivalent for.
  static const Set<String> _unavailableOnWeb = {
    'pauseViewWithID',
    'resumeViewWithID',
    'addSegmentationToViewWithID',
    'addSegmentationToViewWithName',
    'previewContent',
    'remoteConfigClearAllValues',
    'remoteConfigExitABTestsForKeys',
    'remoteConfigTestingDownloadVariantInformation',
    'remoteConfigTestingEnrollIntoVariant',
    'remoteConfigTestingGetAllVariants',
    'remoteConfigTestingGetVariantsForKey',
    'testingDownloadExperimentInformation',
    'testingGetAllExperimentInfo',
    'removeDifferentAppKeysFromQueue',
    'replaceAllAppKeysInQueueWithCurrentAppKey',
    'recordIndirectAttribution',
    'recordMetrics',
    'pushTokenType',
    'askForStarRating',
  };

  /// The calls of [_unavailableOnWeb] whose Dart callback waits for an answer, with its ID first.
  static const Set<String> _variantCallbackMethods = {
    'remoteConfigTestingDownloadVariantInformation',
    'remoteConfigTestingEnrollIntoVariant',
    'testingDownloadExperimentInformation',
  };

  // Register the plugin with Flutter Web
  static void registerWith(Registrar registrar) {
    final MethodChannel channel = MethodChannel('countly_flutter', const StandardMethodCodec(), registrar);
    final CountlyFlutterPlugin instance = CountlyFlutterPlugin();
    instance.methodChannel = channel;
    channel.setMethodCallHandler(instance.handleMethodCall);
  }

  /// Handles a call from the Dart side. While there is no Web SDK instance, before init or when the
  /// script could not load, and when the Web SDK fails, calls get the answer of a failed call instead.
  Future<dynamic> handleMethodCall(MethodCall call) async {
    final List<dynamic> data = _arguments(call.arguments);
    try {
      if (call.method == 'init') {
        return await _initialize(data[0] as Map<String, dynamic>);
      }
      // Answered only when a notification arrives, as the Dart side registers again after every answer.
      if (call.method == 'registerForNotification') {
        return await _nextNotification();
      }
      final CountlyWeb? countly = _countly;
      if (countly == null) {
        const String reason = 'Countly is not initialized, or the Countly Web SDK could not be loaded';
        if (call.method != 'isInitialized') {
          cly.Countly.log('[CountlyFlutterPluginWeb] ${call.method}, $reason', logLevel: cly.LogLevel.WARNING);
        }
        return await _failedAnswer(call.method, data, reason);
      }
      return await _callSdk(countly, call, data);
    } on PlatformException {
      rethrow;
    } catch (e) {
      final String reason = 'The Countly Web SDK failed: $e';
      cly.Countly.log('[CountlyFlutterPluginWeb] ${call.method}, $reason', logLevel: cly.LogLevel.ERROR);
      return await _failedAnswer(call.method, data, reason);
    }
  }

  /// The argument list the Dart side sends as JSON under "data", or an empty list.
  List<dynamic> _arguments(Object? arguments) {
    if (arguments is Map && arguments['data'] is String) {
      return jsonDecode(arguments['data'] as String) as List<dynamic>;
    }
    return List.empty();
  }

  /// Runs [call] on the Web SDK instance [countly] and returns what the Dart side expects.
  Future<dynamic> _callSdk(CountlyWeb countly, MethodCall call, List<dynamic> data) async {
    // INIT RELATED
    if (call.method == 'isInitialized') {
      return 'true';
    }
    // EVENTS
    else if (call.method == 'recordEvent') {
      _recordEvent(countly, data);
    } else if (call.method == 'startEvent') {
      countly.start_event(data[0] as String);
    } else if (call.method == 'endEvent') {
      _endEvent(countly, data);
    } else if (call.method == 'cancelEvent') {
      countly.cancel_event(data[0] as String);
    }

    // SESSIONS
    else if (call.method == 'beginSession') {
      _beginSession(countly);
    } else if (call.method == 'updateSession') {
      _updateSession(countly);
    } else if (call.method == 'endSession') {
      _endSession(countly);
    }

    // DEVICE ID MANAGEMENT
    else if (call.method == 'getID') {
      return countly.get_device_id();
    } else if (call.method == 'setID') {
      countly.set_id(data[0] as String);
    } else if (call.method == 'getIDType') {
      return _getDeviceIDType(countly.get_device_id_type());
    } else if (call.method == 'changeWithMerge') {
      countly.change_id(data[0] as String, true);
    } else if (call.method == 'changeWithoutMerge') {
      _changeDeviceIdWithoutMerge(countly, data[0] as String);
    } else if (call.method == 'enableTemporaryIDMode') {
      countly.enable_offline_mode();
      // there is also disable offine mode call, but it is not needed for now
    }

    // CONSENT
    else if (call.method == 'giveConsent') {
      countly.add_consent(_consentsToGive(data));
    } else if (call.method == 'removeConsent') {
      countly.remove_consent(data.jsify()!);
    } else if (call.method == 'giveAllConsent') {
      countly.add_consent(_consentsToGive(_allFeatures()));
    } else if (call.method == 'removeAllConsent') {
      countly.remove_consent(countlyGlobal.features);
    }

    // VIEWS
    else if (call.method == 'startView' || call.method == 'startAutoStoppedView') {
      return _views.start(countly, data[0] as String, _mapAt(data, 1));
    } else if (call.method == 'stopViewWithName') {
      _views.stopWithName(countly, data[0] as String, _mapAt(data, 1));
    } else if (call.method == 'stopViewWithID') {
      _views.stopWithId(countly, data[0] as String, _mapAt(data, 1));
    } else if (call.method == 'stopAllViews') {
      _views.stopAll(countly, _mapAt(data, 0));
    } else if (call.method == 'setGlobalViewSegmentation') {
      _views.setGlobalSegmentation(_mapAt(data, 0));
    } else if (call.method == 'updateGlobalViewSegmentation') {
      _views.updateGlobalSegmentation(_mapAt(data, 0));
    }

    // PERFORMANCE MONITORING
    else if (call.method == 'startTrace') {
      _apm.startTrace(data[0] as String);
    } else if (call.method == 'endTrace') {
      _apm.endTrace(countly, data[0] as String, _intPairs(data, 1));
    } else if (call.method == 'cancelTrace') {
      _apm.cancelTrace(data[0] as String);
    } else if (call.method == 'clearAllTraces') {
      _apm.clearAllTraces();
    } else if (call.method == 'recordNetworkTrace') {
      _apm.recordNetworkTrace(countly, data[0] as String, _int(data[1]), _int(data[2]), _int(data[3]), _int(data[4]), _int(data[5]));
    } else if (call.method == 'appLoadingFinished') {
      _apm.appLoaded(countly);
    }

    // LOCATION
    else if (call.method == 'setUserLocation') {
      _setUserLocation(countly, data[0] as Map<String, dynamic>);
    } else if (call.method == 'disableLocation') {
      _disableLocation(countly);
    }

    // NETWORKING
    else if (call.method == 'addCustomNetworkRequestHeaders') {
      _addCustomNetworkRequestHeaders(countly, data[0] as Map<String, dynamic>);
    } else if (call.method == 'attemptToSendStoredRequests') {
      countly.attempt_to_send_stored_requests();
    }

    // ATTRIBUTION
    else if (call.method == 'recordDirectAttribution') {
      _recordDirectAttribution(countly, data[0] as String, data[1] as String);
    }

    // PUSH NOTIFICATIONS
    else if (call.method == 'askForNotificationPermission') {
      return await _pushCall(countly, 'enable_push_notifications', 'subscribed');
    } else if (call.method == 'disablePushNotifications') {
      return await _pushCall(countly, 'disable_push_notifications', 'unsubscribed');
    }

    // CRASHES
    else if (call.method == 'logException') {
      String exceptionString = data[0] as String;
      bool nonfatal = data[1] == 'true';

      Map<String, dynamic> segments = {..._customCrashSegment, ..._extractMap(data, idxStart: 2)};
      countly.recordError({'stack': exceptionString}.jsify()!, nonfatal, segments.isEmpty ? null : segments.jsify());
    } else if (call.method == 'addCrashLog') {
      countly.add_log(data[0] as String);
    } else if (call.method == 'throwNativeException') {
      _reportUncaughtError();
    }

    // INTERNALS
    else if (call.method == 'getRequestQueue') {
      return _stringifyAll(countly.internals.getRequestQueue());
    } else if (call.method == 'getEventQueue') {
      return _stringifyAll(countly.internals.getEventQueue());
    } else if (call.method == 'halt') {
      countly.halt();
      _apm.stop();
      _countly = null;
      _customCrashSegment = {};
      _locationDisabled = false;
      _consentRequired = false;
      _sessionReportedAt = null;
      _views = WebViews({});
      _apm = WebApm(trackAppStartTime: false, manualAppLoadedTrigger: false);
      _pendingNotifications.clear();
      retrievedWidgetList.clear();
    }

    // USER PROFILES
    else if (call.method == 'setuserdata') {
      _reportUserDetails(countly, data[0] as Map<String, dynamic>);
    } else if (call.method.startsWith('userData_')) {
      _userDataOps(countly.userData, call.method, data);
    } else if (call.method.startsWith('userProfile_')) {
      _userProfileOps(countly, call.method, data);
    }

    // FEEDBACK
    else if (call.method == 'presentNPS') {
      countly.feedback.showNPS(data[0] as String?);
    } else if (call.method == 'presentSurvey') {
      countly.feedback.showSurvey(data[0] as String?);
    } else if (call.method == 'presentRating') {
      countly.feedback.showRating(data[0] as String?);
    } else if (call.method == 'getAvailableFeedbackWidgets') {
      return _getAvailableFeedbackWidgets(countly);
    } else if (call.method == 'presentFeedbackWidget' || call.method == 'presentRatingWidgetWithID') {
      String widgetId = data[0] as String;
      Map<Object?, Object?>? widget = _retrievedWidget(widgetId);
      if (widget == null) {
        String message = '[CountlyFlutterPluginWeb] presentFeedbackWidget, ${_unknownWidgetMessage(widgetId)}';
        cly.Countly.log(message, logLevel: cly.LogLevel.ERROR);
        return message;
      }
      countly.present_feedback_widget(widget.jsify(), null, null, null);
    } else if (call.method == 'getFeedbackWidgetData') {
      return _getFeedbackWidgetData(countly, data[0] as String);
    } else if (call.method == 'reportFeedbackWidgetManually') {
      List<dynamic> widgetInfo = data[0] as List<dynamic>;
      Map<String, dynamic> widgetData = data[1] as Map<String, dynamic>;
      Map<String, dynamic>? widgetResult = data[2] as Map<String, dynamic>?;
      String widgetId = widgetInfo[0] as String;

      Map<Object?, Object?>? widget = _retrievedWidget(widgetId);
      if (widget == null) {
        String message = '[CountlyFlutterPluginWeb] reportFeedbackWidgetManually, ${_unknownWidgetMessage(widgetId)}';
        cly.Countly.log(message, logLevel: cly.LogLevel.ERROR);
        return message;
      }

      countly.reportFeedbackWidgetManually(widget.jsify(), widgetData.jsify(), widgetResult.jsify());
    }

    // REMOTE CONFIG
    else if (call.method == 'remoteConfigDownloadValues') {
      _downloadRemoteConfig(countly, null, null, true, data[0] as int);
    } else if (call.method == 'remoteConfigDownloadSpecificValue') {
      _downloadRemoteConfig(countly, (data[1] as List<dynamic>).jsify(), null, false, data[0] as int);
    } else if (call.method == 'remoteConfigDownloadOmittingValues') {
      _downloadRemoteConfig(countly, null, (data[1] as List<dynamic>).jsify(), false, data[0] as int);
    } else if (call.method == 'remoteConfigGetAllValues') {
      return _convertMapToRCData(_dartify(countly.get_remote_config()));
    } else if (call.method == 'remoteConfigGetValue') {
      String key = data[0] as String;
      return {'value': _dartify(countly.get_remote_config(key)), 'isCurrentUsersData': true};
    }

    // A/B TESTING
    else if (call.method == 'remoteConfigGetValueAndEnroll') {
      String key = data[0] as String;
      Object? value = _dartify(countly.get_remote_config(key));
      countly.enrollUserToAb([key].jsify());
      return {'value': value, 'isCurrentUsersData': true};
    } else if (call.method == 'remoteConfigGetAllValuesAndEnroll') {
      Map<String, Map<String, dynamic>> rcValues = _convertMapToRCData(_dartify(countly.get_remote_config()));
      if (rcValues.isNotEmpty) {
        countly.enrollUserToAb(rcValues.keys.toList().jsify());
      }
      return rcValues;
    } else if (call.method == 'remoteConfigEnrollIntoABTestsForKeys') {
      countly.enrollUserToAb((data[0] as List<dynamic>).jsify());
    }

    // CONTENT ZONE
    else if (call.method == 'enterContentZone') {
      countly.content.enterContentZone();
    } else if (call.method == 'refreshContentZone') {
      countly.content.refreshContentZone();
    } else if (call.method == 'exitContentZone') {
      countly.content.exitContentZone();
    } else if (_unavailableOnWeb.contains(call.method)) {
      return await _unavailableAnswer(call.method, data);
    } else {
      cly.Countly.log('[CountlyFlutterPluginWeb] handleMethodCall, The method ${call.method} does not implemented', logLevel: cly.LogLevel.ERROR);
    }
    return null;
  }

  /// The answer to [method] when it could not run for [reason]: an empty value of the type the Dart
  /// side expects, and [reason] as the error for the calls that report one.
  Future<dynamic> _failedAnswer(String method, List<dynamic> data, String reason) async {
    if (method == 'isInitialized') {
      return 'false';
    }
    if (method == 'init') {
      return reason;
    } else if (method == 'getIDType') {
      // The Dart side reads an unknown type as SDK generated.
      return '';
    } else if (method == 'getRequestQueue' || method == 'getEventQueue') {
      return <String>[];
    } else if (method == 'remoteConfigGetAllValues' || method == 'remoteConfigGetAllValuesAndEnroll') {
      return <String, Map<String, dynamic>>{};
    } else if (method == 'remoteConfigDownloadValues') {
      _notifyRemoteConfigDownload(2, reason, null, true, data[0] as int);
    } else if (method == 'remoteConfigDownloadSpecificValue' || method == 'remoteConfigDownloadOmittingValues') {
      _notifyRemoteConfigDownload(2, reason, null, false, data[0] as int);
    } else if (method == 'getAvailableFeedbackWidgets') {
      throw PlatformException(code: method, message: reason);
    } else if (method == 'getFeedbackWidgetData') {
      await methodChannel?.invokeMethod('feedbackWidgetDataCallback', prepareCallbackData(null, reason));
      throw PlatformException(code: method, message: reason);
    }
    return null;
  }

  Map<String, Object?> prepareCallbackData(Object? data, String? error) {
    Map<String, Object?> returnedObject = {};
    returnedObject['widgetData'] = data;
    if (error != null) {
      returnedObject['error'] = error;
    }

    return returnedObject;
  }

  /// Whether the page has the Web SDK's global Countly object with its init function.
  bool _isWebSDKLoaded() {
    final JSAny? countly = globalContext['Countly'];
    if (countly == null) {
      return false;
    }
    final JSAny? init = (countly as JSObject)['init'];
    return init != null && init.typeofEquals('function');
  }

  /// Adds the Web SDK script from [url] to the page and reports whether it loaded within
  /// [scriptLoadTimeout]. A page that already loaded the Web SDK itself keeps its copy.
  Future<bool> _loadScript(String url) {
    if (_isWebSDKLoaded()) {
      return Future<bool>.value(true);
    }
    final Completer<bool> completer = Completer<bool>();
    final JSObject document = globalContext['document'] as JSObject;
    final JSObject script = document.callMethod('createElement'.toJS, 'script'.toJS) as JSObject;
    script['async'] = true.toJS;
    script['src'] = url.toJS;
    script['onload'] = ((JSAny? event) {
      if (!completer.isCompleted) {
        completer.complete(_isWebSDKLoaded());
      }
    }).toJS;
    script['onerror'] = ((JSAny? event) {
      if (!completer.isCompleted) {
        completer.complete(false);
      }
    }).toJS;
    (document['head'] as JSObject).callMethod('appendChild'.toJS, script);
    return completer.future.timeout(scriptLoadTimeout, onTimeout: () => false);
  }

  /// The app version from the version.json file Flutter writes into a web build, or null when it
  /// cannot be read within [appVersionTimeout].
  Future<String?> _appVersion() async {
    try {
      return await _readAppVersion().timeout(appVersionTimeout);
    } catch (e) {
      cly.Countly.log('[CountlyFlutterPluginWeb] init, Could not read the app version from version.json: $e', logLevel: cly.LogLevel.WARNING);
      return null;
    }
  }

  /// Reads the version field of the version.json file next to the page.
  Future<String?> _readAppVersion() async {
    final JSPromise request = globalContext.callMethod('fetch'.toJS, 'version.json'.toJS, {'cache': 'no-cache'}.jsify()) as JSPromise;
    final JSObject response = await request.toDart as JSObject;
    if (response['ok']?.dartify() != true) {
      return null;
    }
    final JSAny? text = await (response.callMethod('text'.toJS) as JSPromise).toDart;
    final Object? versionFile = jsonDecode((text as JSString).toDart);
    if (versionFile is Map && versionFile['version'] is String && (versionFile['version'] as String).isNotEmpty) {
      return versionFile['version'] as String;
    }
    return null;
  }

  /// Sends [userData] as user details: the named properties as they are, every other key as a
  /// custom property.
  void _reportUserDetails(CountlyWeb countly, Map<String, dynamic> userData) {
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

  /// Runs the "userProfile_" call [method] with [data]. The changes are sent on its save call.
  void _userProfileOps(CountlyWeb countly, String method, List<dynamic> data) {
    CountlyWebUserData userData = countly.userData;
    if (method == 'userProfile_setProperties') {
      _reportUserDetails(countly, data[0] as Map<String, dynamic>);
    } else if (method == 'userProfile_setProperty') {
      String keyName = data[0] as String;
      Object? keyValue = data[1];
      userData.set(keyName, keyValue.jsify());
    } else if (method == 'userProfile_increment') {
      String keyName = data[0] as String;
      userData.increment(keyName);
    } else if (method == 'userProfile_incrementBy') {
      String key = data[0] as String;
      int value = data[1] as int;
      userData.increment_by(key, value);
    } else if (method == 'userProfile_multiply') {
      String key = data[0] as String;
      int value = data[1] as int;
      userData.multiply(key, value);
    } else if (method == 'userProfile_saveMax') {
      String key = data[0] as String;
      int value = data[1] as int;
      userData.max(key, value);
    } else if (method == 'userProfile_saveMin') {
      String key = data[0] as String;
      int value = data[1] as int;
      userData.min(key, value);
    } else if (method == 'userProfile_setOnce') {
      String key = data[0] as String;
      Object? value = data[1];
      userData.set_once(key, value.jsify());
    } else if (method == 'userProfile_pushUnique') {
      String key = data[0] as String;
      Object? value = data[1];
      userData.push_unique(key, value.jsify());
    } else if (method == 'userProfile_push') {
      String key = data[0] as String;
      Object? value = data[1];
      userData.push(key, value.jsify());
    } else if (method == 'userProfile_pull') {
      String key = data[0] as String;
      Object? value = data[1];
      userData.pull(key, value.jsify());
    } else if (method == 'userProfile_save') {
      userData.save();
    } else {
      cly.Countly.log("The countly_flutter plugin for web doesn't implement the method $method", logLevel: cly.LogLevel.ERROR);
    }
  }

  /// Runs the deprecated "userData_" call [method] with [data] and sends the change at once.
  void _userDataOps(CountlyWebUserData userData, String method, List<dynamic> data) {
    if (method == 'userData_setProperty') {
      String keyName = data[0] as String;
      Object? keyValue = data[1];
      userData.set(keyName, keyValue.jsify());
      userData.save();
    } else if (method == 'userData_increment') {
      String keyName = data[0] as String;
      userData.increment(keyName);
      userData.save();
    } else if (method == 'userData_incrementBy') {
      String keyName = data[0] as String;
      int value = data[1] as int;
      userData.increment_by(keyName, value);
      userData.save();
    } else if (method == 'userData_saveMax') {
      String keyName = data[0] as String;
      int value = data[1] as int;
      userData.max(keyName, value);
      userData.save();
    } else if (method == 'userData_saveMin') {
      String keyName = data[0] as String;
      int value = data[1] as int;
      userData.min(keyName, value);
      userData.save();
    } else if (method == 'userData_setOnce') {
      String keyName = data[0] as String;
      Object? value = data[1];
      userData.set_once(keyName, value.jsify());
      userData.save();
    } else if (method == 'userData_pushUniqueValue') {
      String keyName = data[0] as String;
      Object? value = data[1];
      userData.push_unique(keyName, value.jsify());
      userData.save();
    } else if (method == 'userData_pushValue') {
      String keyName = data[0] as String;
      Object? value = data[1];
      userData.push(keyName, value.jsify());
      userData.save();
    } else if (method == 'userData_pullValue') {
      String keyName = data[0] as String;
      Object? value = data[1];
      userData.pull(keyName, value.jsify());
      userData.save();
    } else {
      cly.Countly.log("The countly_flutter plugin for web doesn't implement the method $method", logLevel: cly.LogLevel.ERROR);
    }
  }

  /// Records the event the Dart side sends as key, count, sum, duration and segmentation. The numbers
  /// arrive as strings and are sent as numbers, as the native SDKs send them.
  void _recordEvent(CountlyWeb countly, List<dynamic> event) {
    assert(event.length >= 4);
    countly.add_event({'key': event[0], 'count': _number(event[1]), 'sum': _number(event[2]), 'dur': _number(event[3]), 'segmentation': event.length > 4 ? event[4] : null}.jsify()!);
  }

  /// Ends the timed event the Dart side sends as key, count, sum and segmentation.
  void _endEvent(CountlyWeb countly, List<dynamic> event) {
    assert(event.length >= 3);
    countly.end_event({'key': event[0], 'count': _number(event[1]), 'sum': _number(event[2]), 'segmentation': event.length > 3 ? event[3] : null}.jsify()!);
  }

  /// [value] as a number, parsing it when the Dart side sent it as a string, or null when it is none.
  num? _number(Object? value) {
    if (value is num) {
      return value;
    }
    if (value is String) {
      return num.tryParse(value);
    }
    return null;
  }

  /// [value] as a whole number, or 0 when it is none.
  int _int(Object? value) {
    return _number(value)?.toInt() ?? 0;
  }

  /// [value] as a map, or an empty map when it is none.
  Map<String, dynamic> _asMap(Object? value) {
    if (value is Map) {
      return Map<String, dynamic>.from(value);
    }
    return {};
  }

  /// The map at [index] of [data], or an empty map when there is none.
  Map<String, dynamic> _mapAt(List<dynamic> data, int index) {
    if (index < data.length) {
      return _asMap(data[index]);
    }
    return {};
  }

  /// The name and number pairs that follow [start] in [data], skipping values that are no number.
  Map<String, int> _intPairs(List<dynamic> data, int start) {
    final Map<String, int> pairs = {};
    for (int i = start; i + 1 < data.length; i += 2) {
      final num? value = _number(data[i + 1]);
      if (value != null) {
        pairs['${data[i]}'] = value.toInt();
      }
    }
    return pairs;
  }

  /// Begins a manual session. Without a heartbeat the Web SDK does not extend the session on its own,
  /// and forcing it starts a session even while the session cookie of an earlier page load is valid.
  void _beginSession(CountlyWeb countly) {
    countly.begin_session(true, true);
    _sessionReportedAt = DateTime.now().millisecondsSinceEpoch;
  }

  /// Reports the seconds of the manual session since it began or was last reported.
  void _updateSession(CountlyWeb countly) {
    final int? reportedAt = _sessionReportedAt;
    if (reportedAt == null) {
      cly.Countly.log('[CountlyFlutterPluginWeb] updateSession, No session was begun', logLevel: cly.LogLevel.WARNING);
      return;
    }
    final int now = DateTime.now().millisecondsSinceEpoch;
    countly.session_duration(((now - reportedAt) / 1000).round());
    _sessionReportedAt = now;
  }

  /// Ends the manual session with the seconds since it was last reported. The session cookie would
  /// otherwise turn the end into a session update.
  void _endSession(CountlyWeb countly) {
    final int? reportedAt = _sessionReportedAt;
    _sessionReportedAt = null;
    int seconds = 1;
    if (reportedAt != null) {
      // The Web SDK reads 0 as "measure it" and would count the seconds since the session began again.
      seconds = max(1, ((DateTime.now().millisecondsSinceEpoch - reportedAt) / 1000).round());
    }
    countly.end_session(seconds, true);
  }

  /// Changes the device ID without merging. The Web SDK ends the running session itself and counts it
  /// from its start, which includes the time manual updates already reported. So a running manual
  /// session is ended here first, and begun again for the new device ID, as the native SDKs keep it.
  void _changeDeviceIdWithoutMerge(CountlyWeb countly, String deviceId) {
    final bool manualSessionRunning = _sessionReportedAt != null;
    if (manualSessionRunning) {
      _endSession(countly);
    }
    countly.change_id(deviceId, false);
    if (manualSessionRunning) {
      _beginSession(countly);
    }
  }

  /// Sets the location sent with every request from now on, which also takes back [_disableLocation].
  /// The Web SDK has no GPS coordinates.
  void _setUserLocation(CountlyWeb countly, Map<String, dynamic> location) {
    if (location['gpsCoordinates'] != null) {
      cly.Countly.log('[CountlyFlutterPluginWeb] setUserLocation, GPS coordinates are not sent on web, only the country code, city and IP address', logLevel: cly.LogLevel.WARNING);
    }
    countly.country_code = (location['countryCode'] as String?)?.toJS;
    countly.city = (location['city'] as String?)?.toJS;
    countly.ip_address = (location['ipAddress'] as String?)?.toJS;
    _locationDisabled = false;
  }

  /// Stops sending location. The Web SDK leaves location to the server's IP lookup unless its
  /// "location" consent is missing, so this takes that consent back in consent mode.
  void _disableLocation(CountlyWeb countly) {
    countly.country_code = null;
    countly.city = null;
    countly.ip_address = null;
    _locationDisabled = true;
    if (_consentRequired) {
      countly.remove_consent(['location'].jsify()!);
    } else {
      cly.Countly.log('[CountlyFlutterPluginWeb] disableLocation, Location can be disabled on web only when consent is required, so the server still looks it up from the IP address', logLevel: cly.LogLevel.WARNING);
    }
  }

  /// Adds [headers] to the headers sent with every request, replacing values with the same name.
  void _addCustomNetworkRequestHeaders(CountlyWeb countly, Map<String, dynamic> headers) {
    final Map<String, dynamic> merged = {};
    final Object? current = _dartify(countly.headers);
    if (current is Map) {
      current.forEach((Object? name, Object? value) => merged['$name'] = value);
    }
    merged.addAll(headers);
    countly.headers = merged.jsify();
  }

  /// Records a direct attribution. Like the native SDKs, only the "countly" campaign type is
  /// supported, with data like {"cid": "campaign ID", "cuid": "campaign user ID"}.
  void _recordDirectAttribution(CountlyWeb countly, String campaignType, String campaignData) {
    if (campaignType != 'countly') {
      cly.Countly.log('[CountlyFlutterPluginWeb] recordDirectAttribution, Only the "countly" campaign type is supported, not [$campaignType]', logLevel: cly.LogLevel.WARNING);
      return;
    }
    Object? data;
    try {
      data = jsonDecode(campaignData);
    } on FormatException {
      data = null;
    }
    if (data is! Map || data['cid'] is! String || (data['cid'] as String).isEmpty) {
      cly.Countly.log('[CountlyFlutterPluginWeb] recordDirectAttribution, The campaign data must be a JSON object with a non-empty "cid"', logLevel: cly.LogLevel.ERROR);
      return;
    }
    final String campaignId = data['cid'] as String;
    final Object? campaignUserId = data['cuid'];
    if (campaignUserId is String && campaignUserId.isNotEmpty) {
      countly.recordDirectAttribution(campaignId, campaignUserId);
    } else {
      countly.recordDirectAttribution(campaignId);
    }
  }

  /// Runs the Web SDK push call [function] and describes how it ended, as "[key]: success" or
  /// "[key]: failed, reason: <reason>". A Web SDK without web push answers with "unsupported".
  Future<String> _pushCall(CountlyWeb countly, String function, String key) async {
    final JSObject instance = countly as JSObject;
    final JSAny? callable = instance[function];
    if (callable == null || !callable.typeofEquals('function')) {
      cly.Countly.log('[CountlyFlutterPluginWeb] Web push needs Countly Web SDK 26.8.0 or newer', logLevel: cly.LogLevel.WARNING);
      return '$key: failed, reason: unsupported';
    }
    Object? settled;
    try {
      final JSPromise promise = instance.callMethod(function.toJS) as JSPromise;
      settled = _dartify(await promise.toDart);
    } catch (e) {
      cly.Countly.log('[CountlyFlutterPluginWeb] $function, $e', logLevel: cly.LogLevel.ERROR);
      return '$key: failed, reason: error';
    }
    if (settled is Map && settled[key] == true) {
      return '$key: success';
    }
    final Object? reason = settled is Map ? settled['reason'] : null;
    return '$key: failed, reason: ${reason ?? 'unknown'}';
  }

  /// The next push notification event as a JSON string, for an "onNotification" registration.
  Future<String> _nextNotification() {
    if (_pendingNotifications.isNotEmpty) {
      return Future<String>.value(_pendingNotifications.removeAt(0));
    }
    final Completer<String> waiter = Completer<String>();
    _notificationWaiters.add(waiter);
    return waiter.future;
  }

  /// Hands a push notification event of the Web SDK to the waiting "onNotification" registrations,
  /// or keeps it for the next one, dropping the oldest beyond [maxPendingNotifications].
  void _onPushNotification(JSAny? event) {
    final String notification;
    try {
      notification = jsonEncode(_dartify(event));
    } catch (e) {
      cly.Countly.log('[CountlyFlutterPluginWeb] A push notification event could not be read: $e', logLevel: cly.LogLevel.ERROR);
      return;
    }
    if (_notificationWaiters.isEmpty) {
      if (_pendingNotifications.length >= maxPendingNotifications) {
        _pendingNotifications.removeAt(0);
      }
      _pendingNotifications.add(notification);
      return;
    }
    final List<Completer<String>> waiters = List<Completer<String>>.of(_notificationWaiters);
    _notificationWaiters.clear();
    for (final Completer<String> waiter in waiters) {
      waiter.complete(notification);
    }
  }

  /// Reports an uncaught JavaScript error to the page the way the browser does, so that unhandled
  /// crash reporting records it as a fatal crash with its message.
  void _reportUncaughtError() {
    const String message = 'A test crash requested through Countly.throwNativeException';
    final JSObject error = (globalContext['Error'] as JSFunction).callAsConstructor<JSObject>(message.toJS);
    final JSObject details = JSObject();
    details['error'] = error;
    details['message'] = message.toJS;
    final JSObject event = (globalContext['ErrorEvent'] as JSFunction).callAsConstructor<JSObject>('error'.toJS, details);
    globalContext.callMethod('dispatchEvent'.toJS, event);
  }

  /// The answer to a call the Web SDK has no equivalent for. A Dart callback waiting for it learns
  /// that it failed.
  Future<dynamic> _unavailableAnswer(String method, List<dynamic> data) async {
    final String reason = '$method is not available on web, the Countly Web SDK has no equivalent';
    cly.Countly.log('[CountlyFlutterPluginWeb] $reason', logLevel: cly.LogLevel.WARNING);
    if (_variantCallbackMethods.contains(method) && data.isNotEmpty) {
      await methodChannel?.invokeMethod('remoteConfigVariantCallback', {'requestResult': 2, 'error': reason, 'id': data[0]});
    }
    return null;
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

  /// Whether [countly] runs with a temporary device ID, in which the Web SDK skips feedback widget
  /// requests without calling back.
  bool _isTemporaryIdMode(CountlyWeb countly) {
    return countly.get_device_id_type() == 2;
  }

  /// The error for feedback widget requests in temporary device ID mode.
  static const String _temporaryIdMessage = 'Feedback widgets are not available in temporary device ID mode';

  /// The error for a widget ID that is not in the last widget list.
  String _unknownWidgetMessage(String widgetId) {
    return "No feedbackWidget is found against widget id: '$widgetId', always call 'getFeedbackWidgets' to get updated list of feedback widgets.";
  }

  /// The message for a call the Web SDK did not answer within [callbackTimeout].
  String get _noResponseMessage => 'The Countly Web SDK did not respond within ${callbackTimeout.inSeconds} seconds';

  /// Starts a Web SDK call through [start], which passes the given callback on to the Web SDK, and
  /// returns the first two arguments of that callback, or null when it did not come within
  /// [callbackTimeout].
  Future<List<JSAny?>?> _waitForCallback(void Function(JSFunction callback) start) {
    final Completer<List<JSAny?>?> completer = Completer<List<JSAny?>?>();
    start(((JSAny? first, JSAny? second) {
      if (!completer.isCompleted) {
        completer.complete(<JSAny?>[first, second]);
      }
    }).toJS);
    return completer.future.timeout(callbackTimeout, onTimeout: () => null);
  }

  /// The message of an error the Web SDK passed to a callback, or null when there was none. The Web
  /// SDK passes false or nothing on success, true for a failed request, and otherwise an Error
  /// object or a string.
  String? _errorMessage(JSAny? error) {
    if (error == null) {
      return null;
    }
    if (error.typeofEquals('boolean')) {
      if ((error as JSBoolean).toDart) {
        return 'The request failed';
      }
      return null;
    }
    if (error.typeofEquals('string')) {
      return (error as JSString).toDart;
    }
    if (error.typeofEquals('object')) {
      final JSAny? message = (error as JSObject)['message'];
      if (message != null && message.typeofEquals('string')) {
        return (message as JSString).toDart;
      }
    }
    return 'Unknown error';
  }

  /// The widget with [widgetId] from the last widget list, or null when the list does not have it.
  Map<Object?, Object?>? _retrievedWidget(String widgetId) {
    for (final Map<Object?, Object?> widget in retrievedWidgetList) {
      if (widget['_id'] == widgetId) {
        return widget;
      }
    }
    return null;
  }

  /// Fetches the available feedback widgets and keeps them for the calls that take a widget ID.
  /// Throws a [PlatformException] when the list cannot be fetched.
  Future<List<Map<String, String>>> _getAvailableFeedbackWidgets(CountlyWeb countly) async {
    retrievedWidgetList.clear();
    String? error;
    List<JSAny?>? reply;
    if (_isTemporaryIdMode(countly)) {
      error = _temporaryIdMessage;
    } else {
      reply = await _waitForCallback((JSFunction callback) => countly.get_available_feedback_widgets(callback));
      error = reply == null ? _noResponseMessage : _errorMessage(reply[1]);
    }
    if (error != null) {
      cly.Countly.log('[CountlyFlutterPluginWeb] getAvailableFeedbackWidgets, $error', logLevel: cly.LogLevel.ERROR);
      throw PlatformException(code: 'getAvailableFeedbackWidgets', message: error);
    }

    List<Map<String, String>> dartFeedbackWidgets = [];
    Object? widgets = _dartify(reply?[0]);
    if (widgets is List) {
      for (final Object? widget in widgets) {
        if (widget is Map) {
          retrievedWidgetList.add(widget);
          dartFeedbackWidgets.add({
            'id': '${widget['_id']}',
            'type': '${widget['type']}',
            'name': '${widget['name']}',
          });
        }
      }
    }
    return dartFeedbackWidgets;
  }

  /// Fetches the data of a widget from the last widget list, passes it to the Dart callback and
  /// returns it. Throws a [PlatformException] with the reason when there is no data.
  Future<Map<dynamic, dynamic>> _getFeedbackWidgetData(CountlyWeb countly, String widgetId) async {
    Map<Object?, Object?>? widget = _retrievedWidget(widgetId);
    String? error;
    Object? widgetData;
    if (widget == null) {
      error = _unknownWidgetMessage(widgetId);
    } else if (_isTemporaryIdMode(countly)) {
      error = _temporaryIdMessage;
    } else {
      List<JSAny?>? reply = await _waitForCallback((JSFunction callback) => countly.getFeedbackWidgetData(widget.jsify(), callback));
      error = reply == null ? _noResponseMessage : _errorMessage(reply[1]);
      widgetData = _dartify(reply?[0]);
    }

    if (error == null && widgetData is Map) {
      await methodChannel?.invokeMethod('feedbackWidgetDataCallback', prepareCallbackData(widgetData, null));
      return widgetData;
    }
    error ??= 'The server sent no widget data';
    cly.Countly.log('[CountlyFlutterPluginWeb] getFeedbackWidgetData, $error', logLevel: cly.LogLevel.ERROR);
    await methodChannel?.invokeMethod('feedbackWidgetDataCallback', prepareCallbackData(null, error));
    throw PlatformException(code: 'getFeedbackWidgetData', message: error);
  }

  /// Downloads remote config values and reports the result to the Dart side once. A download the
  /// Web SDK does not answer, which it does not do when the request fails, is reported as a
  /// network issue.
  void _downloadRemoteConfig(CountlyWeb countly, JSAny? keys, JSAny? omitKeys, bool fullValueUpdate, int requestID) {
    _waitForCallback((JSFunction callback) => countly.fetch_remote_config(keys, omitKeys, callback)).then((List<JSAny?>? reply) {
      if (reply == null) {
        _notifyRemoteConfigDownload(1, _noResponseMessage, null, fullValueUpdate, requestID);
      } else {
        _notifyRemoteConfigResult(reply[0], reply[1], fullValueUpdate, requestID);
      }
    });
  }

  Map<String, dynamic> _extractMap(List<dynamic> data, {int idxStart = 0}) {
    Map<String, dynamic> map = {};
    for (int i = idxStart; i + 1 < data.length; i += 2) {
      map[data[i] as String] = data[i + 1];
    }
    return map;
  }

  /// Each item of [items] as a JSON string.
  List<String> _stringifyAll(JSArray items) {
    List<String> strings = [];
    for (final JSAny? item in items.toDart) {
      strings.add(JSON.stringify(item));
    }
    return strings;
  }

  /// [rcData], the remote config values the Web SDK keeps, in the form the Dart side reads: each key
  /// mapped to its value and whether it belongs to the current user.
  Map<String, Map<String, dynamic>> _convertMapToRCData(Object? rcData) {
    Map<String, Map<String, dynamic>> data = {};
    if (rcData is Map) {
      rcData.forEach((key, value) {
        data['$key'] = {'value': value, 'isCurrentUsersData': true};
      });
    }
    return data;
  }

  /// Reports the arguments of a Web SDK remote config callback to the Dart side.
  void _notifyRemoteConfigResult(JSAny? error, JSAny? remoteConfigs, bool fullValueUpdate, int id) {
    String? message = _errorMessage(error);
    if (message != null) {
      _notifyRemoteConfigDownload(2, message, null, fullValueUpdate, id);
      return;
    }
    _notifyRemoteConfigDownload(0, null, remoteConfigs, fullValueUpdate, id);
  }

  /// Reports a remote config download to the Dart side, unless the download has no callback.
  void _notifyRemoteConfigDownload(int requestResult, String? error, JSAny? remoteConfigs, bool fullValueUpdate, int id) {
    if (id == requestIDNoCallback) {
      return;
    }
    Map<String, dynamic> data = {};
    data['error'] = error;
    data['requestResult'] = requestResult;
    data['downloadedValues'] = _convertMapToRCData(_dartify(remoteConfigs));
    data['fullValueUpdate'] = fullValueUpdate;
    data['id'] = id;

    methodChannel?.invokeMethod('remoteConfigDownloadCallback', data);
  }

  /// The SDK behavior settings JSON from the Dart config as the object the Web SDK takes, or null
  /// when it is missing or not a JSON object.
  Map<String, dynamic>? _behaviorSettings(Object? settings) {
    if (settings is! String) {
      return null;
    }
    try {
      Object? decoded = jsonDecode(settings);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
    } on FormatException catch (e) {
      cly.Countly.log('[CountlyFlutterPluginWeb] init, The SDK behavior settings are not valid JSON: $e', logLevel: cly.LogLevel.ERROR);
    }
    return null;
  }

  /// The Web SDK init config for the Dart [config].
  Map<String, dynamic> _webConfig(Map<String, dynamic> config, String? appVersion) {
    Map<String, dynamic> configMap = {
      'app_key': config['appKey'],
      'url': config['serverURL'],
      'app_version': appVersion,
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
    if (config['locationDisabled'] != true) {
      configMap['ip_address'] = config['locationIpAddress'];
      configMap['country_code'] = config['locationCountryCode'];
      configMap['city'] = config['locationCity'];
    }

    // Remote Config
    configMap['rc_automatic_optin_for_ab'] = config['autoEnrollABOnDownload'] ?? false;
    configMap['use_explicit_rc_api'] = true;

    configMap['behavior_settings'] = _behaviorSettings(config['sdkBehaviorSettings']);

    configMap['headers'] = config['customNetworkRequestHeaders'];

    // Content
    configMap['content_zone_timer_interval'] = config['zoneTimerInterval'];

    // Push options only with a VAPID key, so an app without web push gets no service worker scope.
    if (config['vapidPublicKey'] != null) {
      configMap['push_vapid_public_key'] = config['vapidPublicKey'];
      configMap['push_service_worker_path'] = config['pushServiceWorkerPath'];
      configMap['push_service_worker_scope'] = config['pushServiceWorkerScope'];
      configMap['push_subscribe_timeout'] = config['pushSubscribeTimeout'];
      if (config['pushAutomaticRegistrationDisabled'] == true) {
        configMap['push_auto_register'] = false;
      }
    }

    configMap.removeWhere((key, value) => value == null);
    return configMap;
  }

  /// Every feature the Web SDK takes consent for.
  List<Object?> _allFeatures() {
    return countlyGlobal.features.dartify() as List<Object?>;
  }

  /// [consents] in the form the Web SDK takes, without "location" while location is disabled, so that
  /// giving consent cannot turn location tracking back on.
  JSAny _consentsToGive(List<Object?> consents) {
    if (!_locationDisabled) {
      return consents.jsify()!;
    }
    return consents.where((Object? consent) => consent != 'location').toList().jsify()!;
  }

  /// [value] converted to Dart, with whole numbers as ints. WebAssembly builds turn every JavaScript
  /// number into a double, while JavaScript builds and the native platforms keep whole numbers as ints.
  Object? _dartify(JSAny? value) {
    return _wholeNumbersAsInts(value?.dartify());
  }

  /// [value] with every whole double in it, nested ones included, turned into an int.
  Object? _wholeNumbersAsInts(Object? value) {
    if (value is double && value.isFinite && value == value.truncateToDouble()) {
      return value.toInt();
    }
    if (value is List) {
      return value.map(_wholeNumbersAsInts).toList();
    }
    if (value is Map) {
      return value.map((Object? key, Object? item) => MapEntry(key, _wholeNumbersAsInts(item)));
    }
    return value;
  }

  /// Loads the Web SDK, creates this plugin's instance from the Dart [config] and applies the
  /// settings the Web SDK takes after init. Returns an error message when there is no instance.
  Future<String?> _initialize(Map<String, dynamic> config) async {
    if (_countly != null) {
      return null;
    }
    String scriptUrl = config['webSDKUrl'] as String? ?? CountlyFlutterPluginConfig.WEB_SDK_URL;
    Future<String?> appVersion = _appVersion();
    Future<bool> scriptLoad = _scriptLoad ??= _loadScript(scriptUrl);
    if (!await scriptLoad) {
      // A later init can try again, for example with a self-hosted address.
      _scriptLoad = null;
      String message = 'init, The Countly Web SDK could not be loaded from $scriptUrl, so Countly calls do nothing on this page';
      cly.Countly.log('[CountlyFlutterPluginWeb] $message', logLevel: cly.LogLevel.ERROR);
      return message;
    }
    Map<String, dynamic> configMap = _webConfig(config, await appVersion);
    if (_countly != null) {
      // Another init call completed while this one waited for the script.
      return null;
    }

    JSObject webConfig = configMap.jsify()! as JSObject;
    if (config['remoteConfigAutomaticTriggers'] == true) {
      webConfig['remote_config'] = ((JSAny? error, JSAny? remoteConfigs) {
        _notifyRemoteConfigResult(error, remoteConfigs, true, requestIDGlobalCallback);
      }).toJS;
    }
    // Given at init, so that a click the service worker replays when the page loads is not missed.
    if (config['vapidPublicKey'] != null) {
      webConfig['push_notification_listener'] = ((JSAny? event) {
        _onPushNotification(event);
      }).toJS;
    }
    CountlyWeb? countly = countlyGlobal.init(webConfig);
    if (countly == null) {
      String message = 'init, The Countly Web SDK did not create an instance';
      cly.Countly.log('[CountlyFlutterPluginWeb] $message', logLevel: cly.LogLevel.ERROR);
      return message;
    }
    _countly = countly;
    _locationDisabled = config['locationDisabled'] == true;
    _consentRequired = config['shouldRequireConsent'] == true;
    _views = WebViews(_asMap(config['globalViewSegmentation']));
    _apm = WebApm(
      trackAppStartTime: config['trackAppStartTime'] == true,
      manualAppLoadedTrigger: config['enableManualAppLoaded'] == true,
      appStartOverride: _number(config['startTSOverride'])?.toInt(),
    );

    if (config['manualSessionEnabled'] == null || config['manualSessionEnabled'] == false) {
      countly.track_sessions();
    }

    if (config['consents'] != null) {
      countly.add_consent(_consentsToGive(config['consents'] as List<dynamic>));
    }
    if (config['enableAllConsents'] == true) {
      countly.add_consent(_consentsToGive(_allFeatures()));
    }
    if (_locationDisabled && config['shouldRequireConsent'] != true) {
      cly.Countly.log('[CountlyFlutterPluginWeb] init, "disableLocation" takes effect on web only when consent is required', logLevel: cly.LogLevel.WARNING);
    }

    Object? customCrashSegment = config['customCrashSegment'];
    if (customCrashSegment is Map<String, dynamic>) {
      _customCrashSegment = customCrashSegment;
    }
    if (config['enableUnhandledCrashReporting'] == true) {
      countly.track_errors(_customCrashSegment.isEmpty ? null : _customCrashSegment.jsify());
    }

    final Map<String, dynamic> userProperties = _asMap(config['providedUserProperties']);
    if (userProperties.isNotEmpty) {
      _reportUserDetails(countly, userProperties);
    }
    final Object? campaignType = config['campaignType'];
    final Object? campaignData = config['campaignData'];
    if (campaignType is String && campaignData is String) {
      _recordDirectAttribution(countly, campaignType, campaignData);
    }

    _apm.recordAutomaticAppStart(countly);
    if (config['enableForegroundBackground'] == true) {
      _apm.startForegroundBackgroundTracking(countly);
    }
    return null;
  }
}
