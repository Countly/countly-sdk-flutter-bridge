export 'package:countly_flutter/src/models/countly_presentable_feedback.dart';
export 'package:countly_flutter/src/models/feedback_widget_response.dart';
export 'package:countly_flutter/src/models/log_level.dart';

import 'src/countly_base.dart';
import 'src/models/countly_presentable_feedback.dart';
import 'src/models/feedback_widget_response.dart';
import 'src/models/log_level.dart';
import 'src/stub.dart'
  if (dart.library.js) 'src/countly_web.dart'
  if (dart.library.io) 'src/countly_mobile.dart';

class Countly {
  static final CountlyBase _countly = CountlyApp();

  static final String tag = 'CountlyFlutter';

  static Map<String, String> messagingMode = {
    'TEST': '1',
    'PRODUCTION': '0',
    'ADHOC': '2'
  };
  static Map<String, String> deviceIDType = {
    'TemporaryDeviceID': 'TemporaryDeviceID'
  };

  static void log(String? message, {LogLevel logLevel = LogLevel.DEBUG}) =>
      _countly.log(message);

  static Future<String?> init(String serverUrl, String appKey,
          [String? deviceId]) =>
      _countly.init(serverUrl, appKey);

  static Future<bool> isInitialized() => _countly.isInitialized();

  /// Replaces all requests with a different app key with the current app key.
  /// In request queue, if there are any request whose app key is different than the current app key,
  /// these requests' app key will be replaced with the current app key.
  static Future<String?> replaceAllAppKeysInQueueWithCurrentAppKey() =>
      _countly.replaceAllAppKeysInQueueWithCurrentAppKey();

  /// Removes all requests with a different app key in request queue.
  /// In request queue, if there are any request whose app key is different than the current app key,
  /// these requests will be removed from request queue.
  static Future<String?> removeDifferentAppKeysFromQueue() =>
      _countly.removeDifferentAppKeysFromQueue();

  /// Call this function when app is loaded, so that the app launch duration can be recorded.
  /// Should be called after init.
  static Future<String?> appLoadingFinished() => _countly.appLoadingFinished();

  static bool isNullOrEmpty(String? s) => s == null || s.isEmpty;

  static Future<String?> recordEvent(Map<String, Object> options) =>
      _countly.recordEvent(options);

  /// Record custom view to Countly.
  ///
  /// [String view] - name of the view
  /// [Map<String, Object> segmentation] - allows to add optional segmentation,
  /// Supported data type for segmentation values are String, int, double and bool
  static Future<String?> recordView(String view,
          [Map<String, Object>? segmentation]) =>
      _countly.recordView(view);

  static Future<String?> setUserData(Map<String, Object> options) =>
      _countly.setUserData(options);

  /// This method will ask for permission, enables push notification and send push token to countly server.
  /// Should be call after Countly init
  static Future<String?> askForNotificationPermission() =>
      _countly.askForNotificationPermission();

  /// Disable push notifications feature, by default it is enabled.
  /// Currently implemented for iOS only
  /// Should be called before Countly init
  static Future<String?> disablePushNotifications() =>
      _countly.disablePushNotifications();

  /// Set messaging mode for push notifications
  /// Should be call before Countly init
  static Future<String?> pushTokenType(String tokenType) =>
      _countly.pushTokenType(tokenType);

  /// Set callback to receive push notifications
  /// @param { callback listner } callback
  static Future<String?> onNotification(Function callback) =>
      _countly.onNotification(callback);

  static Future<String?> start() => _countly.start();

  static Future<String?> manualSessionHandling() =>
      _countly.manualSessionHandling();

  static Future<String?> stop() => _countly.stop();

  static Future<String?> updateSessionPeriod() =>
      _countly.updateSessionPeriod();

  /// Sets the interval for the automatic session update calls
  /// min value 1 (1 second),
  /// max value 600 (10 minutes)
  /// [int sessionInterval]- delay in seconds
  static Future<String?> updateSessionInterval(int sessionInterval) =>
      _countly.updateSessionInterval(sessionInterval);

  /// Events get grouped together and are sent either every minute or after the unsent event count reaches a threshold. By default it is 10
  /// Should be call before Countly init
  static Future<String?> eventSendThreshold(int limit) =>
      _countly.eventSendThreshold(limit);

  static Future<String?> storedRequestsLimit() =>
      _countly.storedRequestsLimit();

  static Future<String?> setOptionalParametersForInitialization(
          Map<String, Object> options) =>
      _countly.setOptionalParametersForInitialization(options);

  /// Get currently used device Id.
  /// Should be call after Countly init
  static Future<String?> getCurrentDeviceId() => _countly.getCurrentDeviceId();

  static Future<String?> changeDeviceId(String newDeviceID, bool onServer) =>
      _countly.changeDeviceId(newDeviceID, onServer);

  static Future<String?> addCrashLog(String logs) => _countly.addCrashLog(logs);

  /// Set to true if you want to enable countly internal debugging logs
  /// Should be call before Countly init
  static Future<String?> setLoggingEnabled(bool flag) =>
      _countly.setLoggingEnabled(flag);

