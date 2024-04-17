import 'experiment_information.dart';

/// REMOTE CONFIG / AB TESTING
class RCData {
  /// stores the RC value
  Object? value;
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
  /// Register a callback to be called after remote config values are downloaded.
  /// [RCDownloadCallback callback] - callback
  void registerDownloadCallback(RCDownloadCallback callback);

  /// Remove a registered callback. This callback will not be called after remote config values are downloaded.
  /// [RCDownloadCallback callback] - callback
  void removeDownloadCallback(RCDownloadCallback callback);

  /// Trigger downloading of all remote config keys.
  /// [RCDownloadCallback callback] - will be called after all keys are downloaded
  Future<void> downloadAllKeys([RCDownloadCallback? callback]);

  /// Trigger downloading of specific remote config keys.
  /// [List<String> key] - list of keys to be downloaded
  /// [RCDownloadCallback callback] - will be called after all keys are downloaded
  Future<void> downloadSpecificKeys(List<String> keys, [RCDownloadCallback? callback]);

  /// Trigger downloading of all remote config keys except omitted keys.
  /// [List<String> key] - list of keys to be omitted
  /// [RCDownloadCallback callback] - will be called after all keys are downloaded
  Future<void> downloadOmittingKeys(List<String> omittedKeys, [RCDownloadCallback? callback]);

  /// returns the value of a stored key.
  /// make sure [downloadAllKeys] or [downloadSpecificKeys] is called to download RC data before calling this method.
  Future<RCData> getValue(String key);

  /// returns the values of all keys.
  /// make sure [downloadAllKeys] is called to download all RC data before calling this method.
  Future<Map<String, RCData>> getAllValues();

  /// returns the value of a stored key and enroll it for AB testing.
  /// make sure [downloadAllKeys] or [downloadSpecificKeys] is called to download RC data before calling this method.
  Future<RCData> getValueAndEnroll(String key);

  /// returns the values of all keys and enroll them for AB testing.
  /// make sure [downloadAllKeys] or [downloadSpecificKeys] is called to download all RC data before calling this method.
  Future<Map<String, RCData>> getAllValuesAndEnroll();

  /// Clear all downloaded values
  Future<void> clearAll();

  /// Enroll into AB experiment (for all keys under that experiment) with experiment ID
  /// [String experimentID] - ID of experiment
  /// You can get experiment ID from [testingDownloadExperimentInformation]
  Future<void> testingEnrollIntoABExperiment(String experimentID);

  /// Exit from AB experiment (for all keys under that experiment) with experiment ID
  /// [String experimentID] - ID of experiment
  /// You can get experiment ID from [testingDownloadExperimentInformation]
  Future<void> testingExitABExperiment(String experimentID);

  /// Enroll into AB tests for the given keys
  /// [List<String> keys] - List of keys
  Future<void> enrollIntoABTestsForKeys(List<String> keys);

  /// Exit AB tests for the given keys
  /// [List<String> keys] - List of keys
  Future<void> exitABTestsForKeys(List<String> keys);

  /// returns variants for a specific key
  /// make sure [testingDownloadVariantInformation] is called to download variant info before calling this method.
  /// [String key] - name of key
  Future<List<String>> testingGetVariantsForKey(String key);

  /// returns all variants
  /// make sure [testingDownloadVariantInformation] is called to download variant info before calling this method.
  Future<Map<String, List<String>>> testingGetAllVariants();

  /// fetch a map of all A/B testing parameters (keys) and variants associated with it
  /// [RCVariantCallback rcVariantCallback] - called after all information is downloaded
  Future<void> testingDownloadVariantInformation(RCVariantCallback rcVariantCallback);

  /// Enroll user into a specific variant
  /// make sure [testingDownloadVariantInformation] is called to download variant info before calling this method.
  /// [String keyName] - name of key
  /// [String variantName] - name of variant
  /// [RCVariantCallback rcVariantCallback] - called after enrollment
  Future<void> testingEnrollIntoVariant(String keyName, String variantName, RCVariantCallback? rcVariantCallback);

  /// Fetch information about the A/B tests in your server including test name, description and the current variant
  /// [RCVariantCallback rcVariantCallback] - called after all information is downloaded
  Future<void> testingDownloadExperimentInformation(RCVariantCallback rcVariantCallback);

  /// make sure [testingDownloadExperimentInformation] is called to download experiment info before calling this method.
  Future<Map<String, ExperimentInformation>> testingGetAllExperimentInfo();
}
