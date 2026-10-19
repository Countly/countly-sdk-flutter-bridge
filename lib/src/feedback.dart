typedef OnClosedCallback = void Function();
typedef OnFinishedCallback = void Function(String error);

/// Callbacks of a widget presented with "presentNPS", "presentSurvey" or "presentRating". They are
/// not called on web.
class FeedbackCallback {
  /// Called when the widget is closed.
  final OnClosedCallback onClosed;

  /// Called with the error when the widget cannot be shown. In iOS, and for some widgets in Android,
  /// it is also called with an empty string once the widget is shown.
  final OnFinishedCallback onFinished;

  FeedbackCallback({required this.onClosed, required this.onFinished});
}

abstract class Feedback {
  Future<void> presentNPS([String? nameIDorTag, FeedbackCallback? feedbackCallback]);

  Future<void> presentRating([String? nameIDorTag, FeedbackCallback? feedbackCallback]);

  Future<void> presentSurvey([String? nameIDorTag, FeedbackCallback? feedbackCallback]);
}
