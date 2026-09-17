import 'package:flutter/foundation.dart';

import 'countly_flutter.dart';

typedef OnClosedCallback = void Function();
typedef OnFinishedCallback = void Function(String error);

class FeedbackCallback {
  final OnClosedCallback onClosed;
  final OnFinishedCallback onFinished;

  FeedbackCallback({required this.onClosed, required this.onFinished});
}

abstract class Feedback {
  Future<void> presentNPS([String? nameIDorTag, FeedbackCallback? feedbackCallback]);

  Future<void> presentRating([String? nameIDorTag, FeedbackCallback? feedbackCallback]);

  Future<void> presentSurvey([String? nameIDorTag, FeedbackCallback? feedbackCallback]);

  /// Get the list of feedback widgets available to this device ID.
  Future<FeedbackWidgetsResponse> getAvailableFeedbackWidgets();

  /// Present one of the widgets [getAvailableFeedbackWidgets] returned.
  /// [CountlyPresentableFeedback widgetInfo]: the widget to present
  /// [String closeButtonText]: text of the close button
  /// [VoidCallback? widgetShown]: called when the widget is displayed
  /// [VoidCallback? widgetClosed]: called when the widget is closed, iOS only
  Future<void> presentFeedbackWidget(CountlyPresentableFeedback widgetInfo, String closeButtonText, {VoidCallback? widgetShown, VoidCallback? widgetClosed});

  /// Download the data of a widget, to draw it yourself and report the result with [reportFeedbackWidgetManually].
  /// [CountlyPresentableFeedback widgetInfo]: the widget to download
  /// [Function? onFinished]: called with the widget data, or with the error when the download failed
  /// returns a list holding the widget data and the error message, if any
  Future<List> getFeedbackWidgetData(CountlyPresentableFeedback widgetInfo, {Function(Map<String, dynamic> widgetData, String? error)? onFinished});

  /// Report the result of a widget you drew yourself.
  /// [CountlyPresentableFeedback widgetInfo]: the widget the result belongs to
  /// [Map<String, dynamic> widgetData]: the widget data [getFeedbackWidgetData] returned
  /// [Map<String, Object> widgetResult]: the filled out result, an empty map reports the widget as closed without completion
  Future<void> reportFeedbackWidgetManually(CountlyPresentableFeedback widgetInfo, Map<String, dynamic> widgetData, Map<String, Object> widgetResult);

  /// Present the rating widget with the given ID.
  /// [String widgetId]: the ID of the rating widget
  /// [String? closeButtonText]: text of the close button
  /// [Function? ratingWidgetCallback]: called when the widget is closed, with the error if presenting it failed
  Future<void> presentRatingWidgetWithID(String widgetId, {String? closeButtonText, Function(String? error)? ratingWidgetCallback});
}
