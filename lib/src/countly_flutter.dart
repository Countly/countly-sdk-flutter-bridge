import 'dart:async';
import 'dart:convert';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:pedantic/pedantic.dart';

import 'content_builder.dart';
import 'content_builder_internal.dart';
import 'countly_config.dart';
import 'countly_state.dart';
import 'device_id.dart';
import 'device_id_internal.dart';
import 'feedback.dart';
import 'feedback_internal.dart';
import 'remote_config.dart';
import 'remote_config_internal.dart';
import 'sessions.dart';
import 'sessions_internal.dart';
import 'user_profile.dart';
import 'user_profile_internal.dart';
import 'views.dart';
import 'views_internal.dart';

/// Attribution Keys to record indirect attribution
/// IDFA is for iOS and AdvertisingID is for Android
abstract class AttributionKey {
  /// For iOS IDFA
  /// ignore: non_constant_identifier_names
  static String IDFA = 'idfa';

  /// For Android advertising ID
  /// ignore: non_constant_identifier_names
  static String AdvertisingID = 'adid';
}

// ignore: constant_identifier_names
enum LogLevel { INFO, DEBUG, VERBOSE, WARNING, ERROR }

// ignore: constant_identifier_names
enum DeviceIdType { DEVELOPER_SUPPLIED, SDK_GENERATED, TEMPORARY_ID }

abstract class CountlyConsent {
  static const String sessions = 'sessions';
  static const String events = 'events';
  static const String views = 'views';
  static const String location = 'location';
  static const String crashes = 'crashes';
  static const String attribution = 'attribution';
  static const String users = 'users';
  static const String push = 'push';
  static const String starRating = 'star-rating';
  static const String apm = 'apm';
  static const String feedback = 'feedback';
  static const String remoteConfig = 'remote-config';
  static const String content = 'content';
}

class Countly {
  Countly._() {
    _countlyState = CountlyState(this);
    _deviceIdInternal = DeviceIDInternal(_countlyState);
    _remoteConfigInternal = RemoteConfigInternal(_countlyState);
    _userProfileInternal = UserProfileInternal(_countlyState);
    _viewsInternal = ViewsInternal(_countlyState);
    _sessionsInternal = SessionsInternal(_countlyState);
    _contentBuilderInternal = ContentBuilderInternal(_countlyState);
    _feedbackInternal = FeedbackInternal(_countlyState);
  }
  static final instance = _instance;
  static final _instance = Countly._();

  late final CountlyState _countlyState;

  late final RemoteConfigInternal _remoteConfigInternal;
  RemoteConfig get remoteConfig => _remoteConfigInternal;

  late final UserProfileInternal _userProfileInternal;
  UserProfile get userProfile => _userProfileInternal;

  late final ViewsInternal _viewsInternal;
  Views get views => _viewsInternal;

  late final SessionsInternal _sessionsInternal;
  Sessions get sessions => _sessionsInternal;

  late final DeviceIDInternal _deviceIdInternal;
  DeviceID get deviceId => _deviceIdInternal;

  late final ContentBuilderInternal _contentBuilderInternal;
  ContentBuilderInternal get content => _contentBuilderInternal;

  late final FeedbackInternal _feedbackInternal;
  Feedback get feedback => _feedbackInternal;

  /// ignore: constant_identifier_names
  static const bool BUILDING_WITH_PUSH_DISABLED = false;
  static const String _pushDisabledMsg = 'In this plugin Push notification is disabled, Countly has separate plugin with push notification enabled';

  static const MethodChannel _channel = MethodChannel('countly_flutter');

  /// Used to determine if log messages should be printed to the console
  /// its value should be updated from [setLoggingEnabled(bool flag)].
  static bool _isDebug = false;

  static const String tag = 'CountlyFlutter';

  /// Flag to determine if crash logging functionality should be enabled
  /// If false the intercepted crashes will be ignored
  /// Set true when user enabled crash logging
  static bool _enableCrashReportingFlag = false;

  /// Flag to determine if manual session is enabled
  static bool _manualSessionControlEnabled = false;

  static Map<String, String> messagingMode = Platform.isAndroid ? {'TEST': '2', 'PRODUCTION': '0'} : {'TEST': '1', 'PRODUCTION': '0', 'ADHOC': '2'};

  static const temporaryDeviceID = 'CLYTemporaryDeviceID';
  @Deprecated('This variable is deprecated, please use "Countly.instance.deviceId.enableTemporaryDeviceID()" instead')
  static Map<String, String> deviceIDType = {'TemporaryDeviceID': temporaryDeviceID};

  static void log(String? message, {LogLevel logLevel = LogLevel.DEBUG}) {
    String logLevelStr = describeEnum(logLevel);
    if (_isDebug) {
      print('[$tag] $logLevelStr: $message');
    }
  }

  /// [VoidCallback? _widgetShown] Callback to be executed when feedback widget is displayed
  /// [VoidCallback? _widgetClosed] Callback to be executed when feedback widget is closed
  static VoidCallback? _widgetShown;
  static VoidCallback? _widgetClosed;
  static Function(String? error)? _remoteConfigCallback;
  static int lastUsedRCID = 0;
  static Function(String? error)? _ratingWidgetCallback;
  static Function(Map<String, dynamic> widgetData, String? error)? _feedbackWidgetDataCallback;

  /// Callback handler to handle function calls from native iOS/Android to Dart.
  static Future<void> _methodCallHandler(MethodCall call) async {
    log('[FMethodCallH] ${call.method}', logLevel: LogLevel.VERBOSE);
    switch (call.method) {
      case 'widgetShown':
        if (_widgetShown != null) {
          _widgetShown!();
        }
        break;
      case 'widgetClosed':
        if (_widgetClosed != null) {
          _widgetClosed!();
          _widgetShown = null;
          _widgetClosed = null;
        }
        break;
      case 'remoteConfigCallback':
        if (_remoteConfigCallback != null) {
          _remoteConfigCallback!(call.arguments);
          _remoteConfigCallback = null;
        }
        break;
      case 'ratingWidgetCallback':
        if (_ratingWidgetCallback != null) {
          _ratingWidgetCallback!(call.arguments);
          _ratingWidgetCallback = null;
        }
        break;
      case 'feedbackWidgetDataCallback':
        if (_feedbackWidgetDataCallback != null) {
          Map<String, dynamic> widgetData = {};
          Map<String, dynamic> argumentsMap = Map<String, dynamic>.from(call.arguments);
          String? error = argumentsMap['error'];
          if (error == null) {
            widgetData = Map<String, dynamic>.from(argumentsMap['widgetData']);
          }
          _feedbackWidgetDataCallback!(widgetData, error);
          _feedbackWidgetDataCallback = null;
        }
        break;
      case 'remoteConfigDownloadCallback':
        try {
          final Map<String, dynamic> argumentsMap = Map<String, dynamic>.from(call.arguments);
          final int rResult = argumentsMap['requestResult'];
          late final RequestResult requestResult;
          if (rResult == 0) {
            requestResult = RequestResult.success;
          } else if (rResult == 1) {
            requestResult = RequestResult.networkIssue;
          } else {
            requestResult = RequestResult.error;
          }
          final String? error = argumentsMap['error'];
          final bool fullValueUpdate = argumentsMap['fullValueUpdate'];
          final Map<dynamic, dynamic> downloadedValuesObject = argumentsMap['downloadedValues'];
          final int id = argumentsMap['id'];

          Countly.instance._remoteConfigInternal.notifyDownloadCallbacks(requestResult, error, fullValueUpdate, downloadedValuesObject, id);
        } catch (e) {
          log('[FMethodCallH] Method call for remoteConfigDownloadCallback had a problem: $e', logLevel: LogLevel.ERROR);
        }
        break;
      case 'remoteConfigVariantCallback':
        try {
          final Map<String, dynamic> argumentsMap = Map<String, dynamic>.from(call.arguments);
          final int rResult = argumentsMap['requestResult'];
          late final RequestResult requestResult;
          if (rResult == 0) {
            requestResult = RequestResult.success;
          } else if (rResult == 1) {
            requestResult = RequestResult.networkIssue;
          } else {
            requestResult = RequestResult.error;
          }
          final String? error = argumentsMap['error'];
          final int id = argumentsMap['id'];

          Countly.instance._remoteConfigInternal.notifyVariantCallbacks(requestResult, error, id);
        } catch (e) {
          log('[FMethodCallH] $e', logLevel: LogLevel.ERROR);
        }
        break;
      case 'feedbackCallback_onClosed':
        if (_instance._feedbackInternal.feedbackCallback != null) {
          _instance._feedbackInternal.feedbackCallback!.onClosed();
          _instance._feedbackInternal.feedbackCallback = null;
        }
        break;
      case 'feedbackCallback_onFinished':
        if (_instance._feedbackInternal.feedbackCallback != null) {
          _instance._feedbackInternal.feedbackCallback!.onFinished(call.arguments);
          _instance._feedbackInternal.feedbackCallback = null;
        }
        break;
      case 'contentCallback':
        Map<String, dynamic> argumentsMap = Map<String, dynamic>.from(call.arguments);
        final int contentResult = argumentsMap['contentResult'];
        ContentStatus contentStatus = ContentStatus.completed;
        if (contentResult == 1) {
          contentStatus = ContentStatus.closed;
        }
        Map<String, dynamic> contentData = Map<String, dynamic>.from(argumentsMap['contentData']);

        Countly.instance._contentBuilderInternal.onContentCallback(contentStatus, contentData);
        break;
    }
  }

  /// For registering a callback that is called when a remote config download is completed
  @Deprecated('This function is deprecated, please use rcRegisterCallback instead')
  static void setRemoteConfigCallback(Function(String? error) callback) {
    _remoteConfigCallback = callback;
  }

  /// Initialize the SDK
  /// This should only be called once
  /// returns the error or success message
  @Deprecated('This function is deprecated, please use initWithConfig instead')
  static Future<String?> init(String serverUrl, String appKey, [String? deviceId]) async {
    log('Calling "init" with serverURL: $serverUrl and appKey: $appKey');
    log('init is deprecated, use initWithConfig instead', logLevel: LogLevel.WARNING);
    CountlyConfig config = CountlyConfig(serverUrl, appKey);
    if (deviceId != null) {
      config.setDeviceId(deviceId);
    }
    return await initWithConfig(config);
  }

  /// Initialize the SDK
  /// This should only be called once
  /// returns the error or success message
  static Future<String?> initWithConfig(CountlyConfig config) async {
    if (config.loggingEnabled != null) {
      _isDebug = config.loggingEnabled!;
    }
    log('Calling "initWithConfig"');
    if (_instance._countlyState.isInitialized) {
      String msg = 'initWithConfig, SDK is already initialized';
      log(msg, logLevel: LogLevel.ERROR);
      return msg;
    }
    if (config.serverURL.isEmpty) {
      String msg = 'initWithConfig, serverURL cannot be empty';
      log(msg, logLevel: LogLevel.ERROR);
      return msg;
    }
    if (config.appKey.isEmpty) {
      String msg = 'initWithConfig, appKey cannot be empty';
      log(msg, logLevel: LogLevel.ERROR);
      return msg;
    }
    if (config.manualSessionEnabled != null) {
      _manualSessionControlEnabled = config.manualSessionEnabled!;
      if (config.manualSessionEnabled!) {
        _instance._sessionsInternal.enableManualSession();
      }
    }
    if (config.enableUnhandledCrashReporting != null) {
      // To catch all errors thrown within the flutter framework, we use
      FlutterError.onError = _recordFlutterError;

      // Asynchronous errors are not caught by the Flutter framework. For example
      // ElevatedButton(
      //   onPressed: () async {
      //     throw Error();
      //   }
      // )
      // To catch such errors, we use
      PlatformDispatcher.instance.onError = (e, s) {
        _internalRecordError(e, s);
        return true;
      };

      _enableCrashReportingFlag = config.enableUnhandledCrashReporting!;
    }
    _channel.setMethodCallHandler(_methodCallHandler);

    List<dynamic> args = [];
    args.add(_configToJson(config));

    final String? result = await _channel.invokeMethod('init', <String, dynamic>{'data': json.encode(args)});
    _instance._countlyState.isInitialized = true;

    if (config.remoteConfigGlobalCallbacks.isNotEmpty) {
      log('[initWithConfig] About to register ${config.remoteConfigGlobalCallbacks.length} callbacks', logLevel: LogLevel.VERBOSE);
    }
    for (final callback in config.remoteConfigGlobalCallbacks) {
      Countly.instance._remoteConfigInternal.registerDownloadCallback(callback);
    }

    if (config.content.contentCallback != null) {
      log('[initWithConfig] About to register content callback', logLevel: LogLevel.VERBOSE);
      Countly.instance._contentBuilderInternal.registerContentCallback(config.content.contentCallback!);
    }

    return result;
  }

