import 'package:countly_flutter_np/countly_flutter.dart';
import 'package:flutter_test/flutter_test.dart';

import '../test_utility.dart';

void main() {
  testWidgets('Bar Test', (tester) async {
    // initialize the SDK
    CountlyConfig config = createBaseConfig();
    await Countly.initWithConfig(config);

    // wait 1 second
    await Future.delayed(const Duration(seconds: 1));

    // check if device id is set correctly
    String? id = await Countly.getCurrentDeviceId();
    expect(DEVICE_ID, equals(id));
  });
}
