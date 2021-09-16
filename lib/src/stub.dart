import 'package:countly_flutter/src/models/countly_presentable_feedback.dart';

import 'package:countly_flutter/src/models/feedback_widget_response.dart';

import 'package:countly_flutter/src/models/log_level.dart';

import 'countly_base.dart';

class CountlyApp implements CountlyBase {
  @override
  Future<String?> addCrashLog(String logs) {
    throw UnimplementedError();
  }

  @override
  Future<String?> appLoadingFinished() {
    throw UnimplementedError();
  }

  @override
  Future<String?> askForFeedback(String widgetId, String? closeButtonText) {
    throw UnimplementedError();
  }

  @override
  Future<String?> askForNotificationPermission() {
    throw UnimplementedError();
  }

  @override
  Future<String?> askForStarRating() {
    throw UnimplementedError();
  }

  @override
  Future<String?> cancelTrace(String traceKey) {
    throw UnimplementedError();
  }

  @override
  Future<String?> changeDeviceId(String newDeviceID, bool onServer) {
    throw UnimplementedError();
  }

  @override
  Future<String?> clearAllTraces() {
    throw UnimplementedError();
  }

  @override
  Future<String?> disablePushNotifications() {
    throw UnimplementedError();
  }

  @override
  Future<String?> enableApm() {
    throw UnimplementedError();
  }

  @override
  Future<String?> enableAttribution() {
    throw UnimplementedError();
  }

  @override
  Future<String?> enableCrashReporting() {
    throw UnimplementedError();
  }

  @override
  Future<String?> enableParameterTamperingProtection(String salt) {
    throw UnimplementedError();
  }

  @override
  Future<String?> endEvent(Map<String, Object> options) {
    throw UnimplementedError();
  }

  @override
  Future<String?> endTrace(String traceKey, Map<String, int>? customMetric) {
    throw UnimplementedError();
  }

  @override
  Future<String?> eventSendThreshold(int limit) {
    throw UnimplementedError();
  }

  @override
  Future<FeedbackWidgetsResponse> getAvailableFeedbackWidgets() {
    throw UnimplementedError();
  }

  @override
  Future<String?> getCurrentDeviceId() {
    throw UnimplementedError();
  }

  @override
  Future<List> getFeedbackWidgetData(CountlyPresentableFeedback widgetInfo) {
    throw UnimplementedError();
  }

  @override
  Future<String?> getRemoteConfigValueForKey(String key, Function callback) {
    throw UnimplementedError();
  }

  @override
  Future<String?> giveAllConsent() {
    throw UnimplementedError();
  }

  @override
  Future<String?> giveConsent(List<String> consents) {
    throw UnimplementedError();
  }

  @override
  Future<String?> giveConsentInit(List<String> consents) {
    throw UnimplementedError();
  }

  @override
  Future<String?> increment(String keyName) {
    throw UnimplementedError();
  }

  @override
  Future<String?> incrementBy(String keyName, int keyIncrement) {
    throw UnimplementedError();
  }

  @override
  Future<String?> init(String serverUrl, String appKey, [String? deviceId]) {
    throw UnimplementedError();
  }

  @override
  Future<bool> isInitialized() {
    throw UnimplementedError();
  }

  @override
  void log(String? message, {LogLevel logLevel = LogLevel.DEBUG}) {
    throw UnimplementedError();
  }

  @override
  Future<String?> logException(String exception, bool nonfatal,
      [Map<String, Object>? segmentation]) {
    throw UnimplementedError();
  }

  @override
  Future<String?> logExceptionEx(Exception exception, bool nonfatal,
      {StackTrace? stacktrace, Map<String, Object>? segmentation}) {
    throw UnimplementedError();
  }

  @override
  Future<String?> logExceptionManual(String message, bool nonfatal,
      {StackTrace? stacktrace, Map<String, Object>? segmentation}) {
    throw UnimplementedError();
  }

  @override
  Future<String?> manualSessionHandling() {
    throw UnimplementedError();
  }

  @override
  Future<String?> multiply(String keyName, int multiplyValue) {
    throw UnimplementedError();
  }

  @override
  Future<String?> onNotification(Function callback) {
    throw UnimplementedError();
  }

  @override
  Future<String?> presentFeedbackWidget(
      CountlyPresentableFeedback widgetInfo, String closeButtonText) {
    throw UnimplementedError();
  }

  @override
  Future<String?> pullValue(String type, String pullValue) {
    throw UnimplementedError();
  }

  @override
  Future<String?> pushTokenType(String tokenType) {
    throw UnimplementedError();
  }

