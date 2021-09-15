import 'dart:async';
import 'dart:convert';
import 'dart:js';

import 'package:countly_flutter/src/countly_base.dart';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:pedantic/pedantic.dart';

import 'models/countly_presentable_feedback.dart';
import 'models/feedback_widget_response.dart';
import 'interop/countly_js.dart';
import 'models/log_level.dart';

class CountlyApp implements CountlyBase {
  /// Used to determine if log messages should be printed to the console
  /// its value should be updated from [setLoggingEnabled(bool flag)].
  static bool _isDebug = false;

  /// Used to determine if init is called.
  /// its value should be updated from [init(...)].
  static bool _isInitialized = false;

  static final String tag = 'CountlyFlutter';

  /// Flag to determine if crash logging functionality should be enabled
  /// If false the intercepted crashes will be ignored
  /// Set true when user enabled crash logging
  static bool _enableCrashReportingFlag = false;

  static Map<String, String> messagingMode = {
    'TEST': '1',
    'PRODUCTION': '0',
    'ADHOC': '2'
  };
  static Map<String, String> deviceIDType = {
    'TemporaryDeviceID': 'TemporaryDeviceID'
  };

  @override
  void log(String? message, {LogLevel logLevel = LogLevel.DEBUG}) async {
    String logLevelStr = describeEnum(logLevel);
    if (_isDebug) {
      print('[$tag] $logLevelStr: $message');
    }
  }

  @override
  Future<String?> init(String serverUrl, String appKey,
      [String? deviceId]) async {
    _isInitialized = true;
    CountlyJs.app_key = appKey;
    CountlyJs.url = serverUrl;
    CountlyJs.q.add([
      ['track_sessions'],
      ['track_pageview'],
      ['track_clicks'],
      ['track_scrolls']
    ]);
    return null;
  }

  @override
  Future<bool> isInitialized() async {
    return _isInitialized;
  }

  /// Replaces all requests with a different app key with the current app key.
  /// In request queue, if there are any request whose app key is different than the current app key,
  /// these requests' app key will be replaced with the current app key.
  @override
  Future<String?> replaceAllAppKeysInQueueWithCurrentAppKey() async {
    throw UnimplementedError();
  }

  /// Removes all requests with a different app key in request queue.
  /// In request queue, if there are any request whose app key is different than the current app key,
  /// these requests will be removed from request queue.
  @override
  Future<String?> removeDifferentAppKeysFromQueue() async {
    throw UnimplementedError();
  }

  /// Call this function when app is loaded, so that the app launch duration can be recorded.
  /// Should be called after init.
  @override
  Future<String?> appLoadingFinished() async {
    if (!_isInitialized) {
      log('appLoadingFinished, init must be called before appLoadingFinished',
          logLevel: LogLevel.WARNING);
      return 'init must be called before appLoadingFinished';
    }
    throw UnimplementedError();
  }

  @override
  Future<String?> recordEvent(Map<String, Object> options) async {
    options['key'] ??= '';
    String eventKey = options['key'].toString();

    if (eventKey.isEmpty) {
      String error = 'recordEvent, Valid Countly event key is required';
      log(error);
      return 'Error : $error';
    }

    options['count'] ??= 1;
    options['sum'] ??= '0';
    options['duration'] ??= '0';

    Segmentation? seg;

    if (options['segmentation'] != null) {
      var segmentation = options['segmentation'] as Map;
      //TODO: Segmentation needs to be edited in Interop to take dynamic size Map
      segmentation.forEach((k, v) {
        seg = Segmentation(data: SegData(key: k, val: v));
      });
    }

    final args = CountlyEvent(
      key: eventKey,
      count: options['count'] as num,
      sum: options['sum'] as num,
      dur: options['duration'] as num,
      segmentation: seg,
    );

    CountlyJs.add_event(args);
    return null;
  }

  /// Record custom view to Countly.
  ///
  /// [String view] - name of the view
  /// [Map<String, Object> segmentation] - allows to add optional segmentation,
  /// Supported data type for segmentation values are String, int, double and bool
  @override
  Future<String?> recordView(String view,
      [Map<String, Object>? segmentation]) async {
    if (view.isEmpty) {
      String error =
          'recordView, Trying to record view with empty view name, ignoring request';
      log(error);
      return 'Error : $error';
    }

    //CountlyJs.track_pageview(view);
    CountlyJs.q.addAll(['track_pageview', view]);
    return null;
  }