  /// returns if SDK is initialized
  static Future<bool> isInitialized() async {
    log('Calling "isInitialized"');
    final String? result = await _channel.invokeMethod('isInitialized');
    _instance._countlyState.isInitialized = result == 'true';
    return _instance._countlyState.isInitialized;
  }

  /// Replaces all requests with a different app key with the current app key.
  /// In request queue, if there are any request whose app key is different than the current app key,
  /// these requests' app key will be replaced with the current app key.
  /// returns the error or success message
  static Future<String?> replaceAllAppKeysInQueueWithCurrentAppKey() async {
    if (!_instance._countlyState.isInitialized) {
      String message = '"initWithConfig" must be called before "replaceAllAppKeysInQueueWithCurrentAppKey"';
      log('replaceAllAppKeysInQueueWithCurrentAppKey, $message', logLevel: LogLevel.ERROR);
      return message;
    }
    log('Calling "replaceAllAppKeysInQueueWithCurrentAppKey"');
    final String? result = await _channel.invokeMethod('replaceAllAppKeysInQueueWithCurrentAppKey');

    return result;
  }

  /// Removes all requests with a different app key in request queue.
  /// In request queue, if there are any request whose app key is different than the current app key,
  /// these requests will be removed from request queue.
  /// returns the error or success message
  static Future<String?> removeDifferentAppKeysFromQueue() async {
    if (!_instance._countlyState.isInitialized) {
      String message = '"initWithConfig" must be called before "removeDifferentAppKeysFromQueue"';
      log('removeDifferentAppKeysFromQueue, $message', logLevel: LogLevel.ERROR);
      return message;
    }
    log('Calling "removeDifferentAppKeysFromQueue"');
    final String? result = await _channel.invokeMethod('removeDifferentAppKeysFromQueue');

    return result;
  }

  /// Call this function when app is loaded, so that the app launch duration can be recorded.
  /// Should be called after init.
  /// returns the error or success message
  static Future<String?> appLoadingFinished() async {
    log('Calling "appLoadingFinished"');
    if (!_instance._countlyState.isInitialized) {
      String message = '"initWithConfig" must be called before "appLoadingFinished"';
      log('appLoadingFinished, $message', logLevel: LogLevel.WARNING);
      return message;
    }
    final String? result = await _channel.invokeMethod('appLoadingFinished');

    return result;
  }

  /// Records an event
  /// returns the error or success message
  static Future<String?> recordEvent(Map<String, Object> options) async {
    if (!_instance._countlyState.isInitialized) {
      String message = '"initWithConfig" must be called before "recordEvent"';
      log('recordEvent, $message', logLevel: LogLevel.ERROR);
      return message;
    }
    List<Object> args = [];
    options['key'] ??= '';
    String eventKey = options['key'].toString();
    log('Calling "recordEvent":[$eventKey]');

    if (eventKey.isEmpty) {
      String error = 'recordEvent, Valid Countly event key is required';
      log(error);
      return 'Error : $error';
    }
    args.add(eventKey);
    options['count'] ??= '1';
    args.add(options['count'].toString());

    options['sum'] ??= '0';
    args.add(options['sum'].toString());

    options['duration'] ??= '0';
    args.add(options['duration'].toString());

    if (options['segmentation'] != null) {
      args.add(options['segmentation']!);
    }

    final String? result = await _channel.invokeMethod('recordEvent', <String, dynamic>{'data': json.encode(args)});

    return result;
  }

  /// Record custom view to Countly.
  ///
  /// [String view] - name of the view
  /// [Map<String, Object> segmentation] - allows to add optional segmentation,
  /// Supported data type for segmentation values are String, int, double and bool
  /// returns the error or success message
  @Deprecated('This function is deprecated, please use "startView" of Countly.instance.views instead')
  static Future<String?> recordView(String view, [Map<String, Object>? segmentation]) async {
    if (!_instance._countlyState.isInitialized) {
      String message = '"initWithConfig" must be called before "recordView"';
      log('recordView, $message', logLevel: LogLevel.ERROR);
      return message;
    }
    int segCount = segmentation != null ? segmentation.length : 0;
    log('Calling "recordView":[$view] with segmentation Count:[$segCount]');
    if (view.isEmpty) {
      String error = 'recordView, Trying to record view with empty view name, ignoring request';
      log(error);
      return 'Error : $error';
    }
    List<String> args = [];
    args.add(view);
    if (segmentation != null) {
      segmentation.forEach((k, v) {
        if (v is String || v is int || v is double || v is bool) {
          args.add(k);
          args.add(v.toString());
        } else {
          log('recordView, unsupported segmentation data type [${v.runtimeType}], View [$view]', logLevel: LogLevel.WARNING);
        }
      });
    }

    final String? result = await _channel.invokeMethod('recordView', <String, dynamic>{'data': json.encode(args)});

    return result;
  }

  /// Sets the user data.
  /// Should be called after init.
  /// returns the error or success message
  @Deprecated('This function is deprecated, please use "setUserProperties" instead')
  static Future<String?> setUserData(Map<String, Object> options) async {
    if (!_instance._countlyState.isInitialized) {
      String message = '"initWithConfig" must be called before "setUserData"';
      log('setUserData, $message', logLevel: LogLevel.ERROR);
      return message;
    }
    int optionsCount = options.length;
    log('Calling "setUserData" with options Count:[$optionsCount]');
    List<dynamic> args = [];
    Map<String, String> userData = _getUserData(options);
    args.add(userData);
    final String? result = await _channel.invokeMethod('setuserdata', <String, dynamic>{'data': json.encode(args)});
    return result;
  }

  static Map<String, String> _getUserData(Map<String, dynamic> options) {
    Map<String, String> userData = {};
    if (options.containsKey('name')) {
      userData['name'] = options['name'].toString();
    }
    if (options.containsKey('username')) {
      userData['username'] = options['username'].toString();
    }
    if (options.containsKey('email')) {
      userData['email'] = options['email'].toString();
    }
    if (options.containsKey('organization')) {
      userData['organization'] = options['organization'].toString();
    }
    if (options.containsKey('phone')) {
      userData['phone'] = options['phone'].toString();
    }
    if (options.containsKey('picture')) {
      userData['picture'] = options['picture'].toString();
    }
    if (options.containsKey('picturePath')) {
      userData['picturePath'] = options['picturePath'].toString();
    }
    if (options.containsKey('gender')) {
      userData['gender'] = options['gender'].toString();
    }
    if (options.containsKey('byear')) {
      userData['byear'] = options['byear'].toString();
    }
    return userData;
  }

  /// This method will ask for permission, enables push notification and send push token to countly server.
  /// Should be call after Countly init
  /// returns the error or success message
  static Future<String?> askForNotificationPermission() async {
    if (BUILDING_WITH_PUSH_DISABLED) {
      log('askForNotificationPermission, $_pushDisabledMsg', logLevel: LogLevel.ERROR);
      return _pushDisabledMsg;
    }
    if (!_instance._countlyState.isInitialized) {
      String message = '"initWithConfig" must be called before "askForNotificationPermission"';
      log('askForNotificationPermission, $message', logLevel: LogLevel.ERROR);
      return message;
    }
    log('Calling "askForNotificationPermission"');
    final String? result = await _channel.invokeMethod('askForNotificationPermission');

    return result;
  }

  /// Disable push notifications feature, by default it is enabled.
  /// Currently implemented for iOS only
  /// Should be called before Countly init
  /// returns the error or success message
  static Future<String?> disablePushNotifications() async {
    log('Calling "disablePushNotifications"');
    if (BUILDING_WITH_PUSH_DISABLED) {
      log('disablePushNotifications, $_pushDisabledMsg', logLevel: LogLevel.ERROR);
      return _pushDisabledMsg;
    }
    if (!Platform.isIOS) {
      return 'disablePushNotifications : To be implemented';
    }
    final String? result = await _channel.invokeMethod('disablePushNotifications');

    return result;
  }

  /// Set messaging mode for push notifications
  /// Should be call before Countly init
  /// returns the error or success message
  static Future<String?> pushTokenType(String tokenType) async {
    if (BUILDING_WITH_PUSH_DISABLED) {
      log('pushTokenType, $_pushDisabledMsg', logLevel: LogLevel.ERROR);
      return _pushDisabledMsg;
    }
    log('Calling "pushTokenType":[$tokenType]');
    if (tokenType.isEmpty) {
      String error = 'pushTokenType, tokenType cannot be empty';
      log(error);
      return 'Error : $error';
    }
    List<String> args = [];
    args.add(tokenType);

    final String? result = await _channel.invokeMethod('pushTokenType', <String, dynamic>{'data': json.encode(args)});

    return result;
  }

  /// Set callback to receive push notifications
  /// @param { callback listner } callback
  /// returns the error message or an empty string if there is no error
  static Future<String?> onNotification(Function(String) callback) async {
    if (BUILDING_WITH_PUSH_DISABLED) {
      log('onNotification, $_pushDisabledMsg', logLevel: LogLevel.ERROR);
      return _pushDisabledMsg;
    }
    log('Calling "onNotification"');
    await _channel.invokeMethod('registerForNotification').then((value) {
      callback(value.toString());
      onNotification(callback);
    }).catchError((error) {
      callback(error.toString());
    });
    return '';
  }

  /// Starts session for manual session handling.
  /// This method needs to be called for starting a session only if manual session handling is enabled by calling the 'enableManualSessionHandling' method of 'CountlyConfig'.
  /// returns the error or success message
  @Deprecated('This function is deprecated, please use "beginSession" of Countly.instance.sessions instead')
  static Future<String?> beginSession() async {
    if (!_instance._countlyState.isInitialized) {
      String message = '"initWithConfig" must be called before "beginSession"';
      log('beginSession, $message', logLevel: LogLevel.ERROR);
      return message;
    }
    log('Calling "beginSession", manual session control enabled:[$_manualSessionControlEnabled]');

    if (!_manualSessionControlEnabled) {
      String error = '"beginSession" will be ignored since manual session control is not enabled';
      log(error);
      return error;
    }
    final String? result = await _channel.invokeMethod('beginSession');

    return result;
  }

  /// Update session for manual session handling.
  /// This method needs to be called for updating a session only if manual session handling is enabled by calling the 'enableManualSessionHandling' method of 'CountlyConfig'.
  /// returns the error or success message
  @Deprecated('This function is deprecated, please use "updateSession" of Countly.instance.sessions instead')
  static Future<String?> updateSession() async {
    if (!_instance._countlyState.isInitialized) {
      String message = '"initWithConfig" must be called before "updateSession"';
      log('updateSession, $message', logLevel: LogLevel.ERROR);
      return message;
    }
    log('Calling "updateSession", manual session control enabled:[$_manualSessionControlEnabled]');

    if (!_manualSessionControlEnabled) {
      String error = '"updateSession" will be ignored since manual session control is not enabled';
      log(error);
      return error;
    }
    final String? result = await _channel.invokeMethod('updateSession');

    return result;
  }

