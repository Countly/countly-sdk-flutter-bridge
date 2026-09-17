import 'dart:convert';
import 'package:countly_flutter/countly_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import '../utils.dart';

const int PICTURE_LIMIT = 20;

/// Checks that the picture value limit truncates the user profile picture URL, and only that value.
/// The limit is not supported on web.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  tearDown(() async {
    await Countly.instance.halt();
  });

  testWidgets('The picture URL is truncated to the picture value limit', (WidgetTester tester) async {
    CountlyConfig config = CountlyConfig(SERVER_URL, APP_KEY).setLoggingEnabled(true);
    config.sdkInternalLimits.setMaxValueSizePicture(PICTURE_LIMIT);
    await Countly.initWithConfig(config);

    final String pictureUrl = 'https://example.com/${'a' * 100}.png';
    await Countly.instance.userProfile.setProperty('picture', pictureUrl);
    await Countly.instance.userProfile.setProperty('name', 'a' * 100);
    await Countly.instance.userProfile.save();
    await Future.delayed(const Duration(seconds: 2));

    final userDetailsRequest = await getRequestWithParam('user_details');
    final userDetails = json.decode(userDetailsRequest!['user_details']![0]) as Map<String, dynamic>;

    expect((userDetails['picture'] as String).length, PICTURE_LIMIT);
    expect((userDetails['name'] as String).length, 100);
  }, skip: kIsWeb);
}