  @override
  Future<String?> setUserData(Map<String, Object> options) async {
    throw UnimplementedError();
  }

  /// This method will ask for permission, enables push notification and send push token to countly server.
  /// Should be call after Countly init
  @override
  Future<String?> askForNotificationPermission() async {
    throw UnimplementedError();
  }

  /// Disable push notifications feature, by default it is enabled.
  /// Currently implemented for iOS only
  /// Should be called before Countly init
  @override
  Future<String?> disablePushNotifications() async {
    throw UnimplementedError();
  }

  /// Set messaging mode for push notifications
  /// Should be call before Countly init
  @override
  Future<String?> pushTokenType(String tokenType) async {
    throw UnimplementedError();
  }

  /// Set callback to receive push notifications
  /// @param { callback listner } callback
  @override
  Future<String?> onNotification(Function callback) async {
    throw UnimplementedError();
  }

  @override
  Future<String?> start() async {
    throw UnimplementedError();
  }

  @override
  Future<String?> manualSessionHandling() async {
    throw UnimplementedError();
  }

  @override
  Future<String?> stop() async {
    throw UnimplementedError();
  }

  @override
  Future<String?> updateSessionPeriod() async {
    throw UnimplementedError();
  }

  /// Sets the interval for the automatic session update calls
  /// min value 1 (1 second),
  /// max value 600 (10 minutes)
  /// [int sessionInterval]- delay in seconds
  @override
  Future<String?> updateSessionInterval(int sessionInterval) async {
    if (_isInitialized) {
      log('updateSessionInterval should be called before init',
          logLevel: LogLevel.WARNING);
      return 'updateSessionInterval should be called before init';
    }
    throw UnimplementedError();
  }

  /// Events get grouped together and are sent either every minute or after the unsent event count reaches a threshold. By default it is 10
  /// Should be call before Countly init
  @override
  Future<String?> eventSendThreshold(int limit) async {
    throw UnimplementedError();
  }

  @override
  Future<String?> storedRequestsLimit() async {
    throw UnimplementedError();
  }

  @override
  Future<String?> setOptionalParametersForInitialization(
      Map<String, Object> options) async {
    throw UnimplementedError();
  }

  /// Get currently used device Id.
  /// Should be call after Countly init
  @override
  Future<String?> getCurrentDeviceId() async {
    if (!_isInitialized) {
      log('getCurrentDeviceId, init must be called before getCurrentDeviceId',
          logLevel: LogLevel.WARNING);
      return 'init must be called before getCurrentDeviceId';
    }
    throw UnimplementedError();
  }

  @override
  Future<String?> changeDeviceId(String newDeviceID, bool onServer) async {
    if (newDeviceID.isEmpty) {
      String error = 'changeDeviceId, deviceId cannot be null or empty';
      log(error);
      return 'Error : $error';
    }
    throw UnimplementedError();
  }

  @override
  Future<String?> addCrashLog(String logs) async {
    if (logs.isEmpty) {
      String error = "addCrashLog, Can't add a null or empty crash logs";
      log(error);
      return 'Error : $error';
    }
    throw UnimplementedError();
  }

  /// Set to true if you want to enable countly internal debugging logs
  /// Should be call before Countly init
  @override
  Future<String?> setLoggingEnabled(bool flag) async {
    List<String> args = [];
    _isDebug = flag;
    args.add(flag.toString());
    return null;
  }

  /// Set the optional salt to be used for calculating the checksum of requested data which will be sent with each request, using the &checksum field
  /// Should be call before Countly init
  @override
  Future<String?> enableParameterTamperingProtection(String salt) async {
    if (salt.isEmpty) {
      String error = 'enableParameterTamperingProtection, salt cannot be empty';
      log(error);
      return 'Error : $error';
    }
    throw UnimplementedError();
  }

  /// Set to 'true' if you want HTTP POST to be used for all requests
  /// Should be call before Countly init
  @override
  Future<String?> setHttpPostForced(bool isEnabled) async {
    throw UnimplementedError();
  }

  /// Set user initial location
  /// Should be call before init
  @override
  Future<String?> setLocationInit(String countryCode, String city,
      String gpsCoordinates, String ipAddress) async {
    throw UnimplementedError();
  }

  @override
  Future<String?> setLocation(String latitude, String longitude) async {
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
    throw UnimplementedError();
  }

