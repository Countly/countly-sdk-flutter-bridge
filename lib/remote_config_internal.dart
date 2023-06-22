import 'dart:convert';

import 'package:countly_flutter/countly_flutter.dart';
import 'package:countly_flutter/countly_state.dart';

class RemoteConfigInternal implements RemoteConfig {
  RemoteConfigInternal(this._cly, this._countlyState);

  final Countly _cly;
  final CountlyState _countlyState;
  static final Map<int, RCDownloadInnerCallback> _remoteConfigDownloadCallbacks = {};
  static final Map<int, RCVariantInnerCallback> _remoteConfigVariantInnerCallbacks = {};
  final _downloadKeysToRemove = <int>[];
  final _variantKeysToRemove = <int>[];
  final _requestIDNoCallback = -1;
  final _requestIDGlobalCallback = -2;

  void notifyDownloadCallbacks(RequestResult requestResult, String? error, bool fullValueUpdate, Map<dynamic, dynamic> downloadedValues, int id) {
    final values = _parseDownloadedValues(downloadedValues, 'notifyDownloadCallbacks');

    for (final entry in _remoteConfigDownloadCallbacks.entries) {
      entry.value(requestResult, error, fullValueUpdate, values, id);
    }
    for (final key in _downloadKeysToRemove) {
      _remoteConfigDownloadCallbacks.remove(key);
    }
    _downloadKeysToRemove.clear();
  }

  void notifyVariantCallbacks(RequestResult requestResult, String? error, int id) {
    for (final entry in _remoteConfigVariantInnerCallbacks.entries) {
      entry.value(requestResult, error, id);
    }
    for (final key in _variantKeysToRemove) {
      _remoteConfigVariantInnerCallbacks.remove(key);
    }
    _variantKeysToRemove.clear();
  }

  @override
  Future<void> clearAll() async {
    if (!_countlyState.isInitialized) {
      Countly.log('remoteConfigClearAllValues, "initWithConfig" must be called before "remoteConfigClearAllValues"', logLevel: LogLevel.ERROR);
      return;
    }
    Countly.log('Calling "remoteConfigClearAllValues"');
    await _countlyState.channel.invokeMethod('remoteConfigClearAllValues');
  }

  @override
  Future<void> downloadOmittingKeys(List<String> omittedKeys, [RCDownloadCallback? callback]) async {
    if (!_countlyState.isInitialized) {
      Countly.log('"initWithConfig" must be called before "remoteConfigDownloadOmittingValues"', logLevel: LogLevel.ERROR);
      return;
    }

    Countly.log('Calling "remoteConfigDownloadOmittingValues":[$omittedKeys]');
    if (omittedKeys.isEmpty) {
      Countly.log('remoteConfigDownloadOmittingValues, keys List is empty', logLevel: LogLevel.WARNING);
    }

    int requestID = _wrapDownloadCallback(callback);

    List<dynamic> args = [];
    args.add(requestID);
    args.add(omittedKeys);

    await _countlyState.channel.invokeMethod('remoteConfigDownloadOmittingValues', <String, dynamic>{'data': json.encode(args)});
  }

  @override
  Future<void> downloadSpecificKeys(List<String> keys, [RCDownloadCallback? callback]) async {
    if (!_countlyState.isInitialized) {
      Countly.log('"initWithConfig" must be called before "remoteConfigDownloadSpecificValue"', logLevel: LogLevel.ERROR);
      return;
    }

    Countly.log('Calling "remoteConfigDownloadSpecificValue":[$keys]');
    if (keys.isEmpty) {
      Countly.log('remoteConfigDownloadSpecificValue, keys List is empty', logLevel: LogLevel.WARNING);
    }

    int requestID = _wrapDownloadCallback(callback);

    List<dynamic> args = [];
    args.add(requestID);
    args.add(keys);

    await _countlyState.channel.invokeMethod('remoteConfigDownloadSpecificValue', <String, dynamic>{'data': json.encode(args)});
  }

  @override
  Future<void> downloadAllKeys([RCDownloadCallback? callback]) async {
    if (!_countlyState.isInitialized) {
      Countly.log('"initWithConfig" must be called before "remoteConfigDownloadValues"', logLevel: LogLevel.ERROR);
      return;
    }

    //setup the ID for remembering afterwards
    int requestID = _wrapDownloadCallback(callback);

    List<int> args = [];
    args.add(requestID);
    return await _countlyState.channel.invokeMethod('remoteConfigDownloadValues', <String, dynamic>{'data': json.encode(args)});
  }

