import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:countly_flutter/countly_config.dart';
import 'package:countly_flutter/countly_flutter.dart';

import '../test_utility.dart';

void main() {
  testWidgets('Bar Test', (tester) async {
    // initialize the SDK
    CountlyConfig config = createBaseConfig();
    await Countly.initWithConfig(config);

    // wait 1 second
    await Future.delayed(Duration(seconds: 1));

    // check if device id is set correctly
    String? id = await Countly.getCurrentDeviceId();
    expect(DEVICE_ID, equals(id));
  });
}