  /// End session for manual session handling.
  /// This method needs to be called for ending a session only if manual session handling is enabled by calling the 'enableManualSessionHandling' method of 'CountlyConfig'.
  /// returns the error or success message
  @Deprecated('This function is deprecated, please use "endSession" of Countly.instance.sessions instead')
  static Future<String?> endSession() async {
    if (!_instance._countlyState.isInitialized) {
      String message = '"initWithConfig" must be called before "endSession"';
      log('endSession, $message', logLevel: LogLevel.ERROR);
      return message;
    }
    log('Calling "endSession", manual session control enabled:[$_manualSessionControlEnabled]');

    if (!_manualSessionControlEnabled) {
      String error = '"endSession" will be ignored since manual session control is not enabled';
      log(error);
      return error;
    }
    final String? result = await _channel.invokeMethod('endSession');

    return result;
  }

  /// Starts automatic session tracking.
  /// Does nothing
  /// returns the error message
  @Deprecated('Automatic sessions are handled by underlying SDK, this function will do nothing')
  static Future<String?> start() async {
    String msg = 'Automatic sessions are handled by underlying SDK, this function will do nothing';
    log(msg, logLevel: LogLevel.WARNING);
    return msg;
  }

  /// Enable manual session handling
  /// Should be called before init.
  /// Only implemented for iOS platform.
  /// returns the error or success message
  @Deprecated('This functions is deprecated, please use "enableManualSessionHandling" of CountlyConfig instead')
  static Future<String?> manualSessionHandling() async {
    log('Calling "manualSessionHandling"');
    log('manualSessionHandling is deprecated, use enableManualSessionHandling of CountlyConfig instead', logLevel: LogLevel.WARNING);
    final String? result = await _channel.invokeMethod('manualSessionHandling');

    return result;
  }

  /// Stops automatic session tracking.
  /// Does nothing
  /// returns the error message
  @Deprecated('Automatic sessions are handled by underlying SDK, this function will do nothing')
  static Future<String?> stop() async {
    String msg = 'Automatic sessions are handled by underlying SDK, this function will do nothing';
    log(msg, logLevel: LogLevel.WARNING);
    return msg;
  }

  /// Sets the duration between session updates.
  /// Does nothing
  /// returns the error message
  @Deprecated('This functions is deprecated, please use "setUpdateSessionTimerDelay" of CountlyConfig instead')
  static Future<String?> updateSessionPeriod() async {
    log('Calling "updateSessionPeriod"');
    String msg = 'updateSessionPeriod is deprecated, use setUpdateSessionTimerDelay of CountlyConfig instead';
    log(msg, logLevel: LogLevel.WARNING);
    return msg;
  }

  /// Sets the interval for the automatic session update calls
  /// min value 1 (1 second),
  /// max value 600 (10 minutes)
  /// [int sessionInterval]- delay in seconds
  /// returns the error or success message
  @Deprecated('This functions is deprecated, please use "setUpdateSessionTimerDelay" of CountlyConfig instead')
  static Future<String?> updateSessionInterval(int sessionInterval) async {
    log('Calling "updateSessionInterval":[$sessionInterval]');
    log('updateSessionInterval is deprecated, use setUpdateSessionTimerDelay of CountlyConfig instead', logLevel: LogLevel.WARNING);
    if (_instance._countlyState.isInitialized) {
      log('updateSessionInterval should be called before init', logLevel: LogLevel.WARNING);
      return 'updateSessionInterval should be called before init';
    }
    List<String> args = [];
    args.add(sessionInterval.toString());

    final String? result = await _channel.invokeMethod('updateSessionInterval', <String, dynamic>{'data': json.encode(args)});

    return result;
  }

  /// Events get grouped together and are sent either every minute or after the unsent event count reaches a threshold. By default it is 10
  /// Should be call before Countly init
  /// returns the error or success message
  @Deprecated('This functions is deprecated, please use "setEventQueueSizeToSend" of CountlyConfig instead')
  static Future<String?> eventSendThreshold(int limit) async {
    log('Calling "eventSendThreshold":[$limit]');
    log('eventSendThreshold is deprecated, use setEventQueueSizeToSend of CountlyConfig instead', logLevel: LogLevel.WARNING);
    List<String> args = [];
    args.add(limit.toString());

    final String? result = await _channel.invokeMethod('eventSendThreshold', <String, dynamic>{'data': json.encode(args)});

    return result;
  }

  /// This flag limits the number of requests that can be stored in the request queue when the Countly server is unavailable or unreachable.
  /// If the number of requests in the queue reaches the limit, the oldest requests in the queue will be dropped.
  /// Should be called before init.
  /// returns the error or success message
  @Deprecated('This functions is deprecated, please use "setMaxRequestQueueSize" of CountlyConfig instead')
  static Future<String?> storedRequestsLimit() async {
    log('Calling "storedRequestsLimit"');
    log('storedRequestsLimit is deprecated, use setMaxRequestQueueSize of CountlyConfig instead', logLevel: LogLevel.WARNING);
    final String? result = await _channel.invokeMethod('storedRequestsLimit');

    return result;
  }

  /// Set user location
  /// Should be called before init.
  /// returns the error or success message
  @Deprecated('This functions is deprecated, please use "setLocation" of CountlyConfig instead')
  static Future<String?> setOptionalParametersForInitialization(Map<String, Object> options) async {
    int optionsCount = options.length;
    log('Calling "setOptionalParametersForInitialization" with options count:[$optionsCount]');
    log('setOptionalParametersForInitialization is deprecated, use setLocation of CountlyConfig instead', logLevel: LogLevel.WARNING);
    List<String> args = [];

    options['city'] ??= 'null';
    options['country'] ??= 'null';
    options['latitude'] ??= 'null';
    options['longitude'] ??= 'null';
    options['ipAddress'] ??= 'null';

    String? city = options['city'].toString();
    String country = options['country'].toString();
    String latitude = options['latitude'].toString();
    String longitude = options['longitude'].toString();
    String ipAddress = options['ipAddress'].toString();

    args.add(city);
    args.add(country);
    args.add(latitude);
    args.add(longitude);
    args.add(ipAddress);

    final String? result = await _channel.invokeMethod('setOptionalParametersForInitialization', <String, dynamic>{'data': json.encode(args)});

    return result;
  }

  /// Get currently used device Id.
  /// Should be call after Countly init
  /// returns the error message or deviceID
  @Deprecated('getCurrentDeviceId is deprecated, use getID of Countly.instance.deviceID instead')
  static Future<String?> getCurrentDeviceId() async {
    log('Calling "getCurrentDeviceId"');
    log('getCurrentDeviceId is deprecated, use getID of Countly.instance.deviceID instead', logLevel: LogLevel.WARNING);
    if (!_instance._countlyState.isInitialized) {
      String message = '"initWithConfig" must be called before "getCurrentDeviceId"';
      log('getCurrentDeviceId, $message', logLevel: LogLevel.ERROR);
      return message;
    }
    String? result = await _instance.deviceId.getID();

    return result;
  }

  /// Get currently used device Id type.
  /// Should be call after Countly init
  /// returns the error message or deviceID type
  @Deprecated('getDeviceIDType is deprecated, use getIDType of Countly.instance.deviceID instead')
  static Future<DeviceIdType?> getDeviceIDType() async {
    log('Calling "getDeviceIDType"');
    log('getDeviceIDType is deprecated, use getIDType of Countly.instance.deviceID instead', logLevel: LogLevel.WARNING);
    if (!_instance._countlyState.isInitialized) {
      log('getDeviceIDType, "initWithConfig" must be called before "getDeviceIDType"', logLevel: LogLevel.ERROR);
      return null;
    }
    return await _instance.deviceId.getIDType();
  }

  /// change the device ID
  /// if onServer is true, the old device ID is replaced with the new one and all data associated with the old device ID will be merged automatically.
  /// if onServer is false, the new device ID will be counted as a new device on the server.
  /// returns the error or success message
  @Deprecated('changeDeviceId is deprecated, use changeWithoutMerge of Countly.instance.deviceID if onServer = false and changeWithMerge if onServer = true, instead')
  static Future<String?> changeDeviceId(String newDeviceID, bool onServer) async {
    log('changeDeviceId is deprecated, use ${onServer ? 'changeWithMerge' : 'changeWithoutMerge'} of Countly.instance.deviceID instead', logLevel: LogLevel.WARNING);
    if (!_instance._countlyState.isInitialized) {
      String message = '"initWithConfig" must be called before "changeDeviceId"';
      log('changeDeviceId, $message', logLevel: LogLevel.ERROR);
      return message;
    }
    log('Calling "changeDeviceId":[$newDeviceID] with onServer:[$onServer]');

    if (newDeviceID == Countly.temporaryDeviceID) {
      await _instance.deviceId.enableTemporaryIDMode();
    } else if (onServer) {
      await _instance.deviceId.changeWithMerge(newDeviceID);
    } else {
      await _instance.deviceId.changeWithoutMerge(newDeviceID);
    }
    return 'changeDeviceId Success';
  }

  /// add logs to your crash report.
  /// You can leave crash breadcrumbs which would describe previous steps that were taken in your app before the crash. They will be sent together with the crash report if the app crashes.
  /// returns the error or success message
  static Future<String?> addCrashLog(String logs) async {
    if (!_instance._countlyState.isInitialized) {
      String message = '"initWithConfig" must be called before "addCrashLog"';
      log('addCrashLog, $message', logLevel: LogLevel.ERROR);
      return message;
    }
    log('Calling "addCrashLog":[$logs]');
    if (logs.isEmpty) {
      String error = "addCrashLog, Can't add a null or empty crash logs";
      log(error);
      return 'Error : $error';
    }
    List<String> args = [];
    args.add(logs);

    final String? result = await _channel.invokeMethod('addCrashLog', <String, dynamic>{'data': json.encode(args)});

    return result;
  }

  /// Set to true if you want to enable countly internal debugging logs
  /// Should be call before Countly init
  /// returns the error or success message
  @Deprecated('This functions is deprecated, please use "setLoggingEnabled" of CountlyConfig to enable/disable logging instead')
  static Future<String?> setLoggingEnabled(bool flag) async {
    log('Calling "setLoggingEnabled":[$flag]');
    log('setLoggingEnabled is deprecated, use setLoggingEnabled of CountlyConfig to enable/disable logging', logLevel: LogLevel.WARNING);
    List<String> args = [];
    _isDebug = flag;
    args.add(flag.toString());

    final String? result = await _channel.invokeMethod('setLoggingEnabled', <String, dynamic>{'data': json.encode(args)});

    return result;
  }

  /// Set the optional salt to be used for calculating the checksum of requested data which will be sent with each request, using the &checksum field
  /// Should be call before Countly init
  /// returns the error or success message
  @Deprecated('This functions is deprecated, please use "setParameterTamperingProtectionSalt" of CountlyConfig instead')
  static Future<String?> enableParameterTamperingProtection(String salt) async {
    log('Calling "enableParameterTamperingProtection":[$salt]');
    log('enableParameterTamperingProtection is deprecated, use setParameterTamperingProtectionSalt of CountlyConfig instead', logLevel: LogLevel.WARNING);
    if (salt.isEmpty) {
      String error = 'enableParameterTamperingProtection, salt cannot be empty';
      log(error);
      return 'Error : $error';
    }
    List<String> args = [];
    args.add(salt);

    final String? result = await _channel.invokeMethod('enableParameterTamperingProtection', <String, dynamic>{'data': json.encode(args)});

    return result;
  }

  /// Set to 'true' if you want HTTP POST to be used for all requests
  /// Should be call before Countly init
  /// returns the error or success message
  @Deprecated('This functions is deprecated, please use "setHttpPostForced" of CountlyConfig instead')
  static Future<String?> setHttpPostForced(bool isEnabled) async {
    log('Calling "setHttpPostForced":[$isEnabled]');
    log('setHttpPostForced is deprecated, use setHttpPostForced of CountlyConfig instead', logLevel: LogLevel.WARNING);
    List<String> args = [];
    args.add(isEnabled.toString());

    final String? result = await _channel.invokeMethod('setHttpPostForced', <String, dynamic>{'data': json.encode(args)});

    return result;
  }

