import 'package:integration_test/integration_test.dart';
import 'base_queue_test.dart' as queue_test;
import 'views_tests/auto_view_flow1_test.dart' as auto_view_flow1_test;
import 'views_tests/auto_view_flow2_test.dart' as auto_view_flow2_test;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  queue_test.main();
}
