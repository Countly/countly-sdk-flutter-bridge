/// REMOTE CONFIG / AB TESTING
class RCData {
  Object? value; // stores the RC value
  bool isCurrentUsersData;
  RCData(this.value, this.isCurrentUsersData);
}

//indicates the result of the download action
enum RequestResult { error, success, networkIssue }

//used for internal Flutter-Native communication
typedef RCInnerCallback = void Function(RequestResult rResult, String? error, bool fullValueUpdate, Map<String, Object> downloadedValues, int requestID);

//exposed to the end user
typedef RCDownloadCallback = void Function(RequestResult rResult, String? error, bool fullValueUpdate, Map<String, Object> downloadedValues);

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

  /// returns the values of all keys.
  Future<Map<String, RCData>> getAllValues();

  /// returns the value of a stored key.
  Future<RCData> getValue(String key);

  Future<void> clearAll();

  Future<void> enrollIntoABTestsForKeys(List<String> keys);

  Future<void> exitABTestsForKeys(List<String> keys);

  Future<List<String>> testingGetVariantsForKey(String key);

  Future<Map<String, List<String>>> testingGetAllVariants();

  Future<void> testingDownloadVariantInformation(RCVariantCallback rcVariantCallback);

  Future<void> testingEnrollIntoVariant(String keyName, String variantName, RCVariantCallback? rcVariantCallback);
}