  /// Set user initial location
  /// Should be call before init
  /// returns the error or success message
  @Deprecated('This functions is deprecated, please use "setLocation" of CountlyConfig instead')
  static Future<String?> setLocationInit(String countryCode, String city, String gpsCoordinates, String ipAddress) async {
    log('Calling "setLocationInit" with countryCode:[$countryCode], city:[$city], gpsCoordinates:[$gpsCoordinates], ipAddress:[$ipAddress]');
    log('setLocationInit is deprecated, use setLocation of CountlyConfig instead', logLevel: LogLevel.WARNING);

    List<String> args = [];
    args.add(countryCode);
    args.add(city);
    args.add(gpsCoordinates);
    args.add(ipAddress);

    final String? result = await _channel.invokeMethod('setLocationInit', <String, dynamic>{'data': json.encode(args)});

    return result;
  }

  /// set the user location.
  /// returns the error or success message
  @Deprecated('This functions is deprecated, please use "setUserLocation" instead')
  static Future<String?> setLocation(String latitude, String longitude) async {
    if (!_instance._countlyState.isInitialized) {
      String message = '"initWithConfig" must be called before "setLocation"';
      log('setLocation, $message', logLevel: LogLevel.ERROR);
      return message;
    }
    log('Calling "setLocation" with latitude:[$latitude], longitude:[$longitude]');
    log('setLocation is deprecated, use setUserLocation instead', logLevel: LogLevel.WARNING);
    if (latitude.isEmpty) {
      String error = 'setLocation, latitude cannot be empty';
      log(error);
      return 'Error : $error';
    }
    if (longitude.isEmpty) {
      String error = 'setLocation, longitude cannot be empty';
      log(error);
      return 'Error : $error';
    }
    final String? result = await setUserLocation(gpsCoordinates: '$latitude,$longitude');
    return result;
  }

  /// Set user location
  /// [String country_code] - ISO Country code for the user's country
  /// [String city] - Name of the user's city
  /// [String gpsCoordinates] - comma separate lat and lng values. For example, "56.42345,123.45325"
  /// [String ipAddress] - ip address
  ///  All parameters are optional, but at least one has to be set
  /// returns the error or success message
  static Future<String?> setUserLocation({String? countryCode, String? city, String? gpsCoordinates, String? ipAddress}) async {
    if (!_instance._countlyState.isInitialized) {
      String message = '"initWithConfig" must be called before "setUserLocation"';
      log('setUserLocation, $message', logLevel: LogLevel.ERROR);
      return message;
    }
    Map<String, String?> location = {};
    location['countryCode'] = countryCode;
    location['city'] = city;
    location['gpsCoordinates'] = gpsCoordinates;
    location['ipAddress'] = ipAddress;
    List<dynamic> args = [];
    args.add(location);
    final String? result = await _channel.invokeMethod('setUserLocation', <String, dynamic>{'data': json.encode(args)});
    return result;
  }

  /// Disable User Location tracking
  /// returns the error or success message
  static Future<String?> disableLocation() async {
    if (!_instance._countlyState.isInitialized) {
      String message = '"initWithConfig" must be called before "disableLocation"';
      log('disableLocation, $message', logLevel: LogLevel.ERROR);
      return message;
    }
    final String? result = await _channel.invokeMethod('disableLocation');
    return result;
  }

  /// Set custom user property
  /// returns the error or success message
  @Deprecated('This function is deprecated. Please use "setProperty" of "Countly.instance.userProfile" instead and do not forget to call "Countly.instance.userProfile.save"')
  static Future<String?> setProperty(String keyName, String keyValue) async {
    if (!_instance._countlyState.isInitialized) {
      String message = '"initWithConfig" must be called before "setProperty"';
      log('setProperty, $message', logLevel: LogLevel.ERROR);
      return message;
    }
    log('Calling "setProperty":[$keyName], value:[$keyValue]');
    if (keyName.isEmpty) {
      String error = 'setProperty, key cannot be empty';
      log(error);
      return 'Error : $error';
    }
    if (keyValue.isEmpty) {
      String error = 'setProperty, value cannot be empty';
      log(error);
      return 'Error : $error';
    }
    List<String> args = [];
    args.add(keyName);
    args.add(keyValue);

    final String? result = await _channel.invokeMethod('userData_setProperty', <String, dynamic>{'data': json.encode(args)});

    return result;
  }

  /// Increment user property by 1
  /// returns the error or success message
  @Deprecated('This function is deprecated, please use "Countly.instance.userProfile.increment" instead and do not forget to call "Countly.instance.userProfile.save"')
  static Future<String?> increment(String keyName) async {
    if (!_instance._countlyState.isInitialized) {
      String message = '"initWithConfig" must be called before "increment"';
      log('increment, $message', logLevel: LogLevel.ERROR);
      return message;
    }
    log('Calling "increment":[$keyName]');
    if (keyName.isEmpty) {
      String error = 'increment, key cannot be empty';
      log(error);
      return 'Error : $error';
    }
    List<String> args = [];
    args.add(keyName);

    final String? result = await _channel.invokeMethod('userData_increment', <String, dynamic>{'data': json.encode(args)});

    return result;
  }

  /// Increment user property by provided value
  /// returns the error or success message
  @Deprecated('This function is deprecated, please use "Countly.instance.userProfile.incrementBy" instead and do not forget to call "Countly.instance.userProfile.save"')
  static Future<String?> incrementBy(String keyName, int keyIncrement) async {
    if (!_instance._countlyState.isInitialized) {
      String message = '"initWithConfig" must be called before "incrementBy"';
      log('incrementBy, $message', logLevel: LogLevel.ERROR);
      return message;
    }
    log('Calling "incrementBy":[$keyName], Value:[$keyIncrement]');
    if (keyName.isEmpty) {
      String error = 'incrementBy, key cannot be empty';
      log(error);
      return 'Error : $error';
    }
    List<String> args = [];
    args.add(keyName);
    args.add(keyIncrement.toString());

    final String? result = await _channel.invokeMethod('userData_incrementBy', <String, dynamic>{'data': json.encode(args)});

    return result;
  }

  /// Multiply user property by provided value
  /// returns the error or success message
  @Deprecated('This function is deprecated, please use "Countly.instance.userProfile.multiply" instead and do not forget to call "Countly.instance.userProfile.save"')
  static Future<String?> multiply(String keyName, int multiplyValue) async {
    if (!_instance._countlyState.isInitialized) {
      String message = '"initWithConfig" must be called before "multiply"';
      log('multiply, $message', logLevel: LogLevel.ERROR);
      return message;
    }
    log('Calling "multiply":[$keyName], Value:[$multiplyValue]');
    if (keyName.isEmpty) {
      String error = 'multiply, key cannot be empty';
      log(error);
      return 'Error : $error';
    }
    List<String> args = [];
    args.add(keyName);
    args.add(multiplyValue.toString());

    final String? result = await _channel.invokeMethod('userData_multiply', <String, dynamic>{'data': json.encode(args)});

    return result;
  }

  /// Save max of current value and provided value
  /// returns the error or success message
  @Deprecated('This function is deprecated, please use "Countly.instance.userProfile.saveMax" instead and do not forget to call "Countly.instance.userProfile.save"')
  static Future<String?> saveMax(String keyName, int saveMax) async {
    if (!_instance._countlyState.isInitialized) {
      String message = '"initWithConfig" must be called before "saveMax"';
      log('saveMax, $message', logLevel: LogLevel.ERROR);
      return message;
    }
    log('Calling "saveMax":[$keyName], Value:[$saveMax]');
    if (keyName.isEmpty) {
      String error = 'saveMax, key cannot be empty';
      log(error);
      return 'Error : $error';
    }
    List<String> args = [];
    args.add(keyName);
    args.add(saveMax.toString());

    final String? result = await _channel.invokeMethod('userData_saveMax', <String, dynamic>{'data': json.encode(args)});

    return result;
  }

  /// Save min of current value and provided value
  /// returns the error or success message
  @Deprecated('This function is deprecated, please use "Countly.instance.userProfile.saveMin" instead and do not forget to call "Countly.instance.userProfile.save"')
  static Future<String?> saveMin(String keyName, int saveMin) async {
    if (!_instance._countlyState.isInitialized) {
      String message = '"initWithConfig" must be called before "saveMin"';
      log('saveMin, $message', logLevel: LogLevel.ERROR);
      return message;
    }
    log('Calling "saveMin":[$keyName], Value:[$saveMin]');
    if (keyName.isEmpty) {
      String error = 'saveMin, key cannot be empty';
      log(error);
      return 'Error : $error';
    }
    List<String> args = [];
    args.add(keyName);
    args.add(saveMin.toString());

    final String? result = await _channel.invokeMethod('userData_saveMin', <String, dynamic>{'data': json.encode(args)});

    return result;
  }

  /// Set value to provided value if it does not exist
  /// returns the error or success message
  @Deprecated('This function is deprecated, please use "Countly.instance.userProfile.setOnce" instead and do not forget to call "Countly.instance.userProfile.save"')
  static Future<String?> setOnce(String keyName, String setOnce) async {
    if (!_instance._countlyState.isInitialized) {
      String message = '"initWithConfig" must be called before "setOnce"';
      log('setOnce, $message', logLevel: LogLevel.ERROR);
      return message;
    }
    log('Calling "setOnce":[$keyName], Value:[$setOnce]');
    if (keyName.isEmpty) {
      String error = 'setOnce, key cannot be empty';
      log(error);
      return 'Error : $error';
    }
    if (setOnce.isEmpty) {
      String error = 'setOnce, value cannot be empty';
      log(error);
      return 'Error : $error';
    }
    List<String> args = [];
    args.add(keyName);
    args.add(setOnce);

    final String? result = await _channel.invokeMethod('userData_setOnce', <String, dynamic>{'data': json.encode(args)});

    return result;
  }

  /// insert value to custom property array if value does not exist
  /// returns the error or success message
  @Deprecated('This function is deprecated, please use "Countly.instance.userProfile.pushUnique" instead and do not forget to call "Countly.instance.userProfile.save"')
  static Future<String?> pushUniqueValue(String type, String pushUniqueValue) async {
    if (!_instance._countlyState.isInitialized) {
      String message = '"initWithConfig" must be called before "pushUniqueValue"';
      log('pushUniqueValue, $message', logLevel: LogLevel.ERROR);
      return message;
    }
    log('Calling "pushUniqueValue":[$type], Value:[$pushUniqueValue]');
    if (type.isEmpty) {
      String error = 'pushUniqueValue, key cannot be empty';
      log(error);
      return 'Error : $error';
    }
    if (pushUniqueValue.isEmpty) {
      String error = 'pushUniqueValue, value cannot be empty';
      log(error);
      return 'Error : $error';
    }
    List<String> args = [];
    args.add(type);
    args.add(pushUniqueValue);

    final String? result = await _channel.invokeMethod('userData_pushUniqueValue', <String, dynamic>{'data': json.encode(args)});

    return result;
  }

  /// insert value to array which can have duplicates
  /// returns the error or success message
  @Deprecated('This function is deprecated, please use "Countly.instance.userProfile.push" instead and do not forget to call "Countly.instance.userProfile.save"')
  static Future<String?> pushValue(String type, String pushValue) async {
    if (!_instance._countlyState.isInitialized) {
      String message = '"initWithConfig" must be called before "pushValue"';
      log('pushValue, $message', logLevel: LogLevel.ERROR);
      return message;
    }
    log('Calling "pushValue":[$type], Value:[$pushValue]');
    if (type.isEmpty) {
      String error = 'pushValue, key cannot be empty';
      log(error);
      return 'Error : $error';
    }
    if (pushValue.isEmpty) {
      String error = 'pushValue, value cannot be empty';
      log(error);
      return 'Error : $error';
    }
    List<String> args = [];
    args.add(type);
    args.add(pushValue);

    final String? result = await _channel.invokeMethod('userData_pushValue', <String, dynamic>{'data': json.encode(args)});

    return result;
  }

