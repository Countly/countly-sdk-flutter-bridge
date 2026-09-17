import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'countly_flutter.dart';
import 'countly_state.dart';
import 'feedback.dart';

class FeedbackInternal implements Feedback {
  FeedbackInternal(this._countlyState);
  final CountlyState _countlyState;
  FeedbackCallback? _feedbackCallback;
  FeedbackCallback? get feedbackCallback => _feedbackCallback;
  set feedbackCallback(FeedbackCallback? callback) {
    // Add any validation or custom logic here if needed
    _feedbackCallback = callback;
  }

  /// The callbacks of the widget this instance is presenting, at most one widget is displayed at a time.
  VoidCallback? _widgetShown;
  VoidCallback? _widgetClosed;
  Function(String? error)? _ratingWidgetCallback;
  Function(Map<String, dynamic> widgetData, String? error)? _feedbackWidgetDataCallback;

  @override
  Future<void> presentNPS([String? nameIDorTag, FeedbackCallback? feedbackCallback]) async {
    if (!_countlyState.isInitialized) {
      Countly.log('presentNPS, "initWithConfig" must be called before "presentNPS"', logLevel: LogLevel.ERROR);
      feedbackCallback?.onFinished('init must be called before presentNPS');
      return;
    }

    _feedbackCallback = feedbackCallback;
    Countly.log('Calling "presentNPS" with nameIDorTag: [$nameIDorTag]');
    await invokeFeedbackMethod('presentNPS', nameIDorTag);
  }

  @override
  Future<void> presentRating([String? nameIDorTag, FeedbackCallback? feedbackCallback]) async {
    if (!_countlyState.isInitialized) {
      Countly.log('presentRating, "initWithConfig" must be called before "presentRating"', logLevel: LogLevel.ERROR);
      feedbackCallback?.onFinished('init must be called before presentRating');
      return;
    }

    _feedbackCallback = feedbackCallback;
    Countly.log('Calling "presentRating" with nameIDorTag: [$nameIDorTag]');
    await invokeFeedbackMethod('presentRating', nameIDorTag);
  }

  @override
  Future<void> presentSurvey([String? nameIDorTag, FeedbackCallback? feedbackCallback]) async {
    if (!_countlyState.isInitialized) {
      Countly.log('presentSurvey, "initWithConfig" must be called before "presentSurvey"', logLevel: LogLevel.ERROR);
      feedbackCallback?.onFinished('init must be called before presentSurvey');
      return;
    }

    _feedbackCallback = feedbackCallback;
    Countly.log('Calling "presentSurvey" with nameIDorTag: [$nameIDorTag]');
    await invokeFeedbackMethod('presentSurvey', nameIDorTag);
  }

  Future<void> invokeFeedbackMethod(String methodName, String? nameIDorTag) {
    final args = [];
    nameIDorTag ??= '';
    args.add(nameIDorTag);

    return _countlyState.channel.invokeMethod(methodName, _countlyState.arguments(json.encode(args)));
  }

  @override
  Future<FeedbackWidgetsResponse> getAvailableFeedbackWidgets() async {
    final String? notReady = _countlyState.requireInit('FeedbackInternal', 'getAvailableFeedbackWidgets');
    if (notReady != null) {
      return FeedbackWidgetsResponse([], notReady);
    }
    Countly.log('[FeedbackInternal] getAvailableFeedbackWidgets');
    List<CountlyPresentableFeedback> presentableFeedback = [];
    String? error;
    try {
      final List<dynamic> retrievedWidgets = await _countlyState.channel.invokeMethod('getAvailableFeedbackWidgets', _countlyState.arguments());
      presentableFeedback = retrievedWidgets.map((e) => CountlyPresentableFeedback.fromJson(e)).toList();
    } on PlatformException catch (e) {
      error = e.message;
      Countly.log('[FeedbackInternal] getAvailableFeedbackWidgets, error:[$error]', logLevel: LogLevel.ERROR);
    }
    return FeedbackWidgetsResponse(presentableFeedback, error);
  }

  @override
  Future<String?> presentFeedbackWidget(CountlyPresentableFeedback widgetInfo, String closeButtonText, {VoidCallback? widgetShown, VoidCallback? widgetClosed}) async {
    final String? notReady = _countlyState.requireInit('FeedbackInternal', 'presentFeedbackWidget');
    if (notReady != null) {
      return notReady;
    }
    Countly.log('[FeedbackInternal] presentFeedbackWidget, widget:[${widgetInfo.widgetId}] type:[${widgetInfo.type}]');
    _widgetShown = widgetShown;
    _widgetClosed = widgetClosed;

    final List<String> args = [widgetInfo.widgetId, widgetInfo.type, widgetInfo.name, closeButtonText];
    try {
      return await _countlyState.channel.invokeMethod('presentFeedbackWidget', _countlyState.arguments(json.encode(args)));
    } on PlatformException catch (e) {
      return e.message;
    }
  }

