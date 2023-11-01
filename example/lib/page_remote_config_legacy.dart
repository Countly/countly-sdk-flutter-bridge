import 'package:countly_flutter/countly_flutter.dart';
import 'package:countly_flutter_example/helpers.dart';
import 'package:flutter/material.dart';

final navigatorKey = GlobalKey<NavigatorState>();

class RemoteConfigPageLegacy extends StatelessWidget {

  @deprecated
  void getABTestingValues() {
    Countly.remoteConfigUpdate((result) {
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
    Countly.remoteConfigUpdate((result) {
      print(result);
    });
  }

  @deprecated
  void updateRemoteConfigForKeysOnly() {
    Countly.updateRemoteConfigForKeysOnly(['name'], (result) {
      print(result);
    });
  }

  @deprecated
  void getRemoteConfigValueForKeyString() {
    Countly.getRemoteConfigValueForKey('stringValue', (result) {
      print(result);
    });
  }

  @deprecated
  void getRemoteConfigValueForKeyBoolean() {
    Countly.getRemoteConfigValueForKey('booleanValue', (result) {
      print(result);
    });
  }

  @deprecated
  void getRemoteConfigValueForKeyFloat() {
    Countly.getRemoteConfigValueForKey('floatValue', (result) {
      print(result);
    });
  }

  @deprecated
  void getRemoteConfigValueForKeyInteger() {
    Countly.getRemoteConfigValueForKey('integerValue', (result) {
      print(result);
    });
  }

  @deprecated
  void updateRemoteConfigExceptKeys() {
    Countly.updateRemoteConfigExceptKeys(['url'], (result) {
      print(result);
    });
  }

  @deprecated
  void remoteConfigClearValues() {
    Countly.remoteConfigClearValues((result) {
      print(result);
    });
  }

  @deprecated
  void getRemoteConfigValueForKey() {
    Countly.getRemoteConfigValueForKey('name', (result) {
      print(result);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Remote Config'),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(15),
        child: Center(
            child: Column(
          children: [
            // ignore: deprecated_member_use_from_same_package
            MyButton(text: 'Countly.remoteConfigUpdate (Legacy)', color: 'red', onPressed: remoteConfigUpdate),
            // ignore: deprecated_member_use_from_same_package
            MyButton(text: 'Countly.updateRemoteConfigForKeysOnly (Legacy)', color: 'red', onPressed: updateRemoteConfigForKeysOnly),
            // ignore: deprecated_member_use_from_same_package
            MyButton(text: 'Countly.updateRemoteConfigExceptKeys (Legacy)', color: 'red', onPressed: updateRemoteConfigExceptKeys),
            // ignore: deprecated_member_use_from_same_package
            MyButton(text: 'Countly.remoteConfigClearValues (Legacy)', color: 'red', onPressed: remoteConfigClearValues),
            // ignore: deprecated_member_use_from_same_package
            MyButton(text: 'Get String Value (Legacy)', color: 'red', onPressed: getRemoteConfigValueForKeyString),
            // ignore: deprecated_member_use_from_same_package
            MyButton(text: 'Get Boolean Value (Legacy)', color: 'red', onPressed: getRemoteConfigValueForKeyBoolean),
            // ignore: deprecated_member_use_from_same_package
            MyButton(text: 'Get Float Value (Legacy)', color: 'red', onPressed: getRemoteConfigValueForKeyFloat),
            // ignore: deprecated_member_use_from_same_package
            MyButton(text: 'Get Integer Value (Legacy)', color: 'red', onPressed: getRemoteConfigValueForKeyInteger),
            // ignore: deprecated_member_use_from_same_package
            MyButton(text: 'Get AB testing values (Legacy)', color: 'red', onPressed: getABTestingValues),
            MyButton(text: 'Record event for goal #1', color: 'red', onPressed: eventForGoal_1),
            MyButton(text: 'Record event for goal #2', color: 'red', onPressed: eventForGoal_2),
          ],
        )),
      ),
    );
  }
}