  /// remove value from array
  /// returns the error or success message
  @Deprecated('This function is deprecated, please use "Countly.instance.userProfile.pull" instead and do not forget to call "Countly.instance.userProfile.save"')
  static Future<String?> pullValue(String type, String pullValue) async {
    if (!_instance._countlyState.isInitialized) {
      String message = '"initWithConfig" must be called before "pullValue"';
      log('pullValue, $message', logLevel: LogLevel.ERROR);
      return message;
    }
    log('Calling "pullValue":[$type], Value:[$pullValue]');
    if (type.isEmpty) {
      String error = 'pullValue, key cannot be empty';
      log(error);
      return 'Error : $error';
    }
    if (pullValue.isEmpty) {
      String error = 'pullValue, value cannot be empty';
      log(error);
      return 'Error : $error';
    }
    List<String> args = [];
    args.add(type);
    args.add(pullValue);

    final String? result = await _channel.invokeMethod('userData_pullValue', <String, dynamic>{'data': json.encode(args)});

    return result;
  }

  /// Set that consent should be required for features to work.
  /// Should be call before Countly init
  /// returns the error or success message
  @Deprecated('This function is deprecated, please use "setRequiresConsent" of CountlyConfig instead')
  static Future<String?> setRequiresConsent(bool flag) async {
    log('Calling "setRequiresConsent":[$flag]');
    log('setRequiresConsent is deprecated, use setRequiresConsent of CountlyConfig instead', logLevel: LogLevel.WARNING);
    List<String> args = [];
    args.add(flag.toString());

    final String? result = await _channel.invokeMethod('setRequiresConsent', <String, dynamic>{'data': json.encode(args)});

    return result;
  }

  /// Give consent for specific features.
  /// Should be call before Countly init
  /// returns the error or success message
  @Deprecated('This function is deprecated, please use "setConsentEnabled" of CountlyConfig instead')
  static Future<String?> giveConsentInit(List<String> consents) async {
    String consentsString = consents.toString();
    log('Calling "giveConsentInit":[$consentsString]');
    log('giveConsentInit is deprecated, use setConsentEnabled of CountlyConfig instead', logLevel: LogLevel.WARNING);

    if (consents.isEmpty) {
      String error = 'giveConsentInit, consents List is empty';
      log(error, logLevel: LogLevel.WARNING);
    }
    log(consents.toString());
    final String? result = await _channel.invokeMethod('giveConsentInit', <String, dynamic>{'data': json.encode(consents)});

    return result;
  }

  /// Give consent for specific features.
  /// returns the error or success message
  static Future<String?> giveConsent(List<String> consents) async {
    if (!_instance._countlyState.isInitialized) {
      String message = '"initWithConfig" must be called before "giveConsent"';
      log('giveConsent, $message', logLevel: LogLevel.ERROR);
      return message;
    }
    String consentsString = consents.toString();
    log('Calling "giveConsent":[$consentsString]');
    if (consents.isEmpty) {
      String error = 'giveConsent, consents List is empty';
      log(error, logLevel: LogLevel.WARNING);
    }
    log(consents.toString());
    final String? result = await _channel.invokeMethod('giveConsent', <String, dynamic>{'data': json.encode(consents)});

    return result;
  }

  /// Remove consent for specific features.
  /// returns the error or success message
  static Future<String?> removeConsent(List<String> consents) async {
    if (!_instance._countlyState.isInitialized) {
      String message = '"initWithConfig" must be called before "removeConsent"';
      log('removeConsent, $message', logLevel: LogLevel.ERROR);
      return message;
    }
    String consentsString = consents.toString();
    log('Calling "removeConsent":[$consentsString]');
    if (consents.isEmpty) {
      String error = 'removeConsent, consents List is empty';
      log(error, logLevel: LogLevel.WARNING);
    }
    log(consents.toString());
    final String? result = await _channel.invokeMethod('removeConsent', <String, dynamic>{'data': json.encode(consents)});

    return result;
  }

  /// Give consent for all features
  /// Should be call after Countly init
  /// returns the error or success message
  static Future<String?> giveAllConsent() async {
    if (!_instance._countlyState.isInitialized) {
      String message = '"initWithConfig" must be called before "giveAllConsent"';
      log('giveAllConsent, $message', logLevel: LogLevel.ERROR);
      return message;
    }
    log('Calling "giveAllConsent"');
    final String? result = await _channel.invokeMethod('giveAllConsent');

    return result;
  }

  /// Remove consent for all features.
  /// returns the error or success message
  static Future<String?> removeAllConsent() async {
    if (!_instance._countlyState.isInitialized) {
      String message = '"initWithConfig" must be called before "removeAllConsent"';
      log('removeAllConsent, $message', logLevel: LogLevel.ERROR);
      return message;
    }
    log('Calling "removeAllConsent"');
    final String? result = await _channel.invokeMethod('removeAllConsent');

    return result;
  }

  /// Set Automatic value download happens when the SDK is initiated or when the device ID is changed.
  /// Should be call before Countly init
  /// returns the error or success message
  @Deprecated('This function is deprecated, please use "remoteConfigRegisterDownloadCallback" of CountlyConfig instead')
  static Future<String?> setRemoteConfigAutomaticDownload(Function(String?) callback) async {
    log('Calling "setRemoteConfigAutomaticDownload"');
    log('setRemoteConfigAutomaticDownload is deprecated, use setRemoteConfigAutomaticDownload of CountlyConfig instead', logLevel: LogLevel.WARNING);
    final String? result = await _channel.invokeMethod('setRemoteConfigAutomaticDownload');

    callback(result);
    return result;
  }

  /// Replace all stored remote config values with new ones from the server.
  /// returns the error or success message
  @Deprecated('This function is deprecated, please use "remoteConfigDownloadValues" instead')
  static Future<String?> remoteConfigUpdate(Function(String?) callback) async {
    if (!_instance._countlyState.isInitialized) {
      String message = '"initWithConfig" must be called before "remoteConfigUpdate"';
      log('remoteConfigUpdate, $message', logLevel: LogLevel.ERROR);
      return message;
    }
    log('Calling "remoteConfigUpdate"');
    final String? result = await _channel.invokeMethod('remoteConfigUpdate');

    callback(result);
    return result;
  }

  /// Replace specific remote config values with new ones from the server.
  /// returns the error or success message
  @Deprecated('This function is deprecated, please use "remoteConfigDownloadSpecificValue" instead')
  static Future<String?> updateRemoteConfigForKeysOnly(List<String> keys, Function(String?) callback) async {
    if (!_instance._countlyState.isInitialized) {
      String message = '"initWithConfig" must be called before "updateRemoteConfigForKeysOnly"';
      log('updateRemoteConfigForKeysOnly, $message', logLevel: LogLevel.ERROR);
      return message;
    }
    String keysString = keys.toString();
    log('Calling "updateRemoteConfigForKeysOnly":[$keysString]');
    if (keys.isEmpty) {
      String error = 'updateRemoteConfigForKeysOnly, keys List is empty';
      log(error, logLevel: LogLevel.WARNING);
    }
    log(keys.toString());
    final String? result = await _channel.invokeMethod('updateRemoteConfigForKeysOnly', <String, dynamic>{'data': json.encode(keys)});

    callback(result);
    return result;
  }

  /// Replace remote config values (except provided keys) with new ones from the server.
  /// returns the error or success message
  @Deprecated('This function is deprecated, please use "remoteConfigDownloadOmittingValues" instead')
  static Future<String?> updateRemoteConfigExceptKeys(List<String> keys, Function(String?) callback) async {
    if (!_instance._countlyState.isInitialized) {
      String message = '"initWithConfig" must be called before "updateRemoteConfigExceptKeys"';
      log('updateRemoteConfigExceptKeys, $message', logLevel: LogLevel.ERROR);
      return message;
    }
    String keysString = keys.toString();
    log('Calling "updateRemoteConfigExceptKeys":[$keysString]');
    if (keys.isEmpty) {
      String error = 'updateRemoteConfigExceptKeys, keys List is empty';
      log(error, logLevel: LogLevel.WARNING);
    }
    log(keys.toString());
    final String? result = await _channel.invokeMethod('updateRemoteConfigExceptKeys', <String, dynamic>{'data': json.encode(keys)});

    callback(result);
    return result;
  }

  /// Clear all remote config values.
  /// returns the error or success message
  @Deprecated('This function is deprecated, please use "remoteConfigClearAllValues" instead')
  static Future<String?> remoteConfigClearValues(Function(String?) callback) async {
    if (!_instance._countlyState.isInitialized) {
      String message = '"initWithConfig" must be called before "remoteConfigClearValues"';
      log('remoteConfigClearValues, $message', logLevel: LogLevel.ERROR);
      return message;
    }
    log('Calling "remoteConfigClearValues"');
    final String? result = await _channel.invokeMethod('remoteConfigClearValues');

    callback(result);
    return result;
  }

  /// Clear all remote config values.
  /// returns the error message or remote config value
  @Deprecated('This function is deprecated, please use "remoteConfigGetValue" instead')
  static Future<String?> getRemoteConfigValueForKey(String key, Function(String?) callback) async {
    if (!_instance._countlyState.isInitialized) {
      String message = '"initWithConfig" must be called before "getRemoteConfigValueForKey"';
      log('getRemoteConfigValueForKey, $message', logLevel: LogLevel.ERROR);
      return message;
    }
    log('Calling "getRemoteConfigValueForKey" with the key:[$key]');
    if (key.isEmpty) {
      String error = 'getRemoteConfigValueForKey, key cannot be empty';
      log(error);
      return 'Error : $error';
    }
    List<String> args = [];
    args.add(key);

    final String? result = await _channel.invokeMethod('getRemoteConfigValueForKey', <String, dynamic>{'data': json.encode(args)});

    callback(result);
    return result;
  }

  /// Set's the text's for the different fields in the star rating dialog. Set value null if for some field you want to keep the old value
  /// [String starRatingTextTitle] - dialog's title text (Only for Android)
  /// [String starRatingTextMessage] - dialog's message text
  /// [String starRatingTextDismiss] - dialog's dismiss buttons text (Only for Android)
  /// returns the error or success message
  @Deprecated('This function is deprecated, please use "setStarRatingDialogTexts" of CountlyConfig instead')
  static Future<String?> setStarRatingDialogTexts(String starRatingTextTitle, String starRatingTextMessage, String starRatingTextDismiss) async {
    log('Calling "setStarRatingDialogTexts":[$starRatingTextTitle], message:[$starRatingTextMessage], dimiss:[$starRatingTextDismiss]');
    log('setStarRatingDialogTexts is deprecated, use setStarRatingDialogTexts of CountlyConfig instead', logLevel: LogLevel.WARNING);
    List<String> args = [];
    args.add(starRatingTextTitle);
    args.add(starRatingTextMessage);
    args.add(starRatingTextDismiss);

    final String? result = await _channel.invokeMethod('setStarRatingDialogTexts', <String, dynamic>{'data': json.encode(args)});

    return result;
  }

  /// display star rating to users.
  /// returns the error or success message
  static Future<String?> askForStarRating() async {
    if (!_instance._countlyState.isInitialized) {
      String message = '"initWithConfig" must be called before "askForStarRating"';
      log('askForStarRating, $message', logLevel: LogLevel.ERROR);
      return message;
    }
    log('Calling "askForStarRating"');
    final String? result = await _channel.invokeMethod('askForStarRating');

    return result;
  }

  /// Show feedback widget associated with provided ID.
  /// returns the error or success message
  @Deprecated('This function is deprecated, please use "presentRatingWidgetWithID" instead')
  static Future<String?> askForFeedback(String widgetId, String? closeButtonText) async {
    if (!_instance._countlyState.isInitialized) {
      String message = '"initWithConfig" must be called before "askForFeedback"';
      log('askForFeedback, $message', logLevel: LogLevel.ERROR);
      return message;
    }
    log('Calling "askForFeedback":[$widgetId]');
    if (widgetId.isEmpty) {
      String error = 'askForFeedback, widgetId cannot be empty';
      log(error);
      return 'Error : $error';
    }
    log('askForFeedback is deprecated, use presentRatingWidgetWithID instead', logLevel: LogLevel.WARNING);
    final String? result = await presentRatingWidgetWithID(widgetId, closeButtonText: closeButtonText);
    return result;
  }

