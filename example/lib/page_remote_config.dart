import 'package:countly_flutter/countly_flutter.dart';
import 'package:countly_flutter/experiment_information.dart';
import 'package:countly_flutter_example/helpers.dart';
import 'package:countly_flutter_example/page_remote_config_legacy.dart';
import 'package:flutter/material.dart';

class RemoteConfigPage extends StatefulWidget {
  static final RCDownloadCallback _rcDownloadCallback = (rResult, error, fullValueUpdate, downloadedValues) {
    print('RCDownloadCallback, Result:[$rResult]');
  };

  @override
  State<RemoteConfigPage> createState() => _RemoteConfigPageState();
}

class _RemoteConfigPageState extends State<RemoteConfigPage> {
  var rcKey;

//===================================================
// Contents
//===================================================
  void Contents() {}
// Manual Download Calls
  /// Download All RC Values [downloadAllRCValues]
  /// Download Specific RC Values [downloadSpecificRCValues]
  /// Download Omitting Specific RC Values [downloadOmittingSpecificRCValues]
// Accessing Values
  /// Get All RC Values [getAllRCValues]
  /// Get Specific RC Values [getSpecificRCValues]
// Clearing Values
  /// Clear All RC Values [clearAllRCValues]
// Global Download Callbacks
  /// Register RC Download Callback [registerRCDownloadCallback]
  /// Remove RC Download Callback [removeRCDownloadCallback]
// AB Testing
// Enroll on Access
  /// Get All RC Values And Enroll [getAllRCValuesAndEnroll]
  /// Get Specific RC Values And Enroll [getSpecificRCValuesAndEnroll]
// Enroll on Action
  /// Enroll Into AB Tests [enrollIntoABTests]
// Exiting AB Tests
  /// Exit AB Tests [exitABTests]
// Variant Download Calls
  /// Fetch All Test Variants [downloadAllTestVariants]
  /// Fetch Specific Test Variants [downloadSpecificTestVariants]
// Experiment Information
  /// Download Experiment Information [downloadExperimentInfo]

//===================================================
// Manual Download Calls
//===================================================
  /// Downloads all RC Values irrespective of the keys
  /// Return back to contents [Contents]
  void downloadAllRCValues() {
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

  /// Downloads specific RC Values based on the keys
  /// Return back to contents [Contents]
  void downloadSpecificRCValues() {
    final RCDownloadCallback callback = (rResult, error, fullValueUpdate, downloadedValues) {
      print(rResult);
      print(error);
      print(fullValueUpdate);
      for (final entry in downloadedValues.entries) {
        print('key: ${entry.key}: value: ${entry.value.value}');
      }
    };
    Countly.instance.remoteConfig.downloadSpecificKeys([rcKey], callback);
  }

  /// Downloads all RC Values except the specified keys
  /// Return back to contents [Contents]
  void downloadOmittingSpecificRCValues() {
    final RCDownloadCallback callback = (rResult, error, fullValueUpdate, downloadedValues) {
      print(rResult);
      print(error);
      print(fullValueUpdate);
      for (final entry in downloadedValues.entries) {
        print('key: ${entry.key}: value: ${entry.value.value}');
      }
    };
    Countly.instance.remoteConfig.downloadOmittingKeys([rcKey], callback);
  }

//===================================================
// Accessing Values
//===================================================
  /// Gets all RC values from storage and prints them
  /// Return back to contents [Contents]
  Future<void> getAllRCValues() async {
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

  /// Gets specific RC values from storage and prints them
  /// Return back to contents [Contents]
  Future<void> getSpecificRCValues() async {
    RCData data = await Countly.instance.remoteConfig.getValue(rcKey);
    print('getSpecificRCValues, value:${data.value} cache: ${data.isCurrentUsersData}');
  }

//===================================================
// Clearing Values
//===================================================
  /// Clear all RC values from storage
  /// Return back to contents [Contents]
  void clearAllRCValues() {
    Countly.instance.remoteConfig.clearAll();
  }

//===================================================
// Global Download Callbacks
//===================================================
  /// For registering a callback that is called when a remote config download is completed
  /// Return back to contents [Contents]
  void registerRCDownloadCallback() {
    Countly.instance.remoteConfig.registerDownloadCallback(RemoteConfigPage._rcDownloadCallback);
  }

  /// For removing a global RC callback
  /// Return back to contents [Contents]
  void removeRCDownloadCallback() {
    Countly.instance.remoteConfig.removeDownloadCallback(RemoteConfigPage._rcDownloadCallback);
  }

//===================================================
// AB Testing
//===================================================
// Enroll on Access -------------------------------
  /// Gets specific RC values from storage and prints them also enroll for that key
  /// Return back to contents [Contents]
  Future<void> getSpecificRCValuesAndEnroll() async {
    RCData data = await Countly.instance.remoteConfig.getValueAndEnroll(rcKey);
    print('getSpecificRCValuesAndEnroll, value:${data.value} cache: ${data.isCurrentUsersData}');
  }

  /// Gets all RC values from storage and prints them also enroll for all keys
  /// Return back to contents [Contents]
  Future<void> getAllRCValuesAndEnroll() async {
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

// Enroll on Action -------------------------------
  /// Enroll into AB tests for the specified keys
  /// Return back to contents [Contents]
  void enrollIntoABTests() {
    Countly.instance.remoteConfig.enrollIntoABTestsForKeys([rcKey]);
  }

// Exiting AB Tests -------------------------------
  /// Exits from AB tests for the specified keys
  /// Return back to contents [Contents]
  void exitABTests() {
    Countly.instance.remoteConfig.exitABTestsForKeys([rcKey]);
  }

// Variant Download Calls -------------------------------
  /// Downloads all test variants
  /// Return back to contents [Contents]
  void downloadAllTestVariants() {
    Countly.instance.remoteConfig.testingGetAllVariants();
  }

  /// Downloads specific test variants
  /// Return back to contents [Contents]
  void downloadSpecificTestVariants() {
    Countly.instance.remoteConfig.testingGetVariantsForKey(rcKey);
  }

// Experiment Information -------------------------------
  /// Downloads experiment information and prints it
  /// Return back to contents [Contents]
  void downloadExperimentInfo() {
    Countly.instance.remoteConfig.testingDownloadExperimentInformation((rResult, error) async {
      if (rResult == RequestResult.success) {
        Map<String, ExperimentInformation> experimentInfoMap = await Countly.instance.remoteConfig.testingGetAllExperimentInfo();
        print(experimentInfoMap);
      }
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
            SizedBox(
              height: 40,
              child: TextField(
                onSubmitted: (value) {
                  setState(() {
                    rcKey = value;
                  });
                },
                decoration: const InputDecoration(
                  border: OutlineInputBorder(gapPadding: 4.0, borderSide: BorderSide(color: Colors.teal), borderRadius: BorderRadius.all(Radius.circular(20.0))),
                  hintText: 'Enter an RC Key',
                ),
              ),
            ),
            countlySpacer(),
            countlyTitle('Manual Download Calls'),
            MyButton(text: 'Download All RC Values', color: 'green', onPressed: downloadAllRCValues),
            MyButton(text: 'Download Specific RC Values', color: 'green', onPressed: downloadSpecificRCValues),
            MyButton(text: 'Download Omitting Specific RC Values', color: 'green', onPressed: downloadOmittingSpecificRCValues),
            countlySpacer(),
            countlyTitle('Accessing Values'),
            MyButton(text: 'Get All RC Values', color: 'teal', onPressed: getAllRCValues),
            MyButton(text: 'Get Specific RC Values', color: 'teal', onPressed: getSpecificRCValues),
            countlySpacer(),
            countlyTitle('Clearing Values'),
            MyButton(text: 'Clear All RC Values', color: 'red', onPressed: clearAllRCValues),
            countlySpacer(),
            countlyTitle('Global Download Callbacks'),
            MyButton(text: 'Register RC Download Callback', color: 'orange', onPressed: registerRCDownloadCallback),
            MyButton(text: 'Remove RC Download Callback', color: 'red', onPressed: removeRCDownloadCallback),
            countlySpacer(),
            countlyTitle('AB Testing'),
            countlySubTitle('Enroll on Access'),
            MyButton(text: 'Get All RC Values And Enroll', color: 'teal', onPressed: getAllRCValuesAndEnroll),
            MyButton(text: 'Get Specific RC Values And Enroll', color: 'teal', onPressed: getSpecificRCValuesAndEnroll),
            countlySpacerSmall(),
            countlySubTitle('Enroll on Action'),
            MyButton(text: 'Enroll Into AB Tests', color: 'blue', onPressed: enrollIntoABTests),
            countlySpacerSmall(),
            countlySubTitle('Exiting AB Tests'),
            MyButton(text: 'Exit AB Tests', color: 'red', onPressed: exitABTests),
            countlySpacerSmall(),
            countlySubTitle('Variant Download Calls'),
            MyButton(text: 'Fetch All Test Variants', color: 'green', onPressed: downloadAllTestVariants),
            MyButton(text: 'Fetch Specific Test Variants', color: 'green', onPressed: downloadSpecificTestVariants),
            countlySpacerSmall(),
            countlySubTitle('Experiment Information'),
            MyButton(text: 'Download Experiment Information', color: 'yellow', onPressed: downloadExperimentInfo),
            countlySpacer(),
            countlyTitle('Legacy Remote Config Methods'),
            MyButton(
                text: 'Remote Config (Legacy)',
                color: 'gray',
                onPressed: () {
                  navigateToPage(context, RemoteConfigPageLegacy());
                }),
          ],
        )),
      ),
    );
  }
}