  /// Set the optional salt to be used for calculating the checksum of requested data which will be sent with each request, using the &checksum field
  /// Should be call before Countly init
  static Future<String?> enableParameterTamperingProtection(String salt) =>
      _countly.enableParameterTamperingProtection(salt);

  /// Set to 'true' if you want HTTP POST to be used for all requests
  /// Should be call before Countly init
  static Future<String?> setHttpPostForced(bool isEnabled) =>
      _countly.setHttpPostForced(isEnabled);

  /// Set user initial location
  /// Should be call before init
  static Future<String?> setLocationInit(String countryCode, String city,
          String gpsCoordinates, String ipAddress) =>
      _countly.setLocationInit(countryCode, city, gpsCoordinates, ipAddress);

  static Future<String?> setLocation(String latitude, String longitude) =>
      _countly.setLocation(latitude, longitude);

  static Future<String?> setProperty(String keyName, String keyValue) =>
      _countly.setProperty(keyName, keyValue);

  static Future<String?> increment(String keyName) =>
      _countly.increment(keyName);

  static Future<String?> incrementBy(String keyName, int keyIncrement) =>
      _countly.incrementBy(keyName, keyIncrement);

  static Future<String?> multiply(String keyName, int multiplyValue) =>
      _countly.multiply(keyName, multiplyValue);

  static Future<String?> saveMax(String keyName, int saveMax) =>
      _countly.saveMax(keyName, saveMax);

  static Future<String?> saveMin(String keyName, int saveMin) =>
      _countly.saveMin(keyName, saveMin);

  static Future<String?> setOnce(String keyName, String setOnce) =>
      _countly.setOnce(keyName, setOnce);

  static Future<String?> pushUniqueValue(String type, String pushUniqueValue) =>
      _countly.pushUniqueValue(type, pushUniqueValue);

  static Future<String?> pushValue(String type, String pushValue) =>
      _countly.pushValue(type, pushValue);

  static Future<String?> pullValue(String type, String pullValue) =>
      _countly.pullValue(type, pullValue);

  /// Set that consent should be required for features to work.
  /// Should be call before Countly init
  static Future<String?> setRequiresConsent(bool flag) =>
      _countly.setRequiresConsent(flag);

  /// Give consent for specific features.
  /// Should be call before Countly init
  static Future<String?> giveConsentInit(List<String> consents) =>
      _countly.giveConsentInit(consents);

  static Future<String?> giveConsent(List<String> consents) =>
      _countly.giveConsent(consents);

  static Future<String?> removeConsent(List<String> consents) =>
      _countly.removeConsent(consents);

  /// Give consent for all features
  /// Should be call after Countly init
  static Future<String?> giveAllConsent() => _countly.giveAllConsent();

  static Future<String?> removeAllConsent() => _countly.removeAllConsent();

  /// Set Automatic value download happens when the SDK is initiated or when the device ID is changed.
  /// Should be call before Countly init
  static Future<String?> setRemoteConfigAutomaticDownload(Function callback) =>
      _countly.setRemoteConfigAutomaticDownload(callback);

  static Future<String?> remoteConfigUpdate(Function callback) =>
      _countly.remoteConfigUpdate(callback);

  static Future<String?> updateRemoteConfigForKeysOnly(
          List<String> keys, Function callback) =>
      _countly.updateRemoteConfigForKeysOnly(keys, callback);

  static Future<String?> updateRemoteConfigExceptKeys(
          List<String> keys, Function callback) =>
      _countly.updateRemoteConfigExceptKeys(keys, callback);

  static Future<String?> remoteConfigClearValues(Function callback) =>
      _countly.remoteConfigClearValues(callback);

  static Future<String?> getRemoteConfigValueForKey(
          String key, Function callback) =>
      _countly.getRemoteConfigValueForKey(key, callback);

  /// Set's the text's for the different fields in the star rating dialog. Set value null if for some field you want to keep the old value
  /// [String starRatingTextTitle] - dialog's title text (Only for Android)
  /// [String starRatingTextMessage] - dialog's message text
  /// [String starRatingTextDismiss] - dialog's dismiss buttons text (Only for Android)
  static Future<String?> setStarRatingDialogTexts(String starRatingTextTitle,
          String starRatingTextMessage, String starRatingTextDismiss) =>
      _countly.setStarRatingDialogTexts(
          starRatingTextTitle, starRatingTextMessage, starRatingTextDismiss);

  static Future<String?> askForStarRating() => _countly.askForStarRating();

  static Future<String?> askForFeedback(
          String widgetId, String? closeButtonText) =>
      _countly.askForFeedback(widgetId, closeButtonText);

  /// Get a list of available feedback widgets for this device ID
  static Future<FeedbackWidgetsResponse> getAvailableFeedbackWidgets() =>
      _countly.getAvailableFeedbackWidgets();

