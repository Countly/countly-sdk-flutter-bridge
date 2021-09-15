import 'countly_presentable_feedback.dart';

class FeedbackWidgetsResponse {
  FeedbackWidgetsResponse(this.presentableFeedback, this.error);

  final String? error;
  final List<CountlyPresentableFeedback> presentableFeedback;
}