  @override
  Future<List> getFeedbackWidgetData(CountlyPresentableFeedback widgetInfo, {Function(Map<String, dynamic> widgetData, String? error)? onFinished}) async {
    Map<String, dynamic> widgetData = {};
    final String? notReady = _countlyState.requireInit('FeedbackInternal', 'getFeedbackWidgetData');
    if (notReady != null) {
      return [widgetData, notReady];
    }
    _feedbackWidgetDataCallback = onFinished;
    Countly.log('[FeedbackInternal] getFeedbackWidgetData, widget:[${widgetInfo.widgetId}] type:[${widgetInfo.type}]');
    String? error;
    final List<String> args = [widgetInfo.widgetId, widgetInfo.type, widgetInfo.name];
    try {
      final dynamic retrievedWidgetData = await _countlyState.channel.invokeMethod('getFeedbackWidgetData', _countlyState.arguments(json.encode(args)));
      if (retrievedWidgetData is Map) {
        widgetData = Map<String, dynamic>.from(retrievedWidgetData);
      } else {
        // iOS answers with the failure message instead of throwing
        error = retrievedWidgetData?.toString();
      }
    } on PlatformException catch (e) {
      error = e.message;
      Countly.log('[FeedbackInternal] getFeedbackWidgetData, error:[$error]', logLevel: LogLevel.ERROR);
    }
    return [widgetData, error];
  }

  @override
  Future<String?> reportFeedbackWidgetManually(CountlyPresentableFeedback widgetInfo, Map<String, dynamic> widgetData, Map<String, Object> widgetResult) async {
    final String? notReady = _countlyState.requireInit('FeedbackInternal', 'reportFeedbackWidgetManually');
    if (notReady != null) {
      return notReady;
    }
    Countly.log('[FeedbackInternal] reportFeedbackWidgetManually, widget:[${widgetInfo.widgetId}] type:[${widgetInfo.type}]');
    final List<dynamic> args = [
      [widgetInfo.widgetId, widgetInfo.type, widgetInfo.name],
      widgetData,
      widgetResult,
    ];
    try {
      return await _countlyState.channel.invokeMethod('reportFeedbackWidgetManually', _countlyState.arguments(json.encode(args)));
    } on PlatformException catch (e) {
      return e.message;
    }
  }

  @override
  Future<String?> presentRatingWidgetWithID(String widgetId, {String? closeButtonText, Function(String? error)? ratingWidgetCallback}) async {
    final String? notReady = _countlyState.requireInit('FeedbackInternal', 'presentRatingWidgetWithID');
    if (notReady != null) {
      return notReady;
    }
    if (widgetId.isEmpty) {
      const String error = 'presentRatingWidgetWithID, widgetId cannot be empty';
      Countly.log('[FeedbackInternal] $error', logLevel: LogLevel.WARNING);
      return 'Error : $error';
    }
    Countly.log('[FeedbackInternal] presentRatingWidgetWithID, widget:[$widgetId] with callback:[${ratingWidgetCallback != null}]');
    _ratingWidgetCallback = ratingWidgetCallback;
    final List<String> args = [widgetId, closeButtonText ?? ''];
    return _countlyState.channel.invokeMethod('presentRatingWidgetWithID', _countlyState.arguments(json.encode(args)));
  }

  /// Drops every callback still waiting on the native side, after the instance was halted or removed.
  void forgetCallbacks() {
    _feedbackCallback = null;
    _widgetShown = null;
    _widgetClosed = null;
    _ratingWidgetCallback = null;
    _feedbackWidgetDataCallback = null;
  }

  /// Called by the native side when the widget presented with [presentFeedbackWidget] is displayed.
  void onWidgetShown() {
    _widgetShown?.call();
  }

  /// Called by the native side when the widget presented with [presentFeedbackWidget] is closed.
  void onWidgetClosed() {
    _widgetClosed?.call();
    _widgetShown = null;
    _widgetClosed = null;
  }

  /// Called by the native side when the rating widget presented with [presentRatingWidgetWithID] is done.
  void onRatingWidgetResult(String? error) {
    final Function(String? error)? callback = _ratingWidgetCallback;
    _ratingWidgetCallback = null;
    callback?.call(error);
  }

  /// Called by the native side with the outcome of the download [getFeedbackWidgetData] started.
  void onFeedbackWidgetData(Map<String, dynamic> widgetData, String? error) {
    final Function(Map<String, dynamic> widgetData, String? error)? callback = _feedbackWidgetDataCallback;
    _feedbackWidgetDataCallback = null;
    callback?.call(widgetData, error);
  }
}