  /// Present a chosen feedback widget
  /// [CountlyPresentableFeedback widgetInfo] - Get available list of feedback widgets by calling 'getAvailableFeedbackWidgets()' and pass the widget object as a parameter.
  /// [String closeButtonText] - Text for cancel/close button.
  static Future<String?> presentFeedbackWidget(
          CountlyPresentableFeedback widgetInfo, String closeButtonText) =>
      _countly.presentFeedbackWidget(widgetInfo, closeButtonText);

  /// Downloads widget info and returns [widgetData, error]
  /// Currently implemented for Android only
  /// [CountlyPresentableFeedback widgetInfo] - identifies the specific widget for which you want to download widget data
  static Future<List> getFeedbackWidgetData(
          CountlyPresentableFeedback widgetInfo) =>
      _countly.getFeedbackWidgetData(widgetInfo);

  /// Report widget info and do data validation
  /// Currently implemented for Android only
  /// [CountlyPresentableFeedback widgetInfo] - identifies the specific widget for which the feedback is filled out
  /// [Map<String, dynamic> widgetData] - widget data for this specific widget
  /// [Map<String, Object> widgetResult] - segmentation of the filled out feedback. If this segmentation is null, it will be assumed that the survey was closed before completion and mark it appropriately
  static Future<String?> reportFeedbackWidgetManually(
          CountlyPresentableFeedback widgetInfo,
          Map<String, dynamic> widgetData,
          Map<String, Object> widgetResult) =>
      _countly.reportFeedbackWidgetManually(
          widgetInfo, widgetData, widgetResult);

  static Future<String?> startEvent(String key) => _countly.startEvent(key);

  static Future<String?> endEvent(Map<String, Object> options) =>
      _countly.endEvent(options);

  /// Call used for testing error handling
  /// Should not be used
  static Future<String?> throwNativeException() =>
      _countly.throwNativeException();

  /// Enable crash reporting to report uncaught errors to Countly.
  /// Should be call before Countly init
  static Future<String?> enableCrashReporting() =>
      _countly.enableCrashReporting();

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
  static Future<String?> logException(String exception, bool nonfatal,
          [Map<String, Object>? segmentation]) =>
      _countly.logException(exception, nonfatal);

  /// Set optional key/value segment added for crash reports.
  /// Should be call before Countly init
  static Future<String?> setCustomCrashSegment(Map<String, Object> segments) =>
      _countly.setCustomCrashSegment(segments);

  static Future<String?> startTrace(String traceKey) =>
      _countly.startTrace(traceKey);

  static Future<String?> cancelTrace(String traceKey) =>
      _countly.cancelTrace(traceKey);

  static Future<String?> clearAllTraces() => _countly.clearAllTraces();

  static Future<String?> endTrace(
          String traceKey, Map<String, int>? customMetric) =>
      _countly.endTrace(traceKey, customMetric);

  static Future<String?> recordNetworkTrace(
          String networkTraceKey,
          int responseCode,
          int requestPayloadSize,
          int responsePayloadSize,
          int startTime,
          int endTime) =>
      _countly.recordNetworkTrace(networkTraceKey, responseCode,
          requestPayloadSize, responsePayloadSize, startTime, endTime);

  /// Enable APM features, which includes the recording of app start time.
  /// Should be call before Countly init
  static Future<String?> enableApm() => _countly.enableApm();

  /// Report a handled or unhandled exception/error to Countly.
  ///
  /// The exception is provided with an [Exception] object
  /// If no stack trace is provided, [StackTrace.current] will be used
  ///
  /// [String exception] - the exception that is recorded
  /// [bool nonfatal] - reports if the exception was fatal or not
  /// [StackTrace stacktrace] - stacktrace for the crash
  /// [Map<String, Object> segmentation] - allows to add optional segmentation
  static Future<String?> logExceptionEx(Exception exception, bool nonfatal,
          {StackTrace? stacktrace, Map<String, Object>? segmentation}) =>
      _countly.logExceptionEx(exception, nonfatal);

  /// Report a handled or unhandled exception/error to Countly.
  ///
  /// The exception/error is provided with a string message
  /// If no stack trace is provided, [StackTrace.current] will be used
  ///
  /// [String message] - the error / crash information sent to the server
  /// [bool nonfatal] - reports if the error was fatal or not
  /// [StackTrace stacktrace] - stacktrace for the crash
  /// [Map<String, Object> segmentation] - allows to add optional segmentation
  static Future<String?> logExceptionManual(String message, bool nonfatal,
          {StackTrace? stacktrace, Map<String, Object>? segmentation}) =>
      _countly.logExceptionManual(message, nonfatal);

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
  static Future<void> recordDartError(dynamic exception, StackTrace stack,
          {dynamic context}) =>
      _countly.recordDartError(exception, stack);

  /// Enable campaign attribution reporting to Countly.
  /// For iOS use 'recordAttributionID' instead of 'enableAttribution'
  /// Should be call before Countly init
  static Future<String?> enableAttribution() => _countly.enableAttribution();

  /// set attribution Id for campaign attribution reporting.
  /// Currently implemented for iOS only
  /// For Android just call the enableAttribution to enable campaign attribution.
  static Future<String?> recordAttributionID(String attributionID) =>
      _countly.recordAttributionID(attributionID);
}