  @override
  Future<String?> setProperty(String keyName, String keyValue) async {
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
    throw UnimplementedError();
  }

  @override
  Future<String?> increment(String keyName) async {
    if (keyName.isEmpty) {
      String error = 'increment, key cannot be empty';
      log(error);
      return 'Error : $error';
    }
    throw UnimplementedError();
  }

  @override
  Future<String?> incrementBy(String keyName, int keyIncrement) async {
    if (keyName.isEmpty) {
      String error = 'incrementBy, key cannot be empty';
      log(error);
      return 'Error : $error';
    }
    throw UnimplementedError();
  }

  @override
  Future<String?> multiply(String keyName, int multiplyValue) async {
    if (keyName.isEmpty) {
      String error = 'multiply, key cannot be empty';
      log(error);
      return 'Error : $error';
    }
    throw UnimplementedError();
  }

  @override
  Future<String?> saveMax(String keyName, int saveMax) async {
    if (keyName.isEmpty) {
      String error = 'saveMax, key cannot be empty';
      log(error);
      return 'Error : $error';
    }
    throw UnimplementedError();
  }

  @override
  Future<String?> saveMin(String keyName, int saveMin) async {
    if (keyName.isEmpty) {
      String error = 'saveMin, key cannot be empty';
      log(error);
      return 'Error : $error';
    }
    throw UnimplementedError();
  }

  @override
  Future<String?> setOnce(String keyName, String setOnce) async {
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
    throw UnimplementedError();
  }

  @override
  Future<String?> pushUniqueValue(String type, String pushUniqueValue) async {
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
    throw UnimplementedError();
  }

  @override
  Future<String?> pushValue(String type, String pushValue) async {
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
    throw UnimplementedError();
  }

  @override
  Future<String?> pullValue(String type, String pullValue) async {
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
    throw UnimplementedError();
  }

  /// Set that consent should be required for features to work.
  /// Should be call before Countly init
  @override
  Future<String?> setRequiresConsent(bool flag) async {
    throw UnimplementedError();
  }

  /// Give consent for specific features.
  /// Should be call before Countly init
  @override
  Future<String?> giveConsentInit(List<String> consents) async {
    if (consents.isEmpty) {
      String error = 'giveConsentInit, consents List is empty';
      log(error, logLevel: LogLevel.WARNING);
    }
    throw UnimplementedError();
  }

  @override
  Future<String?> giveConsent(List<String> consents) async {
    if (consents.isEmpty) {
      String error = 'giveConsent, consents List is empty';
      log(error, logLevel: LogLevel.WARNING);
    }
    throw UnimplementedError();
  }

  @override
  Future<String?> removeConsent(List<String> consents) async {
    if (consents.isEmpty) {
      String error = 'removeConsent, consents List is empty';
      log(error, logLevel: LogLevel.WARNING);
    }
    throw UnimplementedError();
  }

  /// Give consent for all features
  /// Should be call after Countly init
  @override
  Future<String?> giveAllConsent() async {
    throw UnimplementedError();
  }

  @override
  Future<String?> removeAllConsent() async {
    throw UnimplementedError();
  }

  /// Set Automatic value download happens when the SDK is initiated or when the device ID is changed.
  /// Should be call before Countly init
  @override
  Future<String?> setRemoteConfigAutomaticDownload(Function callback) async {
    throw UnimplementedError();
  }

  @override
  Future<String?> remoteConfigUpdate(Function callback) async {
    throw UnimplementedError();
  }

  @override
  Future<String?> updateRemoteConfigForKeysOnly(
      List<String> keys, Function callback) async {
    if (keys.isEmpty) {
      String error = 'updateRemoteConfigForKeysOnly, keys List is empty';
      log(error, logLevel: LogLevel.WARNING);
    }
    throw UnimplementedError();
  }

  @override
  Future<String?> updateRemoteConfigExceptKeys(
      List<String> keys, Function callback) async {
    if (keys.isEmpty) {
      String error = 'updateRemoteConfigExceptKeys, keys List is empty';
      log(error, logLevel: LogLevel.WARNING);
    }
    throw UnimplementedError();
  }

  @override
  Future<String?> remoteConfigClearValues(Function callback) async {
    throw UnimplementedError();
  }

  @override
  Future<String?> getRemoteConfigValueForKey(
      String key, Function callback) async {
    if (key.isEmpty) {
      String error = 'getRemoteConfigValueForKey, key cannot be empty';
      log(error);
      return 'Error : $error';
    }
    throw UnimplementedError();
  }

