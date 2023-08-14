// ignore_for_file: avoid_print

import 'package:countly_flutter_example/main.dart' as app;
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('Countly TEST', (tester) async {
    print('hello');
    app.main(['e14e913a4b451bc8a5c413acd1d2219a9b30b055']);
    await tester.takeException();
    await tester.pumpAndSettle();
    await tester.pumpAndSettle(Duration(seconds: 10));
    await tester.pumpAndSettle();
  });
  // await Future.delayed(Duration(seconds: 10));
  testWidgets('Countly TEST 1', (tester) async {
    print('hello');
    app.main(['6c8f7f21ba9c4a4c0b20b6c020f8de86667345c8']);
    await tester.takeException();
    await tester.pumpAndSettle();
    await tester.pumpAndSettle(Duration(seconds: 10));
    await tester.pumpAndSettle();
  });
}
