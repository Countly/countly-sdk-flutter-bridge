import 'package:countly_flutter/countly_flutter.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../utils.dart';

/// Feedback and rating calls complete, with an error where one applies, when the SDK cannot
/// show anything: no consent and an unknown widget. None of them may leave the app waiting.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('Feedback and rating calls complete without consent or a known widget', (WidgetTester tester) async {
    await Countly.initWithConfig(CountlyConfig(SERVER_URL, APP_KEY).setLoggingEnabled(true).setRequiresConsent(true));
    const Duration limit = Duration(seconds: 10);

    await Countly.instance.feedback.presentNPS('missing_widget', FeedbackCallback(onClosed: () {}, onFinished: (String error) {})).timeout(limit);
    await Countly.instance.feedback.presentSurvey().timeout(limit);
    await Countly.instance.feedback.presentRating().timeout(limit);

    final List<dynamic> widgetData = await Countly.getFeedbackWidgetData(CountlyPresentableFeedback('missing_id', 'nps', 'missing')).timeout(limit);
    print('widget data: $widgetData');
    expect(widgetData[0], isEmpty);
    expect(widgetData[1], isNotNull);

    final String? starRating = await Countly.askForStarRating().timeout(limit);
    print('star rating: $starRating');
    expect(starRating, contains('consent'));
  });
}
