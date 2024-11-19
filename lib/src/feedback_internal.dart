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

  @override
  Future<void> presentNPS([String? nameIDorTag, FeedbackCallback? feedbackCallback]) async {
    if (!_countlyState.isInitialized) {
      Countly.log('presentNPS, "initWithConfig" must be called before "presentNPS"', logLevel: LogLevel.ERROR);
      feedbackCallback?.onFinished('init must be called before presentNPS');
      return;
    }
    
    _feedbackCallback = feedbackCallback;
    Countly.log('Calling "presentNPS"');
    await _countlyState.channel.invokeMethod('presentNPS', nameIDorTag);
  }

  @override
  Future<void> presentRating([String? nameIDorTag, FeedbackCallback? feedbackCallback]) async {
    if (!_countlyState.isInitialized) {
      Countly.log('presentNPS, "initWithConfig" must be called before "presentRating"', logLevel: LogLevel.ERROR);
      feedbackCallback?.onFinished('init must be called before presentRating');
      return;
    }

    _feedbackCallback = feedbackCallback;
    Countly.log('Calling "presentRating"');
    await _countlyState.channel.invokeMethod('presentRating', nameIDorTag);
  }

  @override
  Future<void> presentSurvey([String? nameIDorTag, FeedbackCallback? feedbackCallback]) async {
    if (!_countlyState.isInitialized) {
      Countly.log('presentNPS, "initWithConfig" must be called before "presentSurvey"', logLevel: LogLevel.ERROR);
      feedbackCallback?.onFinished('init must be called before presentSurvey');
      return;
    }

    _feedbackCallback = feedbackCallback;
    Countly.log('Calling "presentSurvey"');
    await _countlyState.channel.invokeMethod('presentSurvey', nameIDorTag);
  }

}