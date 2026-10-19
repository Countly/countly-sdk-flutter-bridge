import 'dart:convert';
import 'dart:io';

import 'package:countly_flutter/countly_flutter.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../utils.dart';

/// The star rating consent controls the star rating dialog. On iOS that dialog follows the
/// feedback consent, so giving or removing "star-rating" gives or removes "feedback" there.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('The star-rating consent is reported and, on iOS, carries the feedback consent', (WidgetTester tester) async {
    await Countly.initWithConfig(CountlyConfig(SERVER_URL, APP_KEY)
      ..setLoggingEnabled(true)
      ..setRequiresConsent(true));

    await Countly.giveConsent([CountlyConsent.starRating]);
    await Future<void>.delayed(const Duration(seconds: 2));
    final Map<String, dynamic> given = await lastConsentRequest();
    if (Platform.isIOS) {
      expect(given['feedback'], isTrue);
    } else {
      expect(given['star-rating'], isTrue);
      expect(given['feedback'], isFalse);
    }

    await Countly.removeConsent([CountlyConsent.starRating]);
    await Future<void>.delayed(const Duration(seconds: 2));
    final Map<String, dynamic> removed = await lastConsentRequest();
    if (Platform.isIOS) {
      expect(removed['feedback'], isFalse);
    } else {
      expect(removed['star-rating'], isFalse);
    }
  });
}

/// The consent states of the last consent request in the request queue.
Future<Map<String, dynamic>> lastConsentRequest() async {
  final String request = (await getRequestQueue()).lastWhere((request) => request.contains('consent='));
  return json.decode(Uri.parse('?$request').queryParameters['consent']!) as Map<String, dynamic>;
}