  @override
  Future<String?> pushUniqueValue(String type, String pushUniqueValue) {
    throw UnimplementedError();
  }

  @override
  Future<String?> pushValue(String type, String pushValue) {
    throw UnimplementedError();
  }

  @override
  Future<String?> recordAttributionID(String attributionID) {
    throw UnimplementedError();
  }

  @override
  Future<void> recordDartError(exception, StackTrace stack, {context}) {
    throw UnimplementedError();
  }

  @override
  Future<String?> recordEvent(Map<String, Object> options) {
    throw UnimplementedError();
  }

  @override
  Future<String?> recordNetworkTrace(
      String networkTraceKey,
      int responseCode,
      int requestPayloadSize,
      int responsePayloadSize,
      int startTime,
      int endTime) {
    throw UnimplementedError();
  }

  @override
  Future<String?> recordView(String view, [Map<String, Object>? segmentation]) {
    throw UnimplementedError();
  }

  @override
  Future<String?> remoteConfigClearValues(Function callback) {
    throw UnimplementedError();
  }

  @override
  Future<String?> remoteConfigUpdate(Function callback) {
    throw UnimplementedError();
  }

  @override
  Future<String?> removeAllConsent() {
    throw UnimplementedError();
  }

  @override
  Future<String?> removeConsent(List<String> consents) {
    throw UnimplementedError();
  }

  @override
  Future<String?> removeDifferentAppKeysFromQueue() {
    throw UnimplementedError();
  }

  @override
  Future<String?> replaceAllAppKeysInQueueWithCurrentAppKey() {
    throw UnimplementedError();
  }

  @override
  Future<String?> reportFeedbackWidgetManually(
      CountlyPresentableFeedback widgetInfo,
      Map<String, dynamic> widgetData,
      Map<String, Object> widgetResult) {
    throw UnimplementedError();
  }

  @override
  Future<String?> saveMax(String keyName, int saveMax) {
    throw UnimplementedError();
  }

  @override
  Future<String?> saveMin(String keyName, int saveMin) {
    throw UnimplementedError();
  }

  @override
  Future<String?> setCustomCrashSegment(Map<String, Object> segments) {
    throw UnimplementedError();
  }

  @override
  Future<String?> setHttpPostForced(bool isEnabled) {
    throw UnimplementedError();
  }

  @override
  Future<String?> setLocation(String latitude, String longitude) {
    throw UnimplementedError();
  }

  @override
  Future<String?> setLocationInit(String countryCode, String city,
      String gpsCoordinates, String ipAddress) {
    throw UnimplementedError();
  }

  @override
  Future<String?> setLoggingEnabled(bool flag) {
    throw UnimplementedError();
  }

  @override
  Future<String?> setOnce(String keyName, String setOnce) {
    throw UnimplementedError();
  }

  @override
  Future<String?> setOptionalParametersForInitialization(
      Map<String, Object> options) {
    throw UnimplementedError();
  }

  @override
  Future<String?> setProperty(String keyName, String keyValue) {
    throw UnimplementedError();
  }

  @override
  Future<String?> setRemoteConfigAutomaticDownload(Function callback) {
    throw UnimplementedError();
  }

  @override
  Future<String?> setRequiresConsent(bool flag) {
    throw UnimplementedError();
  }

  @override
  Future<String?> setStarRatingDialogTexts(String starRatingTextTitle,
      String starRatingTextMessage, String starRatingTextDismiss) {
    throw UnimplementedError();
  }

  @override
  Future<String?> setUserData(Map<String, Object> options) {
    throw UnimplementedError();
  }

  @override
  Future<String?> start() {
    throw UnimplementedError();
  }

  @override
  Future<String?> startEvent(String key) {
    throw UnimplementedError();
  }

  @override
  Future<String?> startTrace(String traceKey) {
    throw UnimplementedError();
  }

  @override
  Future<String?> stop() {
    throw UnimplementedError();
  }

  @override
  Future<String?> storedRequestsLimit() {
    throw UnimplementedError();
  }

  @override
  Future<String?> throwNativeException() {
    throw UnimplementedError();
  }

  @override
  Future<String?> updateRemoteConfigExceptKeys(
      List<String> keys, Function callback) {
    throw UnimplementedError();
  }

  @override
  Future<String?> updateRemoteConfigForKeysOnly(
      List<String> keys, Function callback) {
    throw UnimplementedError();
  }

  @override
  Future<String?> updateSessionInterval(int sessionInterval) {
    throw UnimplementedError();
  }

  @override
  Future<String?> updateSessionPeriod() {
    throw UnimplementedError();
  }
}
