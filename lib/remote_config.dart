import 'package:countly_flutter/experiment_information.dart';

/// REMOTE CONFIG / AB TESTING
class RCData {
  Object? value; // stores the RC value
  bool isCurrentUsersData;
  RCData(this.value, this.isCurrentUsersData);

  factory RCData.fromMap(Map<dynamic, dynamic> json) {
    return RCData(json['value'] as dynamic, json['isCurrentUsersData'] as bool);
  }
}

//indicates the result of the download action
enum RequestResult { error, success, networkIssue }

//used for internal Flutter-Native communication
typedef RCDownloadInnerCallback = void Function(RequestResult rResult, String? error, bool fullValueUpdate, Map<String, RCData> downloadedValues, int requestID);

//exposed to the end user
typedef RCDownloadCallback = void Function(RequestResult rResult, String? error, bool fullValueUpdate, Map<String, RCData> downloadedValues);

//used for internal Flutter-Native communication
typedef RCVariantInnerCallback = void Function(RequestResult rResult, String? error, int requestID);

//exposed to the end user
typedef RCVariantCallback = void Function(RequestResult rResult, String? error);

abstract class RemoteConfig {
  void registerDownloadCallback(RCDownloadCallback callback);

  void removeDownloadCallback(RCDownloadCallback callback);

  Future<void> downloadAllKeys([RCDownloadCallback? callback]);

  Future<void> downloadSpecificKeys(List<String> keys, [RCDownloadCallback? callback]);

  Future<void> downloadOmittingKeys(List<String> omittedKeys, [RCDownloadCallback? callback]);

  /// returns the value of a stored key.
  Future<RCData> getValue(String key);

  /// returns the values of all keys.
  Future<Map<String, RCData>> getAllValues();

  /// returns the value of a stored key and enroll it for AB testing.
  Future<RCData> getValueAndEnroll(String key);

  /// returns the values of all keys and enroll them for AB testing.
  Future<Map<String, RCData>> getAllValuesAndEnroll();

  Future<void> clearAll();

  Future<void> testingEnrollIntoABExperiment(String experimentID);

  Future<void> testingExitABExperiment(String experimentID);

  Future<void> enrollIntoABTestsForKeys(List<String> keys);

  Future<void> exitABTestsForKeys(List<String> keys);

  Future<List<String>> testingGetVariantsForKey(String key);

  Future<Map<String, List<String>>> testingGetAllVariants();

  Future<void> testingDownloadVariantInformation(RCVariantCallback rcVariantCallback);

  Future<void> testingEnrollIntoVariant(String keyName, String variantName, RCVariantCallback? rcVariantCallback);

  Future<void> testingDownloadExperimentInformation(RCVariantCallback rcVariantCallback);

  Future<Map<String, ExperimentInformation>> testingGetAllExperimentInfo();
}