  /// Displays the feedback widget for the given ID
  /// returns the error or success message
  static Future<String?> presentRatingWidgetWithID(String widgetId, {String? closeButtonText, Function(String? error)? ratingWidgetCallback}) async {
    if (!_instance._countlyState.isInitialized) {
      String message = '"initWithConfig" must be called before "presentRatingWidgetWithID"';
      log('presentRatingWidgetWithID, $message', logLevel: LogLevel.ERROR);
      return message;
    }
    bool isCallback = ratingWidgetCallback != null ? true : false;
    log('Calling "presentRatingWidgetWithID":[$widgetId] with callback:[$isCallback]');
    if (widgetId.isEmpty) {
      String error = 'presentRatingWidgetWithID, widgetId cannot be empty';
      log(error);
      return 'Error : $error';
    }
    _ratingWidgetCallback = ratingWidgetCallback;
    closeButtonText = closeButtonText ??= '';
    List<String> args = [];
    args.add(widgetId);
    args.add(closeButtonText);
    final String? result = await _channel.invokeMethod('presentRatingWidgetWithID', <String, dynamic>{'data': json.encode(args)});
    return result;
  }

  /// Get a list of available feedback widgets for this device ID
  /// returns FeedbackWidgetsResponse
  static Future<FeedbackWidgetsResponse> getAvailableFeedbackWidgets() async {
    if (!_instance._countlyState.isInitialized) {
      String message = '"initWithConfig" must be called before "getAvailableFeedbackWidgets"';
      log('getAvailableFeedbackWidgets, $message', logLevel: LogLevel.ERROR);
      return FeedbackWidgetsResponse([], message);
    }
    log('Calling "getAvailableFeedbackWidgets"');
    List<CountlyPresentableFeedback> presentableFeedback = [];
    String? error;
    try {
      final List<dynamic> retrievedWidgets = await _channel.invokeMethod('getAvailableFeedbackWidgets');
      presentableFeedback = retrievedWidgets.map((e) => CountlyPresentableFeedback.fromJson(e)).toList();
    } on PlatformException catch (e) {
      error = e.message;
      log('getAvailableFeedbackWidgets Error : $error');
    }
    FeedbackWidgetsResponse feedbackWidgetsResponse = FeedbackWidgetsResponse(presentableFeedback, error);

    return feedbackWidgetsResponse;
  }

  /// Present a chosen feedback widget
  /// [CountlyPresentableFeedback widgetInfo] - Get available list of feedback widgets by calling 'getAvailableFeedbackWidgets()' and pass the widget object as a parameter.
  /// [String closeButtonText] - Text for cancel/close button.
  /// [VoidCallback? widgetShown] Callback to be executed when feedback widget is displayed
  /// [VoidCallback? widgetClosed] Callback to be executed when feedback widget is closed
  /// Note: widgetClosed is only implemented for iOS
  /// returns error or success message
  static Future<String?> presentFeedbackWidget(CountlyPresentableFeedback widgetInfo, String closeButtonText, {VoidCallback? widgetShown, VoidCallback? widgetClosed}) async {
    if (!_instance._countlyState.isInitialized) {
      String message = '"initWithConfig" must be called before "presentFeedbackWidget"';
      log('presentFeedbackWidget, $message', logLevel: LogLevel.ERROR);
      return message;
    }
    String widgetId = widgetInfo.widgetId;
    String widgetType = widgetInfo.type;
    log('Calling "presentFeedbackWidget":[$presentFeedbackWidget] with Type:[$widgetType]');
    _widgetShown = widgetShown;
    _widgetClosed = widgetClosed;

    List<String> args = [];
    args.add(widgetId);
    args.add(widgetType);
    args.add(widgetInfo.name);
    args.add(closeButtonText);

    String? result;
    try {
      result = await _channel.invokeMethod('presentFeedbackWidget', <String, dynamic>{'data': json.encode(args)});
    } on PlatformException catch (e) {
      result = e.message;
    }

    return result;
  }

  /// Downloads widget info and returns [widgetData, error]
  /// [CountlyPresentableFeedback widgetInfo] - identifies the specific widget for which you want to download widget data
  /// returns a List [widgetData and error message] if any.
  static Future<List> getFeedbackWidgetData(CountlyPresentableFeedback widgetInfo, {Function(Map<String, dynamic> widgetData, String? error)? onFinished}) async {
    Map<String, dynamic> widgetData = {};
    if (!_instance._countlyState.isInitialized) {
      String message = '"initWithConfig" must be called before "getFeedbackWidgetData"';
      log('getFeedbackWidgetData, $message', logLevel: LogLevel.ERROR);
      return [widgetData, message];
    }
    _feedbackWidgetDataCallback = onFinished;
    String widgetId = widgetInfo.widgetId;
    String widgetType = widgetInfo.type;
    log('Calling "getFeedbackWidgetData":[$presentFeedbackWidget] with Type:[$widgetType]');
    String? error;
    List<String> args = [];
    args.add(widgetId);
    args.add(widgetType);
    args.add(widgetInfo.name);

    try {
      Map<dynamic, dynamic> retrievedWidgetData = await _channel.invokeMethod('getFeedbackWidgetData', <String, dynamic>{'data': json.encode(args)});
      widgetData = Map<String, dynamic>.from(retrievedWidgetData);
    } on PlatformException catch (e) {
      error = e.message;
      log('getFeedbackWidgetData Error : $error');
    }
    return [widgetData, error];
  }

  /// Report widget info and do data validation
  /// [CountlyPresentableFeedback widgetInfo] - identifies the specific widget for which the feedback is filled out
  /// [Map<String, dynamic> widgetData] - widget data for this specific widget
  /// [Map<String, Object> widgetResult] - segmentation of the filled out feedback. If this segmentation is null, it will be assumed that the survey was closed before completion and mark it appropriately
  /// returns error or success message
  static Future<String?> reportFeedbackWidgetManually(CountlyPresentableFeedback widgetInfo, Map<String, dynamic> widgetData, Map<String, Object> widgetResult) async {
    if (!_instance._countlyState.isInitialized) {
      String message = '"initWithConfig" must be called before "reportFeedbackWidgetManually"';
      log('reportFeedbackWidgetManually, $message', logLevel: LogLevel.ERROR);
      return message;
    }
    String widgetId = widgetInfo.widgetId;
    String widgetType = widgetInfo.type;
    log('Calling "reportFeedbackWidgetManually":[$presentFeedbackWidget] with Type:[$widgetType]');
    List<String> widgetInfoList = [];
    widgetInfoList.add(widgetId);
    widgetInfoList.add(widgetType);
    widgetInfoList.add(widgetInfo.name);

    List<dynamic> args = [];
    args.add(widgetInfoList);
    args.add(widgetData);
    args.add(widgetResult);

    String? result;
    try {
      result = await _channel.invokeMethod('reportFeedbackWidgetManually', <String, dynamic>{'data': json.encode(args)});
    } on PlatformException catch (e) {
      result = e.message;
    }

    return result;
  }

  /// starts a timed event
  /// returns error or success message
  static Future<String?> startEvent(String key) async {
    if (!_instance._countlyState.isInitialized) {
      String message = '"initWithConfig" must be called before "startEvent"';
      log('startEvent, $message', logLevel: LogLevel.ERROR);
      return message;
    }
    log('Calling "startEvent":[$key]');
    if (key.isEmpty) {
      String error = "startEvent, Can't start event with empty key";
      log(error);
      return 'Error : $error';
    }
    List<String> args = [];
    args.add(key);

    final String? result = await _channel.invokeMethod('startEvent', <String, dynamic>{'data': json.encode(args)});

    return result;
  }

  /// ends a timed event
  /// returns error or success message
  static Future<String?> endEvent(Map<String, Object> options) async {
    if (!_instance._countlyState.isInitialized) {
      String message = '"initWithConfig" must be called before "endEvent"';
      log('endEvent, $message', logLevel: LogLevel.ERROR);
      return message;
    }
    String eventKey = options['key'] != null ? options['key'].toString() : '';
    log('Calling "endEvent":[$eventKey]');
    List<Object> args = [];

    if (eventKey.isEmpty) {
      String error = "endEvent, Can't end event with a null or empty key";
      log(error);
      return 'Error : $error';
    }
    args.add(eventKey);

    options['count'] ??= '1';
    args.add(options['count'].toString());

    options['sum'] ??= '0';
    args.add(options['sum'].toString());

    if (options['segmentation'] != null) {
      args.add(options['segmentation']!);
    }

    final String? result = await _channel.invokeMethod('endEvent', <String, dynamic>{'data': json.encode(args)});

    return result;
  }

  /// Call used for testing error handling
  /// Should not be used
  static Future<String?> throwNativeException() async {
    log('Calling "throwNativeException"');
    final String? result = await _channel.invokeMethod('throwNativeException');

    return result;
  }

  /// Enable crash reporting to report uncaught errors to Countly.
  /// Should be call before Countly init
  /// returns error or success message
  @Deprecated('This function is deprecated, please use "enableCrashReporting" of CountlyConfig instead')
  static Future<String?> enableCrashReporting() async {
    log('Calling "enableCrashReporting"');
    log('enableCrashReporting is deprecated, use enableCrashReporting of CountlyConfig instead', logLevel: LogLevel.WARNING);
    FlutterError.onError = _recordFlutterError;
    PlatformDispatcher.instance.onError = (e, s) {
      _internalRecordError(e, s);
      return true;
    };
    _enableCrashReportingFlag = true;
    final String? result = await _channel.invokeMethod('enableCrashReporting');

    return result;
  }

  /// Report a handled or unhandled exception/error to Countly.
  ///
  /// This call does not add a stacktrace automatically
  /// if it's needed, it should already be added to the [exception] variable
  ///
  /// A potential use case would be to provide [exception.toString()]
  ///
  /// [String exception] - the exception / crash information sent to the server
  /// [bool nonfatal] - reports if the error was fatal or not
  /// [Map<String, Object> segmentation] - allows to add optional segmentation
  /// returns error or success message
  static Future<String?> logException(String exception, bool nonfatal, [Map<String, Object>? segmentation]) async {
    if (!_instance._countlyState.isInitialized) {
      String message = '"initWithConfig" must be called before "logException"';
      log('logException, $message', logLevel: LogLevel.ERROR);
      return message;
    }
    int segCount = segmentation != null ? segmentation.length : 0;
    log('Calling "logException":[$exception] nonfatal:[$nonfatal]: with segmentation count:[$segCount]');
    List<String> args = [];
    args.add(exception);
    args.add(nonfatal.toString());
    if (segmentation != null) {
      segmentation.forEach((k, v) {
        args.add(k.toString());
        args.add(v.toString());
      });
    }
    final String? result = await _channel.invokeMethod('logException', <String, dynamic>{'data': json.encode(args)});

    return result;
  }

  /// Set optional key/value segment added for crash reports.
  /// Should be call before Countly init
  /// returns error or success message
  @Deprecated('This function is deprecated, please use "setCustomCrashSegment" of CountlyConfig instead')
  static Future<String?> setCustomCrashSegment(Map<String, Object> segments) async {
    int segCount = segments.length;
    log('Calling "setCustomCrashSegment" segmentation count:[$segCount]');
    log('setCustomCrashSegment is deprecated, use setCustomCrashSegment of CountlyConfig instead', logLevel: LogLevel.WARNING);
    List<String> args = [];
    segments.forEach((k, v) {
      args.add(k.toString());
      args.add(v.toString());
    });

    final String? result = await _channel.invokeMethod('setCustomCrashSegment', <String, dynamic>{'data': json.encode(args)});

    return result;
  }

  /// record duration of application processes
  /// returns error or success message
  static Future<String?> startTrace(String traceKey) async {
    if (!_instance._countlyState.isInitialized) {
      String message = '"initWithConfig" must be called before "startTrace"';
      log('startTrace, $message', logLevel: LogLevel.ERROR);
      return message;
    }
    log('Calling "startTrace":[$traceKey]');
    List<String> args = [];
    args.add(traceKey);

    final String? result = await _channel.invokeMethod('startTrace', <String, dynamic>{'data': json.encode(args)});

    return result;
  }

