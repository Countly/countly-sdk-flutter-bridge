import 'dart:io';

import 'package:countly_flutter_np/countly_flutter.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../utils.dart';
import 'sbs_utils.dart';

/// Filter Mutual Exclusivity + Boundary Validation Test
/// Tests:
/// - When both blacklist AND whitelist are provided for the same filter type,
///   the server response should override stored values and resolve the conflict
/// - Boundary values for czi (>= 16), bom_rqp (0.0 < x < 1.0), dort (>= 0)
/// - Invalid filter types (non-array for eb, non-object for esb) should be rejected
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('SBS_202C_test', (WidgetTester tester) async {
    List<Map<String, List<String>>> requestArray = <Map<String, List<String>>>[];

    // Server provides whitelists — these should override stored blacklists
    createServerWithConfig(requestArray, {
      'v': 1,
      't': 1750748806695,
      'c': {
        // Whitelists from server should remove stored blacklists
        'ew': ['event1', 'event2'],
        'sw': ['key1', 'key2'],
        // Boundary values — all should be rejected as invalid
        'czi': 15, // below minimum of 16
        'bom_rqp': 1.0, // boundary: must be < 1.0
        'dort': -1, // must be >= 0
        // Invalid filter types — should be rejected
        'eb': 'not_an_array', // should be array
        'esb': 'not_an_object', // should be object
        'jte': 123, // should be array
        'upb': true, // should be array
      },
    });

    // Store blacklists — these should be removed when server provides whitelists
    setServerConfig({
      'v': 1,
      't': 1750748806695,
      'c': {
        'eb': ['old_blocked_event'],
        'sb': ['old_blocked_key'],
        // Valid boundary values that should be accepted
        'czi': 16, // exactly at minimum
        'bom_rqp': 0.5, // valid range
        'dort': 0, // exactly at minimum (0 = disabled)
      },
    });

    // Initialize the SDK
    CountlyConfig config = CountlyConfig(TEST_SERVER_URL, APP_KEY).enableManualSessionHandling().setLoggingEnabled(true);
    await Countly.initWithConfig(config);
    await Future.delayed(const Duration(seconds: 2));

    // Validate stored config after merge and validation
    Map<String, dynamic> storedConfig = await getServerConfig();
    Map<String, dynamic> c = storedConfig['c'];

    // Whitelists from server should be stored
    expect(c.containsKey('ew'), isTrue, reason: 'Event whitelist from server should be stored');
    expect(c['ew'], ['event1', 'event2']);
    expect(c.containsKey('sw'), isTrue, reason: 'Segmentation whitelist from server should be stored');
    expect(c['sw'], ['key1', 'key2']);

    // Blacklists from stored config should be removed because server provided whitelists
    expect(c.containsKey('eb'), isFalse, reason: 'Event blacklist should be removed when server provides event whitelist');
    expect(c.containsKey('sb'), isFalse, reason: 'Segmentation blacklist should be removed when server provides segmentation whitelist');

    // Invalid boundary values from server should be rejected
    // iOS removes invalid keys from the dictionary entirely
    // Android rejects invalid server values but stored valid values persist from setServerConfig
    if (Platform.isIOS) {
      expect(c.containsKey('czi'), isFalse, reason: 'iOS: czi: 15 should be rejected and removed');
      expect(c.containsKey('bom_rqp'), isFalse, reason: 'iOS: bom_rqp: 1.0 should be rejected and removed');
      expect(c.containsKey('dort'), isFalse, reason: 'iOS: dort: -1 should be rejected and removed');
    } else {
      expect(c['czi'], 16, reason: 'Android: czi: 15 from server rejected, stored 16 persists');
      expect(c['bom_rqp'], 0.5, reason: 'Android: bom_rqp: 1.0 from server rejected, stored 0.5 persists');
      expect(c['dort'], 0, reason: 'Android: dort: -1 from server rejected, stored 0 persists');
    }

    // Invalid filter types should be rejected
    expect(c.containsKey('esb'), isFalse, reason: 'esb: string should be rejected (must be object)');
    expect(c.containsKey('jte'), isFalse, reason: 'jte: integer should be rejected (must be array)');
    expect(c.containsKey('upb'), isFalse, reason: 'upb: boolean should be rejected (must be array)');
  });
}
