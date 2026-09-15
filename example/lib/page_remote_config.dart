import 'package:countly_flutter_np/countly_flutter.dart';
import 'package:countly_flutter_np/experiment_information.dart';
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
  String rcKey = 'testKey';
  @override
  Widget build(BuildContext context) {
    final RCDownloadCallback callback = (rResult, error, fullValueUpdate, downloadedValues) {
      if (error != null) {
        print('RCDownloadCallback, Result:[$rResult], error:[$error]');
        return;
      }
      String downloadedValuesString = '';
      for (final entry in downloadedValues.entries) {
        downloadedValuesString += '||key: ${entry.key}, value: ${entry.value.value}||\n';
      }
      String message = 'Manual Download, Result:[${rResult}, updatedAll:[${fullValueUpdate}], downloadedValues:[\n${downloadedValuesString}]';
      print(message);
      showCountlyToast(context, message, null);
    };

//===================================================
// Contents
//===================================================
    // ignore: unused_element
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
    /// Enroll Into an AB Experiment [enrollIntoABExperiment]
// Exiting AB Tests
    /// Exit AB Tests [exitABTests]
    /// Exit an AB Experiment [exitABExperiment]
// Variant Download/Get Calls
    /// Download All Test Variants [downloadAllVariants]
    /// Get All Test Variants [getAllTestVariants]
    /// Get Specific Test Variants [getSpecificTestVariants]
    /// Enroll Into Variant [enrollIntoVariant]
// Experiment Information
    /// Download Experiment Information [downloadExperimentInfo]
    /// Get Experiment Information [getExperimentInfo]

//===================================================
// Manual Download Calls
//===================================================

    /// Downloads all RC Values irrespective of the keys
    /// Return back to [Contents]
    void downloadAllRCValues() {
      Countly.instance.remoteConfig.downloadAllKeys(callback);
    }

    /// Downloads specific RC Values based on the keys
    /// Return back to [Contents]
    void downloadSpecificRCValues() {
      Countly.instance.remoteConfig.downloadSpecificKeys([rcKey], callback);
    }

    /// Downloads all RC Values except the specified keys
    /// Return back to [Contents]
    void downloadOmittingSpecificRCValues() {
      Countly.instance.remoteConfig.downloadOmittingKeys([rcKey], callback);
    }

//===================================================
// Accessing Values
//===================================================
    /// Gets all RC values from storage and prints them
    /// Return back to [Contents]
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
      String resultString = '';
      allValues.forEach((key, RCData) {
        resultString += '\nKey: [$key],';
        resultString += ' Value: [${RCData.value}] (${RCData.value.runtimeType}),';
        resultString += ' isCurrentUSer: [${RCData.isCurrentUsersData}]';
      });
      if (context.mounted) {
        showCountlyToast(context, resultString, null);
      }
    }

    /// Gets specific RC values from storage and prints them
    /// Return back to [Contents]
    Future<void> getSpecificRCValues() async {
      try {
        RCData data = await Countly.instance.remoteConfig.getValue(rcKey);
        final s = data.value;
        print('getSpecificRCValues, value:${data.value} with type:${s.runtimeType}, cache: ${data.isCurrentUsersData}');
        if (context.mounted) {
          showCountlyToast(context, 'value:${data.value}', null);
        }
      } catch (e) {
        print(e);
      }
    }

//===================================================
// Clearing Values
//===================================================
    /// Clear all RC values from storage
    /// Return back to [Contents]
    void clearAllRCValues() {
      Countly.instance.remoteConfig.clearAll();
      showCountlyToast(context, 'Cleared All RC Data', Colors.red);
    }

//===================================================
// Global Download Callbacks
//===================================================
    /// For registering a callback that is called when a remote config download is completed
    /// Return back to [Contents]
    void registerRCDownloadCallback() {
      Countly.instance.remoteConfig.registerDownloadCallback(RemoteConfigPage._rcDownloadCallback);
    }

    /// For removing a global RC callback
    /// Return back to [Contents]
    void removeRCDownloadCallback() {
      Countly.instance.remoteConfig.removeDownloadCallback(RemoteConfigPage._rcDownloadCallback);
    }

//===================================================
// AB Testing
//===================================================
// Enroll on Access -------------------------------
    /// Gets specific RC values from storage and prints them also enroll for that key
    /// Return back to [Contents]
    Future<void> getSpecificRCValuesAndEnroll() async {
      RCData data = await Countly.instance.remoteConfig.getValueAndEnroll(rcKey);
      print('getSpecificRCValuesAndEnroll, value:${data.value} cache: ${data.isCurrentUsersData}');
      if (context.mounted) {
        showCountlyToast(context, 'value:${data.value}', null);
      }
    }

    /// Gets all RC values from storage and prints them also enroll for all keys
    /// Return back to [Contents]
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
      String resultString = '';
      allValues.forEach((key, RCData) {
        resultString += '\nKey: [$key],';
        resultString += ' Value: [${RCData.value}] (${RCData.value.runtimeType}),';
        resultString += ' isCurrentUSer: [${RCData.isCurrentUsersData}]';
      });
      if (context.mounted) {
        showCountlyToast(context, resultString, null);
      }
    }