  @override
  Future<void> enrollIntoABTestsForKeys(List<String> keys) async {
    if (!_countlyState.isInitialized) {
      Countly.log('"initWithConfig" must be called before "remoteConfigEnrollIntoABTestsForKeys"', logLevel: LogLevel.ERROR);
      return;
    }
    Countly.log('Calling "remoteConfigEnrollIntoABTestsForKeys":[$keys]');
    if (keys.isEmpty) {
      Countly.log('remoteConfigEnrollIntoABTestsForKeys, keys List is empty', logLevel: LogLevel.WARNING);
    }
    Countly.log(keys.toString());
    List<dynamic> args = [];
    args.add(keys);
    return await _countlyState.channel.invokeMethod('remoteConfigEnrollIntoABTestsForKeys', <String, dynamic>{'data': json.encode(args)});
  }

  @override
  Future<void> exitABTestsForKeys(List<String> keys) async {
    if (!_countlyState.isInitialized) {
      Countly.log('"initWithConfig" must be called before "remoteConfigExitABTestsForKeys"', logLevel: LogLevel.ERROR);
      return;
    }
    Countly.log('Calling "remoteConfigExitABTestsForKeys":[$keys]');
    if (keys.isEmpty) {
      Countly.log('remoteConfigExitABTestsForKeys, keys List is empty', logLevel: LogLevel.WARNING);
    }
    Countly.log(keys.toString());
    List<dynamic> args = [];
    args.add(keys);
    return await _countlyState.channel.invokeMethod('remoteConfigExitABTestsForKeys', <String, dynamic>{'data': json.encode(args)});
  }

  @override
  Future<Map<String, RCData>> getAllValues() async {
    if (!_countlyState.isInitialized) {
      Countly.log('"initWithConfig" must be called before "remoteConfigGetAllValues"', logLevel: LogLevel.ERROR);
      return {};
    }

    final Map<dynamic, dynamic> allValues = await _countlyState.channel.invokeMethod('remoteConfigGetAllValues');
    Countly.log('"getAllValues" returned values:$allValues', logLevel: LogLevel.DEBUG);
    Map<String, RCData> returnValue = _parseDownloadedValues(allValues, 'getAllValues');

    Countly.log('"getAllValues" transformed values:$returnValue', logLevel: LogLevel.DEBUG);
    return returnValue;
  }

  Map<String, RCData> _parseDownloadedValues(Map<dynamic, dynamic> data, String locationName) {
    Map<String, RCData> returnValue = {};
    for (final item in data.entries) {
      if ((item.key is! String?) || item.key == null || (item.key as String).isEmpty) {
        Countly.log('"$locationName" returned key is not valid:$item', logLevel: LogLevel.WARNING);
        continue;
      }

      final key = item.key as String;
      returnValue[key] = RCData.fromMap(item.value as Map<dynamic, dynamic>);
    }
    return returnValue;
  }

  @override
  Future<RCData> getValue(String key) async {
    if (!_countlyState.isInitialized) {
      Countly.log('"initWithConfig" must be called before "remoteConfigGetValue"', logLevel: LogLevel.ERROR);
      return RCData(null, true);
    }
    Countly.log('Calling "remoteConfigGetValue":[$key]');
    if (key.isEmpty) {
      Countly.log('remoteConfigGetValue, key cannot be empty');
      return RCData(null, true);
    }
    List<String> args = [];
    args.add(key);

    final valueMap = await _countlyState.channel.invokeMethod('remoteConfigGetValue', <String, dynamic>{'data': json.encode(args)});

    RCData? returnValue;
    if (valueMap != null) {
      returnValue = RCData.fromMap(valueMap as Map<dynamic, dynamic>);
    }

    returnValue ??= RCData(null, true);
    return returnValue;
  }

  @override
  void registerDownloadCallback(RCDownloadCallback callback) {
    if (!_countlyState.isInitialized) {
      Countly.log('"initWithConfig" must be called before "remoteConfigRegisterDownloadCallback"', logLevel: LogLevel.ERROR);
      return;
    }

    // ignore: prefer_function_declarations_over_variables
    RCDownloadInnerCallback innerCallback = (rResult, error, fullValueUpdate, downloadedValues, requestID) {
      if (requestID != _requestIDGlobalCallback) {
        return;
      }
      callback(rResult, error, fullValueUpdate, downloadedValues);
    };

    int requestID = callback.hashCode;
    Countly.log('"remoteConfigRegisterDownloadCallback" registering a callback with the hashCode:[$requestID]', logLevel: LogLevel.ERROR);
    _remoteConfigDownloadCallbacks[requestID] = innerCallback;
  }

  @override
  void removeDownloadCallback(RCDownloadCallback callback) {
    if (!_countlyState.isInitialized) {
      Countly.log('"initWithConfig" must be called before "remoteConfigRemoveDownloadCallback"', logLevel: LogLevel.ERROR);
      return;
    }

    int requestID = callback.hashCode;
    Countly.log('"remoteConfigRemoveDownloadCallback" removing a callback with the hashCode:[$requestID]', logLevel: LogLevel.ERROR);

    if (_remoteConfigDownloadCallbacks.containsKey(requestID)) {
      _remoteConfigDownloadCallbacks.remove(requestID);
    } else {
      Countly.log('"remoteConfigRemoveDownloadCallback" provided callback hashCode:[$requestID] is not registred', logLevel: LogLevel.ERROR);
    }
  }