  /// Set's the text's for the different fields in the star rating dialog. Set value null if for some field you want to keep the old value
  /// [String starRatingTextTitle] - dialog's title text (Only for Android)
  /// [String starRatingTextMessage] - dialog's message text
  /// [String starRatingTextDismiss] - dialog's dismiss buttons text (Only for Android)
  @override
  Future<String?> setStarRatingDialogTexts(String starRatingTextTitle,
      String starRatingTextMessage, String starRatingTextDismiss) async {
    throw UnimplementedError();
  }

  @override
  Future<String?> askForStarRating() async {
    throw UnimplementedError();
  }

  @override
  Future<String?> askForFeedback(
      String widgetId, String? closeButtonText) async {
    if (widgetId.isEmpty) {
      String error = 'askForFeedback, widgetId cannot be empty';
      log(error);
      return 'Error : $error';
    }
    throw UnimplementedError();
  }

  /// Get a list of available feedback widgets for this device ID
  @override
  Future<FeedbackWidgetsResponse> getAvailableFeedbackWidgets() async {
    throw UnimplementedError();
  }

  /// Present a chosen feedback widget
  /// [CountlyPresentableFeedback widgetInfo] - Get available list of feedback widgets by calling 'getAvailableFeedbackWidgets()' and pass the widget object as a parameter.
  /// [String closeButtonText] - Text for cancel/close button.
  @override
  Future<String?> presentFeedbackWidget(
      CountlyPresentableFeedback widgetInfo, String closeButtonText) async {
    throw UnimplementedError();
  }

  /// Downloads widget info and returns [widgetData, error]
  /// Currently implemented for Android only
  /// [CountlyPresentableFeedback widgetInfo] - identifies the specific widget for which you want to download widget data
  @override
  Future<List> getFeedbackWidgetData(
      CountlyPresentableFeedback widgetInfo) async {
    throw UnimplementedError();
  }

  /// Report widget info and do data validation
  /// Currently implemented for Android only
  /// [CountlyPresentableFeedback widgetInfo] - identifies the specific widget for which the feedback is filled out
  /// [Map<String, dynamic> widgetData] - widget data for this specific widget
  /// [Map<String, Object> widgetResult] - segmentation of the filled out feedback. If this segmentation is null, it will be assumed that the survey was closed before completion and mark it appropriately
  @override
  Future<String?> reportFeedbackWidgetManually(
      CountlyPresentableFeedback widgetInfo,
      Map<String, dynamic> widgetData,
      Map<String, Object> widgetResult) async {
    throw UnimplementedError();
  }

  @override
  Future<String?> startEvent(String key) async {
    if (key.isEmpty) {
      String error = "startEvent, Can't start event with empty key";
      log(error);
      return 'Error : $error';
    }
    throw UnimplementedError();
  }

  @override
  Future<String?> endEvent(Map<String, Object> options) async {
    String eventKey = options['key'] != null ? options['key'].toString() : '';

    if (eventKey.isEmpty) {
      String error = "endEvent, Can't end event with a null or empty key";
      log(error);
      return 'Error : $error';
    }
    throw UnimplementedError();
  }

  /// Call used for testing error handling
  /// Should not be used
  @override
  Future<String?> throwNativeException() async {
    throw UnimplementedError();
  }

