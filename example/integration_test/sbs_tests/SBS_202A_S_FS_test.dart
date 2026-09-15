import 'package:countly_flutter_np/countly_flutter.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../utils.dart';
import 'sbs_utils.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('SBS_202A_S_FS_test', (WidgetTester tester) async {
    List<Map<String, List<String>>> requestArray = <Map<String, List<String>>>[];
    createServerWithConfig(requestArray, {
      'v': 1,
      't': 1750748806695,
      'c': {'lvs': 'hoho', 'lsv': 'hehe', 'lbc': -5, 'ltlpt': 0, 'unkown': 'very_unkown', 'ltl': 0, 'rcz': 'no', 'ecz': 'no', 'czi': -16, 'bom': 'test', 'dort': false, 'tracking': 'no', 'scui': 0.1, 'networking': 'yes', 'cr': '', 'rqs': -5, 'sui': -10},
    });

    setServerConfig({
      'v': 1,
      't': 1750748806695,
      'c': {'st': 'yes', 'cet': 'no', 'vt': 0, 'eqs': 0, 'lt': 1, 'unkown1': 'very_unkown1', 'crt': 'value', 'bom_at': -1, 'bom_d': -1, 'bom_rqp': 50, 'bom_ra': -1, 'lkl': 'test'},
    });

    // Initialize the SDK
    CountlyConfig config = CountlyConfig(TEST_SERVER_URL, APP_KEY).enableManualSessionHandling().setLoggingEnabled(true);

    await Countly.initWithConfig(config);
    await Future.delayed(const Duration(seconds: 2));

    expect(await getServerConfig(), {'v': 1, 't': 1750748806695, 'c': {}});
  });
}