  /// cancel a trace
  /// returns error or success message
  static Future<String?> cancelTrace(String traceKey) async {
    if (!_instance._countlyState.isInitialized) {
      String message = '"initWithConfig" must be called before "cancelTrace"';
      log('cancelTrace, $message', logLevel: LogLevel.ERROR);
      return message;
    }
    log('Calling "cancelTrace":[$traceKey]');
    List<String> args = [];
    args.add(traceKey);

    final String? result = await _channel.invokeMethod('cancelTrace', <String, dynamic>{'data': json.encode(args)});

    return result;
  }

  /// cancel all traces
  /// returns error or success message
  static Future<String?> clearAllTraces() async {
    if (!_instance._countlyState.isInitialized) {
      String message = '"initWithConfig" must be called before "clearAllTraces"';
      log('clearAllTraces, $message', logLevel: LogLevel.ERROR);
      return message;
    }
    log('Calling "clearAllTraces"');
    final String? result = await _channel.invokeMethod('clearAllTraces');

    return result;
  }

  /// end a trace
  /// returns error or success message
  static Future<String?> endTrace(String traceKey, Map<String, int>? customMetric) async {
    if (!_instance._countlyState.isInitialized) {
      String message = '"initWithConfig" must be called before "endTrace"';
      log('endTrace, $message', logLevel: LogLevel.ERROR);
      return message;
    }
    int metricCount = customMetric != null ? customMetric.length : 0;
    log('Calling "endTrace":[$traceKey] with metric count:[$metricCount]');
    List<String> args = [];
    args.add(traceKey);
    if (customMetric != null) {
      customMetric.forEach((k, v) {
        args.add(k.toString());
        args.add(v.toString());
      });
    }

    final String? result = await _channel.invokeMethod('endTrace', <String, dynamic>{'data': json.encode(args)});

    return result;
  }

  /// record a network trace
  /// returns error or success message
  static Future<String?> recordNetworkTrace(String networkTraceKey, int responseCode, int requestPayloadSize, int responsePayloadSize, int startTime, int endTime) async {
    if (!_instance._countlyState.isInitialized) {
      String message = '"initWithConfig" must be called before "recordNetworkTrace"';
      log('recordNetworkTrace, $message', logLevel: LogLevel.ERROR);
      return message;
    }
    log('Calling "recordNetworkTrace":[$networkTraceKey] with response Code:[$responseCode]');
    List<String> args = [];
    args.add(networkTraceKey);
    args.add(responseCode.toString());
    args.add(requestPayloadSize.toString());
    args.add(responsePayloadSize.toString());
    args.add(startTime.toString());
    args.add(endTime.toString());

    final String? result = await _channel.invokeMethod('recordNetworkTrace', <String, dynamic>{'data': json.encode(args)});

    return result;
  }

  /// Enable APM features, which includes the recording of app start time.
  /// Should be call before Countly init
  /// returns error or success message
  @Deprecated('This function is deprecated, please use "enableAppStartTimeTracking" of CountlyConfig.apm instead')
  static Future<String?> enableApm() async {
    log('Calling "enableApm"');
    log('enableApm is deprecated, use enableAppStartTimeTracking of CountlyConfig.apm instead', logLevel: LogLevel.WARNING);
    final String? result = await _channel.invokeMethod('enableApm');

    return result;
  }

  /// Report a handled or unhandled exception/error to Countly.
  ///
  /// The exception is provided with an [Exception] object
  /// If no stack trace is provided, [StackTrace.current] will be used
  ///
  /// [String exception] - the exception that is recorded
  /// [bool nonfatal] - reports if the exception was fatal or not
  /// [StackTrace stacktrace] - stacktrace for the crash
  /// [Map<String, Object> segmentation] - allows to add optional segmentation
  /// returns error or success message
  static Future<String?> logExceptionEx(Exception exception, bool nonfatal, {StackTrace? stacktrace, Map<String, Object>? segmentation}) async {
    String exceptionString = exception.toString();
    log('Calling "logExceptionEx":[$exceptionString] nonfatal:[$nonfatal]');
    stacktrace ??= StackTrace.current;
    final result = logException('$exceptionString\n$stacktrace', nonfatal, segmentation);
    return result;
  }

  /// Report a handled or unhandled exception/error to Countly.
  ///
  /// The exception/error is provided with a string message
  /// If no stack trace is provided, [StackTrace.current] will be used
  ///
  /// [String message] - the error / crash information sent to the server
  /// [bool nonfatal] - reports if the error was fatal or not
  /// [StackTrace stacktrace] - stacktrace for the crash
  /// [Map<String, Object> segmentation] - allows to add optional segmentation
  /// returns error or success message
  static Future<String?> logExceptionManual(String message, bool nonfatal, {StackTrace? stacktrace, Map<String, Object>? segmentation}) async {
    log('Calling "logExceptionManual":[$message] nonfatal:[$nonfatal]');
    stacktrace ??= StackTrace.current;
    final result = logException('$message\n$stacktrace', nonfatal, segmentation);
    return result;
  }

  /// Internal callback to record 'FlutterError.onError' errors
  ///
  /// Must call [enableCrashReporting()] to enable it
  static void _recordFlutterError(FlutterErrorDetails details) {
    log('_recordFlutterError, Flutter error caught by Countly:');
    if (!_enableCrashReportingFlag) {
      log('_recordFlutterError, Crash Reporting must be enabled to report crash on Countly', logLevel: LogLevel.WARNING);
      return;
    }

    _internalRecordError(details.exceptionAsString(), details.stack);
  }

  /// Callback to catch and report Dart errors, [enableCrashReporting()] must call before [initWithConfig] to make it work.
  ///
  static Future<void> recordDartError(exception, StackTrace stack) async {
    log('recordDartError, Error caught by Countly :');
    if (!_enableCrashReportingFlag) {
      log('recordDartError, Crash Reporting must be enabled to report crash on Countly', logLevel: LogLevel.WARNING);
      return;
    }
    _internalRecordError(exception, stack);
  }

  /// A common call for crashes coming from [_recordFlutterError] and [recordDartError]
  ///
  /// They are then further reported to countly
  static void _internalRecordError(exception, StackTrace? stack) {
    if (!_instance._countlyState.isInitialized) {
      log('_internalRecordError, countly is not initialized', logLevel: LogLevel.WARNING);
      return;
    }

    log('_internalRecordError, Exception : ${exception.toString()}');
    if (stack != null) {
      log('\n_internalRecordError, Stack : $stack');
    }

    stack ??= StackTrace.fromString('');
    try {
      unawaited(logException('${exception.toString()}\n$stack', true));
    } catch (e) {
      log('_internalRecordError, Sending crash report to Countly failed: $e');
    }
  }

  /// Enable campaign attribution reporting to Countly.
  /// This does not do anything
  /// returns error message
  @Deprecated('This function is deprecated, please use "recordIndirectAttribution" instead')
  static Future<String?> enableAttribution() async {
    log('Calling enableAttribution');
    String error = 'enableAttribution is deprecated, use recordIndirectAttribution instead';
    log(error);
    return 'Error : $error';
  }

  /// set attribution Id for campaign attribution reporting.
  /// If this is call for iOS then 'attributionID' is IDFA
  /// If this is call for Android then 'attributionID' is ADID
  /// returns error or success message
  @Deprecated('This function is deprecated, please use "recordIndirectAttribution" instead')
  static Future<String?> recordAttributionID(String attributionID) async {
    if (!_instance._countlyState.isInitialized) {
      String message = '"initWithConfig" must be called before "recordAttributionID"';
      log('recordAttributionID, $message', logLevel: LogLevel.ERROR);
      return message;
    }
    log('Calling recordAttributionID: [$attributionID]');
    log('recordAttributionID is deprecated, use recordIndirectAttribution instead');
    if (attributionID.isEmpty) {
      String error = 'recordAttributionID, attributionID cannot be empty';
      log(error);
      return 'Error : $error';
    }
    Map<String, String> attributionValues = {};
    if (Platform.isIOS) {
      attributionValues[AttributionKey.IDFA] = attributionID;
    } else {
      attributionValues[AttributionKey.AdvertisingID] = attributionID;
    }
    final String? result = await recordIndirectAttribution(attributionValues);
    return result;
  }

  /// set indirect attribution Id for campaign attribution reporting.
  /// Use 'AttributionKey' to set key of IDFA and ADID
  /// returns error or success message
  static Future<String?> recordIndirectAttribution(Map<String, String> attributionValues) async {
    if (!_instance._countlyState.isInitialized) {
      String message = '"initWithConfig" must be called before "recordIndirectAttribution"';
      log('recordIndirectAttribution, $message', logLevel: LogLevel.ERROR);
      return message;
    }
    int attributionValuesCount = attributionValues.length;
    log('Calling recordIndirectAttribution: [$attributionValuesCount]');
    attributionValues.forEach((k, v) {
      if (k.isEmpty) {
        String error = 'recordIndirectAttribution, Key should not be empty, ignoring that key-value pair';
        log(error);
        attributionValues.removeWhere((key, value) => key == k && value == v);
      }
    });
    List<dynamic> args = [];
    args.add(attributionValues);
    final String? result = await _channel.invokeMethod('recordIndirectAttribution', <String, dynamic>{'data': json.encode(args)});
    return result;
  }

  /// set direct attribution Id for campaign attribution reporting.
  /// returns error or success message
  static Future<String?> recordDirectAttribution(String campaignType, String campaignData) async {
    if (!_instance._countlyState.isInitialized) {
      String message = '"initWithConfig" must be called before "recordDirectAttribution"';
      log('recordDirectAttribution, $message', logLevel: LogLevel.ERROR);
      return message;
    }
    log('Calling recordDirectAttribution: [$campaignType] with campaignData: [$campaignData]');
    if (campaignType.isEmpty) {
      String error = 'recordDirectAttribution, campaignId cannot be empty';
      log(error);
      return 'Error : $error';
    }
    List<String> args = [];
    args.add(campaignType);
    args.add(campaignData);
    final String? result = await _channel.invokeMethod('recordDirectAttribution', <String, dynamic>{'data': json.encode(args)});
    return result;
  }

