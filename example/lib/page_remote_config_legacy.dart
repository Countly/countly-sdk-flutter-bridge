import 'package:countly_flutter_np/countly_flutter.dart';
import 'package:countly_flutter_example/helpers.dart';
import 'package:flutter/material.dart';

final navigatorKey = GlobalKey<NavigatorState>();

class RemoteConfigPageLegacy extends StatelessWidget {
  @deprecated
  void getABTestingValues() {
    // ignore: deprecated_member_use_from_same_package
    Countly.remoteConfigUpdate((result) {
      // ignore: deprecated_member_use_from_same_package
      Countly.getRemoteConfigValueForKey('baloon', (result) {
        String alertText = "Value for 'baloon' is : ${result.toString()}";
        print(alertText);
      });
    });
  }

  void eventForGoal_1() {
    var event = {'key': 'eventForGoal_1', 'count': 1};
    Countly.recordEvent(event);
  }

  void eventForGoal_2() {
    var event = {'key': 'eventForGoal_2', 'count': 1};
    Countly.recordEvent(event);
  }

  @deprecated
  void remoteConfigUpdate() {
    // ignore: deprecated_member_use_from_same_package
    Countly.remoteConfigUpdate((result) {
      print(result);
    });
  }

  @deprecated
  void updateRemoteConfigForKeysOnly() {
    // ignore: deprecated_member_use_from_same_package
    Countly.updateRemoteConfigForKeysOnly(['name'], (result) {
      print(result);
    });
  }

  @deprecated
  void getRemoteConfigValueForKeyString() {
    // ignore: deprecated_member_use_from_same_package
    Countly.getRemoteConfigValueForKey('stringValue', (result) {
      print(result);
    });
  }

  @deprecated
  void getRemoteConfigValueForKeyBoolean() {
    // ignore: deprecated_member_use_from_same_package
    Countly.getRemoteConfigValueForKey('booleanValue', (result) {
      print(result);
    });
  }

  @deprecated
  void getRemoteConfigValueForKeyFloat() {
    // ignore: deprecated_member_use_from_same_package
    Countly.getRemoteConfigValueForKey('floatValue', (result) {
      print(result);
    });
  }

  @deprecated
  void getRemoteConfigValueForKeyInteger() {
    // ignore: deprecated_member_use_from_same_package
    Countly.getRemoteConfigValueForKey('integerValue', (result) {
      print(result);
    });
  }

  @deprecated
  void updateRemoteConfigExceptKeys() {
    // ignore: deprecated_member_use_from_same_package
    Countly.updateRemoteConfigExceptKeys(['url'], (result) {
      print(result);
    });
  }

  @deprecated
  void remoteConfigClearValues() {
    // ignore: deprecated_member_use_from_same_package
    Countly.remoteConfigClearValues((result) {
      print(result);
    });
  }

  @deprecated
  void getRemoteConfigValueForKey() {
    // ignore: deprecated_member_use_from_same_package
    Countly.getRemoteConfigValueForKey('name', (result) {
      print(result);
    });
  }

  @override
  Widget build(BuildContext context) {
    return CountlyPageScaffold(
      title: 'Remote Config (Legacy)',
      sections: [
        CountlySection(
          title: 'Legacy RC Operations',
          subtitle: 'These methods are deprecated',
          children: [
            // ignore: deprecated_member_use_from_same_package
            MyButton(text: 'Remote Config Update', type: CountlyButtonType.outlined, onPressed: remoteConfigUpdate),
            // ignore: deprecated_member_use_from_same_package
            MyButton(text: 'Update For Keys Only', type: CountlyButtonType.outlined, onPressed: updateRemoteConfigForKeysOnly),
            // ignore: deprecated_member_use_from_same_package
            MyButton(text: 'Update Except Keys', type: CountlyButtonType.outlined, onPressed: updateRemoteConfigExceptKeys),
            // ignore: deprecated_member_use_from_same_package
            MyButton(text: 'Clear RC Values', type: CountlyButtonType.outlined, onPressed: remoteConfigClearValues),
          ],
        ),
        CountlySection(
          title: 'Legacy Get Values',
          children: [
            // ignore: deprecated_member_use_from_same_package
            MyButton(text: 'Get String Value', type: CountlyButtonType.outlined, onPressed: getRemoteConfigValueForKeyString),
            // ignore: deprecated_member_use_from_same_package
            MyButton(text: 'Get Boolean Value', type: CountlyButtonType.outlined, onPressed: getRemoteConfigValueForKeyBoolean),
            // ignore: deprecated_member_use_from_same_package
            MyButton(text: 'Get Float Value', type: CountlyButtonType.outlined, onPressed: getRemoteConfigValueForKeyFloat),
            // ignore: deprecated_member_use_from_same_package
            MyButton(text: 'Get Integer Value', type: CountlyButtonType.outlined, onPressed: getRemoteConfigValueForKeyInteger),
            // ignore: deprecated_member_use_from_same_package
            MyButton(text: 'Get AB Testing Values', type: CountlyButtonType.outlined, onPressed: getABTestingValues),
          ],
        ),
        CountlySection(
          title: 'Goal Events',
          children: [
            MyButton(text: 'Record Event for Goal #1', type: CountlyButtonType.tonal, onPressed: eventForGoal_1),
            MyButton(text: 'Record Event for Goal #2', type: CountlyButtonType.tonal, onPressed: eventForGoal_2),
          ],
        ),
      ],
    );
  }
}