// Enroll on Action -------------------------------
    /// Enroll into AB tests for the specified keys
    /// Return back to [Contents]
    void enrollIntoABTests() {
      Countly.instance.remoteConfig.enrollIntoABTestsForKeys([rcKey]);
      showCountlyToast(context, 'Enrolled to tests', null);
    }

    /// Enroll into an AB experiment (for its all keys)
    /// Return back to [Contents]
    Future<void> enrollIntoABExperiment() async {
      // Get All Experiment information from the server
      Map<String, ExperimentInformation> experimentInfoMap = await Countly.instance.remoteConfig.testingGetAllExperimentInfo();
      String experimentID = 'EXPERIMENT_ID';
      if (experimentInfoMap.isNotEmpty) {
        // Get the first experiment's ID
        ExperimentInformation experimentInformation = experimentInfoMap.entries.first.value;
        experimentID = experimentInformation.experimentID;
      }
      await Countly.instance.remoteConfig.testingEnrollIntoABExperiment(experimentID);
    }

// Exiting AB Tests -------------------------------
    /// Exits from AB tests for the specified keys
    /// Return back to [Contents]
    void exitABTests() {
      Countly.instance.remoteConfig.exitABTestsForKeys([rcKey]);
      showCountlyToast(context, 'Exited from tests', null);
    }

    /// Exits from an AB experiment (for its all keys)
    /// Return back to [Contents]
    Future<void> exitABExperiment() async {
      Map<String, ExperimentInformation> experimentInfoMap = await Countly.instance.remoteConfig.testingGetAllExperimentInfo();
      String experimentID = 'EXPERIMENT_ID';
      if (experimentInfoMap.isNotEmpty) {
        ExperimentInformation experimentInformation = experimentInfoMap.entries.first.value;
        experimentID = experimentInformation.experimentID;
      }
      await Countly.instance.remoteConfig.testingExitABExperiment(experimentID);
    }

// Variant Download Calls -------------------------------
    /// Downloads all test variants
    /// Return back to [Contents]
    Future<void> downloadAllVariants() async {
      await Countly.instance.remoteConfig.testingDownloadVariantInformation(
        (rResult, error) {
          showCountlyToast(context, 'Downloaded all variants', null);
        },
      );
    }

    /// Downloads all test variants
    /// Return back to [Contents]
    Future<void> getAllTestVariants() async {
      String resultString = '';
      Map<String, List<String>> result = await Countly.instance.remoteConfig.testingGetAllVariants();
      result.forEach((key, value) {
        resultString += '\n[$key]:\n';
        value.forEach((item) {
          resultString += '- [$item]\n';
        });
      });
      print(resultString);
      if (context.mounted) {
        showCountlyToast(context, resultString, null);
      }
    }

    /// Enroll into a specific variant for a key
    /// Return back to [Contents]
    Future<void> enrollIntoVariant() async {
      await Countly.instance.remoteConfig.testingEnrollIntoVariant(
        rcKey,
        'variantName',
        (rResult, error) {
          if (error != null) {
            showCountlyToast(context, 'Enroll into variant failed: $error', Colors.red);
          } else {
            showCountlyToast(context, 'Enrolled into variant: $rResult', null);
          }
        },
      );
    }

    /// Downloads specific test variants
    /// Return back to [Contents]
    Future<void> getSpecificTestVariants() async {
      String resultString = '';
      List<String> result = await Countly.instance.remoteConfig.testingGetVariantsForKey(rcKey);
      result.forEach((item) {
        resultString += '- [$item]\n';
      });
      print(resultString);
      if (context.mounted) {
        showCountlyToast(context, resultString, null);
      }
    }