  /// Enable crash reporting to report uncaught errors to Countly.
  /// Should be call before Countly init
  @override
  Future<String?> enableCrashReporting() async {
    FlutterError.onError = _recordFlutterError;
    _enableCrashReportingFlag = true;
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
  @override
  Future<String?> logException(String exception, bool nonfatal,
      [Map<String, Object>? segmentation]) async {
    List<String> args = [];
    args.add(exception);
    args.add(nonfatal.toString());
    if (segmentation != null) {
      segmentation.forEach((k, v) {
        args.add(k.toString());
        args.add(v.toString());
      });
    }
    // CountlyJs.log_error(
    //   Error(data: SegData(key: 'data', val: json.encode(args))),
    //   null,
    // );
    CountlyJs.q.addAll([
      'track_errors',
      Error(data: SegData(key: 'data', val: json.encode(args))),
    ]);
    return null;
  }

  /// Set optional key/value segment added for crash reports.
  /// Should be call before Countly init
  @override
  Future<String?> setCustomCrashSegment(Map<String, Object> segments) async {
    throw UnimplementedError();
  }

  @override
  Future<String?> startTrace(String traceKey) async {
    throw UnimplementedError();
  }

  @override
  Future<String?> cancelTrace(String traceKey) async {
    throw UnimplementedError();
  }

  @override
  Future<String?> clearAllTraces() async {
    throw UnimplementedError();
  }

  @override
  Future<String?> endTrace(
      String traceKey, Map<String, int>? customMetric) async {
    throw UnimplementedError();
  }

  @override
  Future<String?> recordNetworkTrace(
      String networkTraceKey,
      int responseCode,
      int requestPayloadSize,
      int responsePayloadSize,
      int startTime,
      int endTime) async {
    throw UnimplementedError();
  }

  /// Enable APM features, which includes the recording of app start time.
  /// Should be call before Countly init
  @override
  Future<String?> enableApm() async {
    throw UnimplementedError();
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
  @override
  Future<String?> logExceptionEx(Exception exception, bool nonfatal,
      {StackTrace? stacktrace, Map<String, Object>? segmentation}) async {
    stacktrace ??= StackTrace.current;
    final result = logException(
        '${exception.toString()}\n\n$stacktrace', nonfatal, segmentation);
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
  @override
  Future<String?> logExceptionManual(String message, bool nonfatal,
      {StackTrace? stacktrace, Map<String, Object>? segmentation}) async {
    stacktrace ??= StackTrace.current;
    final result =
        logException('$message\n\n$stacktrace', nonfatal, segmentation);
    return result;
  }

  /// Internal callback to record 'FlutterError.onError' errors
  ///
  /// Must call [enableCrashReporting()] to enable it
  Future<void> _recordFlutterError(FlutterErrorDetails details) async {
    log('_recordFlutterError, Flutter error caught by Countly:');
    if (!_enableCrashReportingFlag) {
      log('_recordFlutterError, Crash Reporting must be enabled to report crash on Countly',
          logLevel: LogLevel.WARNING);
      return;
    }

    unawaited(_internalRecordError(details.exceptionAsString(), details.stack));
  }

  /// Callback to catch and report Dart errors, [enableCrashReporting()] must call before [init] to make it work.
  ///
  /// This callback has to be provided when the app is about to be run.
  /// It has to be done inside a custom Zone by providing [Countly.recordDartError] in onError() callback.
  ///
  /// ```
  /// void main() {
  ///   runZonedGuarded<Future<void>>(() async {
  ///     runApp(MyApp());
  ///   }, Countly.recordDartError);
  /// }
  ///
  @override
  Future<void> recordDartError(dynamic exception, StackTrace stack,
      {dynamic context}) async {
    log('recordError, Error caught by Countly :');
    if (!_enableCrashReportingFlag) {
      log('recordError, Crash Reporting must be enabled to report crash on Countly',
          logLevel: LogLevel.WARNING);
      return;
    }
    unawaited(_internalRecordError(exception, stack));
  }

  /// A common call for crashes coming from [_recordFlutterError] and [recordDartError]
  ///
  /// They are then further reported to countly
  Future<void> _internalRecordError(
      dynamic exception, StackTrace? stack) async {
    if (!_isInitialized) {
      log('_internalRecordError, countly is not initialized',
          logLevel: LogLevel.WARNING);
      return;
    }
    log('_internalRecordError, Exception : ${exception.toString()}');
    if (stack != null) log('\n_internalRecordError, Stack : $stack');
    stack ??= StackTrace.fromString('');
    try {
      unawaited(logException('${exception.toString()}\n\n$stack', true));
    } catch (e) {
      log('Sending crash report to Countly failed: $e');
    }
  }

  /// Enable campaign attribution reporting to Countly.
  /// For iOS use 'recordAttributionID' instead of 'enableAttribution'
  /// Should be call before Countly init
  @override
  Future<String?> enableAttribution() async {
    throw UnimplementedError();
  }

  /// set attribution Id for campaign attribution reporting.
  /// Currently implemented for iOS only
  /// For Android just call the enableAttribution to enable campaign attribution.
  @override
  Future<String?> recordAttributionID(String attributionID) async {
    if (!Platform.isIOS) {
      return 'recordAttributionID : To be implemented';
    }
    if (attributionID.isEmpty) {
      String error = 'recordAttributionID, attributionID cannot be empty';
      log(error);
      return 'Error : $error';
    }
    throw UnimplementedError();
  }
}