  static Map<String, dynamic> _configToJson(CountlyConfig config) {
    final Map<String, dynamic> countlyConfig = {};
    try {
      countlyConfig['appKey'] = config.appKey;
      countlyConfig['serverURL'] = config.serverURL;

      final deviceID = config.deviceID?.trim();
      if (deviceID == null) {
        log('"_configToJson", no device ID provided', logLevel: LogLevel.INFO);
      } else if (deviceID.isEmpty) {
        log('"_configToJson", device ID cannot be an empty string.', logLevel: LogLevel.WARNING);
      } else {
        countlyConfig['deviceID'] = deviceID;
        log('"_configToJson", Device ID provided: [$deviceID]', logLevel: LogLevel.INFO);
      }

      if (config.customCrashSegment != null) {
        log('"_configToJson", value provided for customCrashSegment: [${config.customCrashSegment}]', logLevel: LogLevel.INFO);
        countlyConfig['customCrashSegment'] = config.customCrashSegment;
      }

      if (config.providedUserProperties != null) {
        log('"_configToJson", value for providedUserProperties: [${config.providedUserProperties}]', logLevel: LogLevel.INFO);
        countlyConfig['providedUserProperties'] = config.providedUserProperties;
      }

      if (config.consents != null) {
        log('"_configToJson", value provided for consents: [${config.consents}]', logLevel: LogLevel.INFO);
        countlyConfig['consents'] = config.consents;
      }
      if (config.tamperingProtectionSalt != null) {
        log('"_configToJson", value provided for tamperingProtectionSalt: [${config.tamperingProtectionSalt}]', logLevel: LogLevel.INFO);
        countlyConfig['tamperingProtectionSalt'] = config.tamperingProtectionSalt;
      }
      if (config.eventQueueSizeThreshold != null) {
        log('"_configToJson", value provided for eventQueueSizeThreshold: [${config.eventQueueSizeThreshold}]', logLevel: LogLevel.INFO);
        countlyConfig['eventQueueSizeThreshold'] = config.eventQueueSizeThreshold;
      }
      if (config.sessionUpdateTimerDelay != null) {
        log('"_configToJson", value provided for sessionUpdateTimerDelay: [${config.sessionUpdateTimerDelay}]', logLevel: LogLevel.INFO);
        countlyConfig['sessionUpdateTimerDelay'] = config.sessionUpdateTimerDelay;
      }
      if (config.starRatingTextTitle != null) {
        log('"_configToJson", value provided for starRatingTextTitle: [${config.starRatingTextTitle}]', logLevel: LogLevel.INFO);
        countlyConfig['starRatingTextTitle'] = config.starRatingTextTitle;
      }
      if (config.starRatingTextMessage != null) {
        log('"_configToJson", value provided for starRatingTextMessage: [${config.starRatingTextMessage}]', logLevel: LogLevel.INFO);
        countlyConfig['starRatingTextMessage'] = config.starRatingTextMessage;
      }
      if (config.starRatingTextDismiss != null) {
        log('"_configToJson", value provided for starRatingTextDismiss: [${config.starRatingTextDismiss}]', logLevel: LogLevel.INFO);
        countlyConfig['starRatingTextDismiss'] = config.starRatingTextDismiss;
      }
      if (config.loggingEnabled != null) {
        log('"_configToJson", value provided for loggingEnabled: [${config.loggingEnabled}]', logLevel: LogLevel.INFO);
        countlyConfig['loggingEnabled'] = config.loggingEnabled;
      }
      if (config.locationDisabled) {
        log('"_configToJson", value provided for locationDisabled: [${config.locationDisabled}]', logLevel: LogLevel.INFO);
        countlyConfig['locationDisabled'] = config.locationDisabled;
      }
      if (config.httpPostForced != null) {
        log('"_configToJson", value provided for httpPostForced: [${config.httpPostForced}]', logLevel: LogLevel.INFO);
        countlyConfig['httpPostForced'] = config.httpPostForced;
      }
      if (config.customNetworkRequestHeaders != null) {
        log('"_configToJson", value provided for customNetworkRequestHeaders: [${config.customNetworkRequestHeaders}]', logLevel: LogLevel.INFO);
        countlyConfig['customNetworkRequestHeaders'] = config.customNetworkRequestHeaders;
      }
      if (config.shouldRequireConsent != null) {
        log('"_configToJson", value provided for shouldRequireConsent: [${config.shouldRequireConsent}]', logLevel: LogLevel.INFO);
        countlyConfig['shouldRequireConsent'] = config.shouldRequireConsent;
      }
      if (config.enableUnhandledCrashReporting != null) {
        log('"_configToJson", value provided for enableUnhandledCrashReporting: [${config.enableUnhandledCrashReporting}]', logLevel: LogLevel.INFO);
        countlyConfig['enableUnhandledCrashReporting'] = config.enableUnhandledCrashReporting;
      }

      if (config.manualSessionEnabled != null) {
        log('"_configToJson", value provided for manualSessionEnabled: [${config.manualSessionEnabled}]', logLevel: LogLevel.INFO);
        countlyConfig['manualSessionEnabled'] = config.manualSessionEnabled;
      }

      if (config.maxRequestQueueSize != null) {
        log('"_configToJson", value provided for maxRequestQueueSize: [${config.maxRequestQueueSize}]', logLevel: LogLevel.INFO);
        countlyConfig['maxRequestQueueSize'] = config.maxRequestQueueSize;
      }

      if (config.locationCity != null) {
        log('"_configToJson", value provided for City: [${config.locationCity}]', logLevel: LogLevel.INFO);
        countlyConfig['locationCity'] = config.locationCity;
      }

      if (config.locationCountryCode != null) {
        log('"_configToJson", value provided for CountryCode: [${config.locationCountryCode}]', logLevel: LogLevel.INFO);
        countlyConfig['locationCountryCode'] = config.locationCountryCode;
      }

      if (config.locationGpsCoordinates != null) {
        log('"_configToJson", value provided for GpsCoordinates: [${config.locationGpsCoordinates}]', logLevel: LogLevel.INFO);
        countlyConfig['locationGpsCoordinates'] = config.locationGpsCoordinates;
      }

      if (config.locationIpAddress != null) {
        log('"_configToJson", value provided for IpAddress: [${config.locationIpAddress}]', logLevel: LogLevel.INFO);
        countlyConfig['locationIpAddress'] = config.locationIpAddress;
      }

      if (config.enableRemoteConfigAutomaticDownload != null) {
        log('"_configToJson", value provided for enableRemoteConfigAutomaticDownload: [${config.enableRemoteConfigAutomaticDownload}]', logLevel: LogLevel.INFO);
        countlyConfig['enableRemoteConfigAutomaticDownload'] = config.enableRemoteConfigAutomaticDownload;
      }

      if (config.daCampaignType != null) {
        log('"_configToJson", value provided for campaignType: [${config.daCampaignType}]', logLevel: LogLevel.INFO);
        countlyConfig['campaignType'] = config.daCampaignType;
      }

      if (config.daCampaignData != null) {
        log('"_configToJson", value provided for campaignData: [${config.daCampaignData}]', logLevel: LogLevel.INFO);
        countlyConfig['campaignData'] = config.daCampaignData;
      }

      if (config.iaAttributionValues != null) {
        log('"_configToJson", value provided for attributionValues: [${config.iaAttributionValues}]', logLevel: LogLevel.INFO);
        countlyConfig['attributionValues'] = config.iaAttributionValues;
      }

      if (config.globalViewSegmentation != null) {
        log('"_configToJson", value provided for globalViewSegmentation: [${config.globalViewSegmentation}]', logLevel: LogLevel.INFO);
        countlyConfig['globalViewSegmentation'] = config.globalViewSegmentation;
      }

      if (config.enableAllConsents) {
        log('"_configToJson", value provided for enableAllConsents: [${config.enableAllConsents}]', logLevel: LogLevel.INFO);
        countlyConfig['enableAllConsents'] = config.enableAllConsents;
      }

      if (config.autoEnrollABOnDownload) {
        log('"_configToJson", value provided for autoEnrollABOnDownload: [${config.autoEnrollABOnDownload}]', logLevel: LogLevel.INFO);
        countlyConfig['autoEnrollABOnDownload'] = config.autoEnrollABOnDownload;
      }

      if (config.requestDropAgeHours != null) {
        log('"_configToJson", value provided for requestDropAgeHours: [${config.requestDropAgeHours}]', logLevel: LogLevel.INFO);
        countlyConfig['requestDropAgeHours'] = config.requestDropAgeHours;
      }

      /// Experimental ---------------------------
      if (config.experimental.visibilityTracking) {
        log('"_configToJson", value provided for visibilityTracking: [${config.experimental.visibilityTracking}]', logLevel: LogLevel.INFO);
        countlyConfig['visibilityTracking'] = config.experimental.visibilityTracking;
      }
      if (config.experimental.previousNameRecording) {
        log('"_configToJson", value provided for previousNameRecording: [${config.experimental.previousNameRecording}]', logLevel: LogLevel.INFO);
        countlyConfig['previousNameRecording'] = config.experimental.previousNameRecording;
      }

      /// Experimental END ---------------------------

      /// APM ---------------------------
      if (config.apm.trackAppStartTime) {
        log('"_configToJson", value provided for trackAppStartTime: [${config.apm.trackAppStartTime}]', logLevel: LogLevel.INFO);
        countlyConfig['trackAppStartTime'] = config.apm.trackAppStartTime;
      }
      if (config.apm.enableForegroundBackground) {
        log('"_configToJson", value provided for enableForegroundBackground: [${config.apm.enableForegroundBackground}]', logLevel: LogLevel.INFO);
        countlyConfig['enableForegroundBackground'] = config.apm.enableForegroundBackground;
      }
      if (config.apm.enableManualAppLoaded) {
        log('"_configToJson", value provided for enableManualAppLoaded: [${config.apm.enableManualAppLoaded}]', logLevel: LogLevel.INFO);
        countlyConfig['enableManualAppLoaded'] = config.apm.enableManualAppLoaded;
      }
      if (config.apm.startTSOverride != 0) {
        log('"_configToJson", value provided for startTSOverride: [${config.apm.startTSOverride}]', logLevel: LogLevel.INFO);
        countlyConfig['startTSOverride'] = config.apm.startTSOverride;
      }
      // legacy
      if (config.recordAppStartTime != null) {
        log('"_configToJson", value provided for recordAppStartTime: [${config.recordAppStartTime}]', logLevel: LogLevel.INFO);
        countlyConfig['recordAppStartTime'] = config.recordAppStartTime;
      }

      /// APM END ---------------------------
      /// Internal Limits ---------------------------
      // Skipping logs for internal limits (change my mind)
      if (config.sdkInternalLimits.maxKeyLength > 0) {
        log('"_configToJson", value provided for maxKeyLength: [${config.sdkInternalLimits.maxKeyLength}]', logLevel: LogLevel.INFO);
        countlyConfig['maxKeyLength'] = config.sdkInternalLimits.maxKeyLength;
      }
      if (config.sdkInternalLimits.maxValueSize > 0) {
        log('"_configToJson", value provided for maxValueSize: [${config.sdkInternalLimits.maxValueSize}]', logLevel: LogLevel.INFO);
        countlyConfig['maxValueSize'] = config.sdkInternalLimits.maxValueSize;
      }
      if (config.sdkInternalLimits.maxSegmentationValues > 0) {
        log('"_configToJson", value provided for maxSegmentationValues: [${config.sdkInternalLimits.maxSegmentationValues}]', logLevel: LogLevel.INFO);
        countlyConfig['maxSegmentationValues'] = config.sdkInternalLimits.maxSegmentationValues;
      }
      if (config.sdkInternalLimits.maxBreadcrumbCount > 0) {
        log('"_configToJson", value provided for maxBreadcrumbCount: [${config.sdkInternalLimits.maxBreadcrumbCount}]', logLevel: LogLevel.INFO);
        countlyConfig['maxBreadcrumbCount'] = config.sdkInternalLimits.maxBreadcrumbCount;
      }
      if (config.sdkInternalLimits.maxStackTraceLineLength > 0) {
        log('"_configToJson", value provided for maxStackTraceLineLength: [${config.sdkInternalLimits.maxStackTraceLineLength}]', logLevel: LogLevel.INFO);
        countlyConfig['maxStackTraceLineLength'] = config.sdkInternalLimits.maxStackTraceLineLength;
      }
      if (config.sdkInternalLimits.maxStackTraceLinesPerThread > 0) {
        log('"_configToJson", value provided for maxStackTraceLinesPerThread: [${config.sdkInternalLimits.maxStackTraceLinesPerThread}]', logLevel: LogLevel.INFO);
        countlyConfig['maxStackTraceLinesPerThread'] = config.sdkInternalLimits.maxStackTraceLinesPerThread;
      }

      /// Internal Limits END ---------------------------
      log('"_configToJson", value provided for remoteConfigAutomaticTriggers: [${config.remoteConfigAutomaticTriggers}]', logLevel: LogLevel.INFO);
      countlyConfig['remoteConfigAutomaticTriggers'] = config.remoteConfigAutomaticTriggers;

      log('"_configToJson", value provided for remoteConfigValueCaching: [${config.remoteConfigValueCaching}]', logLevel: LogLevel.INFO);
      countlyConfig['remoteConfigValueCaching'] = config.remoteConfigValueCaching;
    } catch (e) {
      log('"_configToJson", Exception occur during converting config to json: $e', logLevel: LogLevel.ERROR);
    }
    return countlyConfig;
  }
}

class CountlyPresentableFeedback {
  CountlyPresentableFeedback(this.widgetId, this.type, this.name);

  final String widgetId;
  final String type;
  final String name;

  static CountlyPresentableFeedback fromJson(Map json) {
    return CountlyPresentableFeedback(json['id'], json['type'], json['name']);
  }
}

class FeedbackWidgetsResponse {
  FeedbackWidgetsResponse(this.presentableFeedback, this.error);

  final String? error;
  final List<CountlyPresentableFeedback> presentableFeedback;
}
