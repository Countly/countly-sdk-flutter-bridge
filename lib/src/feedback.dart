typedef OnClosedCallback = void Function();
typedef OnFinishedCallback = void Function(String error);

class FeedbackCallback {
  final OnClosedCallback onClosed;
  final OnFinishedCallback onFinished;

  FeedbackCallback({required this.onClosed, required this.onFinished});
}

abstract class Feedback {
  Future<void>  presentNPS([String? nameIDorTag, FeedbackCallback? feedbackCallback]);

  Future<void>  presentRating([String? nameIDorTag, FeedbackCallback? feedbackCallback]);

  Future<void>  presentSurvey([String? nameIDorTag, FeedbackCallback? feedbackCallback]);
}