// Experiment Information -------------------------------
    /// Downloads experiment information
    /// Return back to [Contents]
    void downloadExperimentInfo() {
      String message = 'Downloaded experiment information';
      Color? color = null;
      Countly.instance.remoteConfig.testingDownloadExperimentInformation((rResult, error) {
        if (error != null) {
          print('RCDownloadCallback, Result:[$rResult], error:[$error]');
          message = 'Downloaded experiment information failed';
          color = Colors.red;
        }
        showCountlyToast(context, message, color);
      });
    }

    /// Gets experiment information and prints it
    /// Return back to [Contents]
    Future<void> getExperimentInfo() async {
      Map<String, ExperimentInformation> experimentInfoMap = await Countly.instance.remoteConfig.testingGetAllExperimentInfo();
      String resultString = '';
      for (final experimentInfoEntry in experimentInfoMap.entries) {
        final experimentInfo = experimentInfoEntry.value;
        resultString += '- key: ${experimentInfoEntry.key}, experimentID: ${experimentInfo.experimentID}, experimentName: ${experimentInfo.experimentName}, experimentDescription: ${experimentInfo.experimentDescription}, currentVariant: ${experimentInfo.currentVariant}';
        resultString += '\nVariants:';
        for (final variant in experimentInfo.variants.entries) {
          resultString += '\n-- ${variant.key}:';
          for (final variantValue in variant.value.entries) {
            resultString += '\nkey: ${variantValue.key}, value: ${variantValue.value}\n';
          }
        }
      }

      print(resultString);
      if (context.mounted) {
        showCountlyToast(context, resultString, null);
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Remote Config'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          CountlySection(
            title: 'RC Key',
            children: [
              TextField(
                onSubmitted: (value) {
                  setState(() {
                    rcKey = value;
                  });
                },
                decoration: const InputDecoration(
                  labelText: 'RC Key',
                  hintText: 'Enter an RC Key',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          CountlySection(
            title: 'Manual Download Calls',
            children: [
              MyButton(text: 'Download All RC Values', type: CountlyButtonType.filled, onPressed: downloadAllRCValues),
              MyButton(text: 'Download Specific RC Values', type: CountlyButtonType.tonal, onPressed: downloadSpecificRCValues),
              MyButton(text: 'Download Omitting Specific RC Values', type: CountlyButtonType.tonal, onPressed: downloadOmittingSpecificRCValues),
            ],
          ),
          const SizedBox(height: 16),
          CountlySection(
            title: 'Accessing Values',
            children: [
              MyButton(text: 'Get All RC Values', type: CountlyButtonType.tonal, onPressed: getAllRCValues),
              MyButton(text: 'Get Specific RC Values', type: CountlyButtonType.tonal, onPressed: getSpecificRCValues),
            ],
          ),
          const SizedBox(height: 16),
          CountlySection(
            title: 'Clearing Values',
            children: [
              MyButton(text: 'Clear All RC Values', type: CountlyButtonType.outlined, onPressed: clearAllRCValues),
            ],
          ),
          const SizedBox(height: 16),
          CountlySection(
            title: 'Global Download Callbacks',
            children: [
              MyButton(text: 'Register RC Download Callback', type: CountlyButtonType.tonal, onPressed: registerRCDownloadCallback),
              MyButton(text: 'Remove RC Download Callback', type: CountlyButtonType.outlined, onPressed: removeRCDownloadCallback),
            ],
          ),
          const SizedBox(height: 16),
          CountlySection(
            title: 'AB Testing',
            children: [
              CountlySubSection(
                title: 'Enroll on Access',
                children: [
                  MyButton(text: 'Get All RC Values And Enroll', type: CountlyButtonType.tonal, onPressed: getAllRCValuesAndEnroll),
                  MyButton(text: 'Get Specific RC Values And Enroll', type: CountlyButtonType.tonal, onPressed: getSpecificRCValuesAndEnroll),
                ],
              ),
              CountlySubSection(
                title: 'Enroll on Action',
                children: [
                  MyButton(text: 'Enroll Into Specific AB Test Keys', type: CountlyButtonType.filled, onPressed: enrollIntoABTests),
                  MyButton(text: 'Enroll Into an AB Test', type: CountlyButtonType.filled, onPressed: enrollIntoABExperiment),
                ],
              ),
              CountlySubSection(
                title: 'Exiting AB Tests',
                children: [
                  MyButton(text: 'Exit from Specific AB Test Keys', type: CountlyButtonType.outlined, onPressed: exitABTests),
                  MyButton(text: 'Exit an AB Test', type: CountlyButtonType.outlined, onPressed: exitABExperiment),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          CountlySection(
            title: 'Variant Download/Get Calls',
            children: [
              MyButton(text: 'Download All Test Variants', type: CountlyButtonType.filled, onPressed: downloadAllVariants),
              MyButton(text: 'Get All Test Variants', type: CountlyButtonType.tonal, onPressed: getAllTestVariants),
              MyButton(text: 'Get Specific Test Variants', type: CountlyButtonType.tonal, onPressed: getSpecificTestVariants),
              MyButton(text: 'Enroll Into Variant', type: CountlyButtonType.filled, onPressed: enrollIntoVariant),
            ],
          ),
          const SizedBox(height: 16),
          CountlySection(
            title: 'Experiment Information',
            children: [
              MyButton(text: 'Download Experiment Information', type: CountlyButtonType.filled, onPressed: downloadExperimentInfo),
              MyButton(text: 'Get All Experiment Information', type: CountlyButtonType.tonal, onPressed: getExperimentInfo),
            ],
          ),
          const SizedBox(height: 16),
          CountlySection(
            title: 'Legacy Remote Config Methods',
            children: [
              MyButton(
                  text: 'Remote Config (Legacy)',
                  type: CountlyButtonType.text,
                  onPressed: () {
                    navigateToPage(context, RemoteConfigPageLegacy());
                  }),
            ],
          ),
        ],
      ),
    );
  }
}
