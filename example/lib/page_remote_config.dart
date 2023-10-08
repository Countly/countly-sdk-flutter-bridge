import 'package:countly_flutter/countly_flutter.dart';
import 'package:countly_flutter/experiment_information.dart';
import 'package:countly_flutter_example/helpers.dart';
import 'package:flutter/material.dart';

final navigatorKey = GlobalKey<NavigatorState>();

class RemoteConfigPage extends StatelessWidget {
  static final RCDownloadCallback _rcDownloadCallback = (rResult, error, fullValueUpdate, downloadedValues) {
    print('Registered callback:[$rResult]');
  };

  void remoteConfigDownloadExperimentInfo() {
    Countly.instance.remoteConfig.testingDownloadExperimentInformation((rResult, error) async {
      if (rResult == RequestResult.success) {
        Map<String, ExperimentInformation> experimentInfoMap = await Countly.instance.remoteConfig.testingGetAllExperimentInfo();
        print(experimentInfoMap);
      }
    });
  }

  void remoteConfigRegisterDownloadCallback() {
    Countly.instance.remoteConfig.registerDownloadCallback(_rcDownloadCallback);
  }

  void remoteConfigRemoveDownloadCallback() {
    Countly.instance.remoteConfig.removeDownloadCallback(_rcDownloadCallback);
  }

  void remoteConfigDownloadKeys() {
    final RCDownloadCallback callback = (rResult, error, fullValueUpdate, downloadedValues) {
      print(rResult);
      print(error);
      print(fullValueUpdate);
      for (final entry in downloadedValues.entries) {
        print('key: ${entry.key}: value: ${entry.value.value}');
      }
    };
    Countly.instance.remoteConfig.downloadAllKeys(callback);
  }

  void remoteConfigDownloadSpecificKeys() {
    final RCDownloadCallback callback = (rResult, error, fullValueUpdate, downloadedValues) {
      print(rResult);
      print(error);
      print(fullValueUpdate);
      for (final entry in downloadedValues.entries) {
        print('key: ${entry.key}: value: ${entry.value.value}');
      }
    };
    Countly.instance.remoteConfig.downloadSpecificKeys(['rc_1', 'ab_1'], callback);
  }

  void remoteConfigDownloadOmittingKeys() {
    final RCDownloadCallback callback = (rResult, error, fullValueUpdate, downloadedValues) {
      print(rResult);
      print(error);
      print(fullValueUpdate);
      for (final entry in downloadedValues.entries) {
        print('key: ${entry.key}: value: ${entry.value.value}');
      }
    };
    Countly.instance.remoteConfig.downloadOmittingKeys(['rc_1', 'ab_1'], callback);
  }

  Future<void> remoteConfigGetAllValues() async {
    final allValues = await Countly.instance.remoteConfig.getAllValues();
    for (final entry in allValues.entries) {
      final value = entry.value.value;
      print('key: ${entry.key}, value: $value, DataType: ${value.runtimeType}');
      if (value is Map) {
        print('begin 2nd level iteration');
        for (final entry1 in value.entries) {
          final value1 = entry1.value;
          print('2nd iteration - key: ${entry1.key}, value: $value1, DataType: ${value1.runtimeType}');
        }
        print('end 2nd level iteration');
      }
    }
  }

  void remoteConfigGetValue() {
    Countly.instance.remoteConfig.getValue('testKey');
  }

  void remoteConfigGetValueAndEnroll() {
    Countly.instance.remoteConfig.getValueAndEnroll('testKey');
  }

  Future<void> remoteConfigGetAllValuesAndEnroll() async {
    final allValues = await Countly.instance.remoteConfig.getAllValuesAndEnroll();
    for (final entry in allValues.entries) {
      final value = entry.value.value;
      print('key: ${entry.key}, value: $value, DataType: ${value.runtimeType}');
      if (value is Map) {
        print('begin 2nd level iteration');
        for (final entry1 in value.entries) {
          final value1 = entry1.value;
          print('2nd iteration - key: ${entry1.key}, value: $value1, DataType: ${value1.runtimeType}');
        }
        print('end 2nd level iteration');
      }
    }
  }

  void remoteConfigClearAll() {
    Countly.instance.remoteConfig.clearAll();
  }

  void remoteConfigEnrollIntoABTestsForKeys() {
    Countly.instance.remoteConfig.enrollIntoABTestsForKeys(['testKey']);
  }

  void remoteConfigExitABTestsForKeys() {
    Countly.instance.remoteConfig.exitABTestsForKeys(['testKey']);
  }

  void remoteConfigFetchVariantForKeys() {
    Countly.instance.remoteConfig.testingGetVariantsForKey('testKey');
  }

  void remoteConfigFetchAllVariant() {
    Countly.instance.remoteConfig.testingGetAllVariants();
  }

  void getRemoteConfigValueString() {
    Countly.instance.remoteConfig.getValue('stringValue');
  }

