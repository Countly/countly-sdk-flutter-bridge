import 'package:countly_flutter_np/countly_flutter.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import '../utils.dart';
import '../views_tests/view_utils.dart';

/// Tests for the requestTimeoutDuration configuration option.
/// Verifies that the SDK initializes correctly with the option set
/// and that requests are attempted.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('requestTimeoutDuration_test', (WidgetTester tester) async {
    // Create a server that delays response by 3 seconds
    // This is longer than the timeout we will set (1 second)
    List<Map<String, List<String>>> requestArray = <Map<String, List<String>>>[];
    createServer(requestArray, delay: 3);

    // Initialize SDK with a short request timeout
    CountlyConfig config = CountlyConfig(TEST_SERVER_URL, APP_KEY).enableManualSessionHandling().setLoggingEnabled(true).setRequestTimeoutDuration(1); // Set timeout to 1 second

    await Countly.initWithConfig(config);

    // Start a session to trigger a request
    await Countly.instance.sessions.beginSession();

    // Wait for a bit to allow the request to be processed
    await Future.delayed(const Duration(seconds: 5));

    // Verify that we at least attempted to send requests but they timed out thus remained in the queue
    List<String> requestList = await getRequestQueue();

    // Check if the begin_session request in the queue
    equals(requestList.length, 1);
    validateBeginSessionRequest(requestList[0]);
  });
}
