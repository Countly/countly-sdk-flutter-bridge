/// REMOTE CONFIG / AB TESTING
//metadate enum for RC values
enum RCValueState { cached, currentUser, noValue }

class RCValue {
  Object? value; // stores the RC value
  int timestamp; // timestamp of when the value was downloaded
  RCValueState valueState; // it's state. indicating if it's the value of the current user or the previous one (cached)
  RCValue(this.value, this.timestamp, this.valueState);
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

  Future<void> downloadValues([RCDownloadCallback? callback]);

  Future<void> downloadSpecificValue(List<String> keys, [RCDownloadCallback? callback]);

  Future<void> downloadOmittingValues(List<String> omittedKeys, [RCDownloadCallback? callback]);

  /// returns the values of all keys.
  Future<Map<String, RCValue>> getAllValues();

  /// returns the value of a stored key.
  Future<RCValue> getValue(String key);

  Future<void> clearAllValues();

  Future<void> enrollIntoABTestsForKeys(List<String> keys);

  Future<void> exitABTestsForKeys(List<String> keys);

  Future<List<String>> testingGetVariantsForKey(String key);

  Future<Map<String, List<String>>> testingGetAllVariants();

  Future<void> testingDownloadVariantInformation(RCVariantCallback rcVariantCallback);

  Future<void> testingEnrollIntoVariant(String keyName, String variantName, RCVariantCallback? rcVariantCallback);
}
