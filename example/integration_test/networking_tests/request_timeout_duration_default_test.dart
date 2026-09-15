import 'package:countly_flutter_np/countly_flutter.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import '../utils.dart';

/// Tests for the requestTimeoutDuration configuration option default value.
/// Verifies that the SDK initializes correctly with the default option
/// and that requests are attempted.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('requestTimeoutDuration_default_test', (WidgetTester tester) async {
    // Create a server that delays response by 3 seconds
    List<Map<String, List<String>>> requestArray = <Map<String, List<String>>>[];
    createServer(requestArray, delay: 3);

    // Initialize SDK with default request timeout
    CountlyConfig config = CountlyConfig(TEST_SERVER_URL, APP_KEY).enableManualSessionHandling().setLoggingEnabled(true); // Use default timeout

    await Countly.initWithConfig(config);

    // Start a session to trigger a request
    await Countly.instance.sessions.beginSession();

    // Wait for a bit to allow the request to be processed
    await Future.delayed(const Duration(seconds: 5));

    List<String> requestList = await getRequestQueue();
    equals(requestList.length, 0);
  });
}
