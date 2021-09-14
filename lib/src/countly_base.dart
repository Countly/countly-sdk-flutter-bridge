import 'models/countly_presentable_feedback.dart';
import 'models/feedback_widget_response.dart';
import 'dart:async';

import 'models/log_level.dart';

abstract class CountlyBase {
  void log(String? message, {LogLevel logLevel = LogLevel.DEBUG});

  Future<String?> init(String serverUrl, String appKey, [String? deviceId]);

  Future<bool> isInitialized();

  /// Replaces all requests with a different app key with the current app key.
  /// In request queue, if there are any request whose app key is different than the current app key,
  /// these requests' app key will be replaced with the current app key.
  Future<String?> replaceAllAppKeysInQueueWithCurrentAppKey();

  /// Removes all requests with a different app key in request queue.
  /// In request queue, if there are any request whose app key is different than the current app key,
  /// these requests will be removed from request queue.
  Future<String?> removeDifferentAppKeysFromQueue();

  /// Call this function when app is loaded, so that the app launch duration can be recorded.
  /// Should be called after init.
  Future<String?> appLoadingFinished();

  Future<String?> recordEvent(Map<String, Object> options);

  /// Record custom view to Countly.
  ///
  /// [String view] - name of the view
  /// [Map<String, Object> segmentation] - allows to add optional segmentation,
  /// Supported data type for segmentation values are String, int, double and bool
  Future<String?> recordView(String view, [Map<String, Object>? segmentation]);

  Future<String?> setUserData(Map<String, Object> options);

  /// This method will ask for permission, enables push notification and send push token to countly server.
  /// Should be call after Countly init
  Future<String?> askForNotificationPermission();

  /// Disable push notifications feature, by default it is enabled.
  /// Currently implemented for iOS only
  /// Should be called before Countly init
  Future<String?> disablePushNotifications();

  /// Set messaging mode for push notifications
  /// Should be call before Countly init
  Future<String?> pushTokenType(String tokenType);

  /// Set callback to receive push notifications
  /// @param { callback listner } callback
  Future<String?> onNotification(Function callback);

  Future<String?> start();

  Future<String?> manualSessionHandling();

  Future<String?> stop();

  Future<String?> updateSessionPeriod();

  /// Sets the interval for the automatic session update calls
  /// min value 1 (1 second),
  /// max value 600 (10 minutes)
  /// [int sessionInterval]- delay in seconds
  Future<String?> updateSessionInterval(int sessionInterval);

  /// Events get grouped together and are sent either every minute or after the unsent event count reaches a threshold. By default it is 10
  /// Should be call before Countly init
  Future<String?> eventSendThreshold(int limit);

  Future<String?> storedRequestsLimit();

  Future<String?> setOptionalParametersForInitialization(
      Map<String, Object> options);

  /// Get currently used device Id.
  /// Should be call after Countly init
  Future<String?> getCurrentDeviceId();

  Future<String?> changeDeviceId(String newDeviceID, bool onServer);

  Future<String?> addCrashLog(String logs);

  /// Set to true if you want to enable countly internal debugging logs
  /// Should be call before Countly init
  Future<String?> setLoggingEnabled(bool flag);

  /// Set the optional salt to be used for calculating the checksum of requested data which will be sent with each request, using the &checksum field
  /// Should be call before Countly init
  Future<String?> enableParameterTamperingProtection(String salt);

  /// Set to 'true' if you want HTTP POST to be used for all requests
  /// Should be call before Countly init
  Future<String?> setHttpPostForced(bool isEnabled);

  /// Set user initial location
  /// Should be call before init
  Future<String?> setLocationInit(
      String countryCode, String city, String gpsCoordinates, String ipAddress);

  Future<String?> setLocation(String latitude, String longitude);

  Future<String?> setProperty(String keyName, String keyValue);

  Future<String?> increment(String keyName);

  Future<String?> incrementBy(String keyName, int keyIncrement);

  Future<String?> multiply(String keyName, int multiplyValue);

  Future<String?> saveMax(String keyName, int saveMax);

  Future<String?> saveMin(String keyName, int saveMin);

  Future<String?> setOnce(String keyName, String setOnce);

  Future<String?> pushUniqueValue(String type, String pushUniqueValue);

  Future<String?> pushValue(String type, String pushValue);

  Future<String?> pullValue(String type, String pullValue);

  /// Set that consent should be required for features to work.
  /// Should be call before Countly init
  Future<String?> setRequiresConsent(bool flag);

  /// Give consent for specific features.
  /// Should be call before Countly init
  Future<String?> giveConsentInit(List<String> consents);

  Future<String?> giveConsent(List<String> consents);

  Future<String?> removeConsent(List<String> consents);

  /// Give consent for all features
  /// Should be call after Countly init
  Future<String?> giveAllConsent();

  Future<String?> removeAllConsent();

  /// Set Automatic value download happens when the SDK is initiated or when the device ID is changed.
  /// Should be call before Countly init
  Future<String?> setRemoteConfigAutomaticDownload(Function callback);

  Future<String?> remoteConfigUpdate(Function callback);