  @override
  Future<void> testingDownloadVariantInformation(RCVariantCallback rcVariantCallback) async {
    if (!_countlyState.isInitialized) {
      Countly.log('"initWithConfig" must be called before "remoteConfigTestingDownloadVariantInformation"', logLevel: LogLevel.ERROR);
      return;
    }
    Countly.log('Calling "remoteConfigTestingDownloadVariantInformation"');
    int requestID = _wrapVariantCallback(rcVariantCallback);

    List<dynamic> args = [];
    args.add(requestID);

    return await _countlyState.channel.invokeMethod('remoteConfigTestingDownloadVariantInformation', <String, dynamic>{'data': json.encode(args)});
  }

  @override
  Future<void> testingEnrollIntoVariant(String keyName, String variantName, RCVariantCallback? rcVariantCallback) async {
    if (!_countlyState.isInitialized) {
      Countly.log('"initWithConfig" must be called before "remoteConfigTestingEnrollIntoVariant"', logLevel: LogLevel.ERROR);
      return;
    }
    Countly.log('Calling "remoteConfigTestingEnrollIntoVariant":[keyName: $keyName, variantName: $variantName]');
    if (keyName.isEmpty) {
      Countly.log('remoteConfigTestingEnrollIntoVariant, key is empty', logLevel: LogLevel.WARNING);
    }
    int requestID = _wrapVariantCallback(rcVariantCallback);
    Countly.log(keyName.toString());

    List<dynamic> args = [];
    args.add(requestID);
    args.add(keyName);
    args.add(variantName);

    return await _countlyState.channel.invokeMethod('remoteConfigTestingEnrollIntoVariant', <String, dynamic>{'data': json.encode(args)});
  }

  @override
  Future<Map<String, List<String>>> testingGetAllVariants() async {
    if (!_countlyState.isInitialized) {
      Countly.log('"initWithConfig" must be called before "remoteConfigTestingGetAllVariants"', logLevel: LogLevel.ERROR);
      return {};
    }

    Map<dynamic, dynamic>? returnValue = await _countlyState.channel.invokeMethod('remoteConfigTestingGetAllVariants');

    Map<String, List<String>>? variants;
    variants = returnValue?.map((key, value) => MapEntry(key, List<String>.from(value)));

    variants ??= {};

    return variants;
  }

  @override
  Future<List<String>> testingGetVariantsForKey(String key) async {
    if (!_countlyState.isInitialized) {
      Countly.log('"initWithConfig" must be called before "remoteConfigTestingGetVariantsForKey"', logLevel: LogLevel.ERROR);
      return [];
    }
    Countly.log('Calling "remoteConfigTestingGetVariantsForKey":[$key]');
    if (key.isEmpty) {
      Countly.log('remoteConfigTestingGetVariantsForKey, keys List is empty', logLevel: LogLevel.WARNING);
    }
    Countly.log(key.toString());

    List<String> args = [];
    args.add(key);

    List<dynamic>? returnValue = await _countlyState.channel.invokeMethod('remoteConfigTestingGetVariantsForKey', <String, dynamic>{'data': json.encode(args)});

    returnValue ??= [];

    List<String> variant = List<String>.from(returnValue);

    return variant;
  }

  int _wrapDownloadCallback([RCDownloadCallback? callback]) {
    int requestID = _requestIDNoCallback;
    if (callback != null) {
      requestID = callback.hashCode;

      // ignore: prefer_function_declarations_over_variables
      RCDownloadInnerCallback innerCallback = (rResult, error, fullValueUpdate, downloadedValues, providedRequestID) {
        if (requestID != providedRequestID) {
          return;
        }

        // remove callback from the inner list if it matches the request.
        _downloadKeysToRemove.add(requestID);
        callback(rResult, error, fullValueUpdate, downloadedValues);
      };

      // add new callback to the list
      _remoteConfigDownloadCallbacks[requestID] = innerCallback;
    }

    return requestID;
  }

  int _wrapVariantCallback([RCVariantCallback? callback]) {
    int requestID = _requestIDNoCallback;
    if (callback != null) {
      requestID = callback.hashCode;

      // ignore: prefer_function_declarations_over_variables
      RCVariantInnerCallback innerCallback = (rResult, error, providedRequestID) {
        if (requestID != providedRequestID) {
          return;
        }

        // remove callback from the inner list if it matches the request.
        _variantKeysToRemove.add(requestID);
        callback(rResult, error);
      };

      // add new callback to the list
      _remoteConfigVariantInnerCallbacks[requestID] = innerCallback;
    }

    return requestID;
  }
}