  void getRemoteConfigValueBoolean() {
    Countly.instance.remoteConfig.getValue('booleanValue');
  }

  void getRemoteConfigValueFloat() {
    Countly.instance.remoteConfig.getValue('floatValue');
  }

  void getRemoteConfigValueInteger() {
    Countly.instance.remoteConfig.getValue('integerValue');
  }

  void _showDialog(String alertText) {
    showDialog(
      context: navigatorKey.currentContext!,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Alert!!'),
          content: Text(alertText),
          actions: <Widget>[
            ElevatedButton(
              child: const Text('OK'),
              onPressed: () {
                Navigator.of(navigatorKey.currentContext!).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @deprecated
  void getABTestingValues() {
    Countly.remoteConfigUpdate((result) {
      Countly.getRemoteConfigValueForKey('baloon', (result) {
        String alertText = "Value for 'baloon' is : ${result.toString()}";
        _showDialog(alertText);
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
            MyButton(text: 'Remote Config Download Experiment Info', color: 'yellow', onPressed: remoteConfigDownloadExperimentInfo),
            MyButton(text: 'Remote Config Register Download Callback', color: 'orange', onPressed: remoteConfigRegisterDownloadCallback),
            MyButton(text: 'Remote Config Remove Download Callback', color: 'orange', onPressed: remoteConfigRemoveDownloadCallback),
            MyButton(text: 'Remote Config Download Values', color: 'green', onPressed: remoteConfigDownloadKeys),
            MyButton(text: 'Remote Config Download Specific Value', color: 'green', onPressed: remoteConfigDownloadSpecificKeys),
            MyButton(text: 'Remote Config Download Omitting Values', color: 'green', onPressed: remoteConfigDownloadOmittingKeys),
            MyButton(text: 'Remote Config Get All Values', color: 'teal', onPressed: remoteConfigGetAllValues),
            MyButton(text: 'Remote Config Get Value', color: 'teal', onPressed: remoteConfigGetValue),
            MyButton(text: 'Remote Config Get Value And Enroll', color: 'purple', onPressed: remoteConfigGetValueAndEnroll),
            MyButton(text: 'Remote Config Get All Values And Enroll', color: 'purple', onPressed: remoteConfigGetAllValuesAndEnroll),
            MyButton(text: 'Remote Config Clear All Values', color: 'orange', onPressed: remoteConfigClearAll),
            MyButton(text: 'Remote Config Enroll Into AB Tests For Keys', color: 'brown', onPressed: remoteConfigEnrollIntoABTestsForKeys),
            MyButton(text: 'Remote Config Exit AB Tests For Keys', color: 'brown', onPressed: remoteConfigExitABTestsForKeys),
            MyButton(text: 'Remote Config FetchVariantForKeys', color: 'brown', onPressed: remoteConfigFetchVariantForKeys),
            MyButton(text: 'Remote Config Fetch All Variant', color: 'brown', onPressed: remoteConfigFetchAllVariant),
            MyButton(text: 'Get String Value', color: 'violet', onPressed: getRemoteConfigValueString),
            MyButton(text: 'Get Boolean Value', color: 'violet', onPressed: getRemoteConfigValueBoolean),
            MyButton(text: 'Get Float Value', color: 'violet', onPressed: getRemoteConfigValueFloat),
            MyButton(text: 'Get Integer Value', color: 'violet', onPressed: getRemoteConfigValueInteger),
            MyButton(text: 'Countly.remoteConfigUpdate (Legacy)', color: 'red', onPressed: remoteConfigUpdate),
            MyButton(text: 'Countly.updateRemoteConfigForKeysOnly (Legacy)', color: 'red', onPressed: updateRemoteConfigForKeysOnly),
            MyButton(text: 'Countly.updateRemoteConfigExceptKeys (Legacy)', color: 'red', onPressed: updateRemoteConfigExceptKeys),
            MyButton(text: 'Countly.remoteConfigClearValues (Legacy)', color: 'red', onPressed: remoteConfigClearValues),
            MyButton(text: 'Get String Value (Legacy)', color: 'red', onPressed: getRemoteConfigValueForKeyString),
            MyButton(text: 'Get Boolean Value (Legacy)', color: 'red', onPressed: getRemoteConfigValueForKeyBoolean),
            MyButton(text: 'Get Float Value (Legacy)', color: 'red', onPressed: getRemoteConfigValueForKeyFloat),
            MyButton(text: 'Get Integer Value (Legacy)', color: 'red', onPressed: getRemoteConfigValueForKeyInteger),
            MyButton(text: 'Get AB testing values (Legacy)', color: 'red', onPressed: getABTestingValues),
            MyButton(text: 'Record event for goal #1', color: 'red', onPressed: eventForGoal_1),
            MyButton(text: 'Record event for goal #2', color: 'red', onPressed: eventForGoal_2),
          ],
        )),
      ),
    );
  }
}