  Future<String?> updateRemoteConfigForKeysOnly(
      List<String> keys, Function callback);

  Future<String?> updateRemoteConfigExceptKeys(
      List<String> keys, Function callback);

  Future<String?> remoteConfigClearValues(Function callback);

  Future<String?> getRemoteConfigValueForKey(String key, Function callback);

  /// Set's the text's for the different fields in the star rating dialog. Set value null if for some field you want to keep the old value
  /// [String starRatingTextTitle] - dialog's title text (Only for Android)
  /// [String starRatingTextMessage] - dialog's message text
  /// [String starRatingTextDismiss] - dialog's dismiss buttons text (Only for Android)
  Future<String?> setStarRatingDialogTexts(String starRatingTextTitle,
      String starRatingTextMessage, String starRatingTextDismiss);

  Future<String?> askForStarRating();

  Future<String?> askForFeedback(String widgetId, String? closeButtonText);

  /// Get a list of available feedback widgets for this device ID
  Future<FeedbackWidgetsResponse> getAvailableFeedbackWidgets();

  /// Present a chosen feedback widget
  /// [CountlyPresentableFeedback widgetInfo] - Get available list of feedback widgets by calling 'getAvailableFeedbackWidgets()' and pass the widget object as a parameter.
  /// [String closeButtonText] - Text for cancel/close button.
  Future<String?> presentFeedbackWidget(
      CountlyPresentableFeedback widgetInfo, String closeButtonText);

  /// Downloads widget info and returns [widgetData, error]
  /// Currently implemented for Android only
  /// [CountlyPresentableFeedback widgetInfo] - identifies the specific widget for which you want to download widget data
  Future<List> getFeedbackWidgetData(CountlyPresentableFeedback widgetInfo);

  /// Report widget info and do data validation
  /// Currently implemented for Android only
  /// [CountlyPresentableFeedback widgetInfo] - identifies the specific widget for which the feedback is filled out
  /// [Map<String, dynamic> widgetData] - widget data for this specific widget
  /// [Map<String, Object> widgetResult] - segmentation of the filled out feedback. If this segmentation is null, it will be assumed that the survey was closed before completion and mark it appropriately
  Future<String?> reportFeedbackWidgetManually(
      CountlyPresentableFeedback widgetInfo,
      Map<String, dynamic> widgetData,
      Map<String, Object> widgetResult);

  Future<String?> startEvent(String key);

  Future<String?> endEvent(Map<String, Object> options);

  /// Call used for testing error handling
  /// Should not be used
  Future<String?> throwNativeException();

  /// Enable crash reporting to report uncaught errors to Countly.
  /// Should be call before Countly init
  Future<String?> enableCrashReporting();

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
  Future<String?> logException(String exception, bool nonfatal,
      [Map<String, Object>? segmentation]);

  /// Set optional key/value segment added for crash reports.
  /// Should be call before Countly init
  Future<String?> setCustomCrashSegment(Map<String, Object> segments);

  Future<String?> startTrace(String traceKey);

  Future<String?> cancelTrace(String traceKey);

  Future<String?> clearAllTraces();

  Future<String?> endTrace(String traceKey, Map<String, int>? customMetric);

  Future<String?> recordNetworkTrace(
      String networkTraceKey,
      int responseCode,
      int requestPayloadSize,
      int responsePayloadSize,
      int startTime,
      int endTime);

  /// Enable APM features, which includes the recording of app start time.
  /// Should be call before Countly init
  Future<String?> enableApm();

  /// Report a handled or unhandled exception/error to Countly.
  ///
  /// The exception is provided with an [Exception] object
  /// If no stack trace is provided, [StackTrace.current] will be used
  ///
  /// [String exception] - the exception that is recorded
  /// [bool nonfatal] - reports if the exception was fatal or not
  /// [StackTrace stacktrace] - stacktrace for the crash
  /// [Map<String, Object> segmentation] - allows to add optional segmentation
  Future<String?> logExceptionEx(Exception exception, bool nonfatal,
      {StackTrace? stacktrace, Map<String, Object>? segmentation});

  /// Report a handled or unhandled exception/error to Countly.
  ///
  /// The exception/error is provided with a string message
  /// If no stack trace is provided, [StackTrace.current] will be used
  ///
  /// [String message] - the error / crash information sent to the server
  /// [bool nonfatal] - reports if the error was fatal or not
  /// [StackTrace stacktrace] - stacktrace for the crash
  /// [Map<String, Object> segmentation] - allows to add optional segmentation
  Future<String?> logExceptionManual(String message, bool nonfatal,
      {StackTrace? stacktrace, Map<String, Object>? segmentation});

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
  Future<void> recordDartError(dynamic exception, StackTrace stack,
      {dynamic context});

  /// Enable campaign attribution reporting to Countly.
  /// For iOS use 'recordAttributionID' instead of 'enableAttribution'
  /// Should be call before Countly init
  Future<String?> enableAttribution();

  /// set attribution Id for campaign attribution reporting.
  /// Currently implemented for iOS only
  /// For Android just call the enableAttribution to enable campaign attribution.
  Future<String?> recordAttributionID(String attributionID);
}
