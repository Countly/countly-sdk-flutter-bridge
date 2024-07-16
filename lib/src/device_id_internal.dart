import 'dart:convert';

import 'countly_flutter.dart';
import 'countly_state.dart';
import 'device_id.dart';

class DeviceIDInternal implements DeviceID {
  DeviceIDInternal(this._countlyState);
  final CountlyState _countlyState;

  @override
  Future<void> changeWithMerge(String newDeviceID) async {
    Countly.log('[DeviceIDModule] Calling "changeWithMerge":[$newDeviceID]', logLevel: LogLevel.INFO);

    if (!_countlyState.isInitialized) {
      Countly.log('[DeviceIDModule] changeWithMerge, "initWithConfig" must be called before "changeWithMerge"', logLevel: LogLevel.WARNING);
      return;
    }

    if (newDeviceID.isEmpty) {
      Countly.log('[DeviceIDModule] changeWithMerge, provided device ID cannot be empty', logLevel: LogLevel.WARNING);
      return;
    }
    final args = [];
    args.add(newDeviceID);

    await _countlyState.channel.invokeMethod('changeWithMerge', <String, dynamic>{'data': json.encode(args)});
  }

  @override
  Future<void> changeWithoutMerge(String newDeviceID) async {
    Countly.log('[DeviceIDModule] Calling "changeWithoutMerge":[$newDeviceID]', logLevel: LogLevel.INFO);

    if (!_countlyState.isInitialized) {
      Countly.log('[DeviceIDModule] changeWithoutMerge, "initWithConfig" must be called before "changeWithoutMerge"', logLevel: LogLevel.WARNING);
      return;
    }

    if (newDeviceID.isEmpty) {
      Countly.log('[DeviceIDModule] changeWithoutMerge, provided device ID cannot be empty', logLevel: LogLevel.WARNING);
      return;
    }
    final args = [];
    args.add(newDeviceID);

    await _countlyState.channel.invokeMethod('changeWithoutMerge', <String, dynamic>{'data': json.encode(args)});
  }

  @override
  Future<String?> getID() async {
    Countly.log('[DeviceIDModule] Calling "getID"', logLevel: LogLevel.INFO);

    if (!_countlyState.isInitialized) {
      Countly.log('[DeviceIDModule] getID, "initWithConfig" must be called before "getID"', logLevel: LogLevel.WARNING);
      return null;
    }
    final String? result = await _countlyState.channel.invokeMethod('getID');

    return result;
  }

  @override
  Future<DeviceIdType?> getIDType() async {
    Countly.log('[DeviceIDModule] Calling "getIDType"', logLevel: LogLevel.INFO);

    if (!_countlyState.isInitialized) {
      Countly.log('[DeviceIDModule] getIDType, "initWithConfig" must be called before "getIDType"', logLevel: LogLevel.WARNING);
      return null;
    }
    final String result = await _countlyState.channel.invokeMethod('getIDType');
    return _getDeviceIdType(result);
  }

  static DeviceIdType _getDeviceIdType(String givenDeviceIDType) {
    Countly.log('[DeviceIDModule] Calling "getDeviceIdType":[$givenDeviceIDType]', logLevel: LogLevel.INFO);

    DeviceIdType deviceIdType = DeviceIdType.SDK_GENERATED;
    switch (givenDeviceIDType) {
      case 'DS':
        deviceIdType = DeviceIdType.DEVELOPER_SUPPLIED;
        break;
      case 'TID':
        deviceIdType = DeviceIdType.TEMPORARY_ID;
        break;
    }
    return deviceIdType;
  }

  @override
  Future<void> setID(String newDeviceID) async {
    Countly.log('[DeviceIDModule] Calling "setID":[$newDeviceID]', logLevel: LogLevel.INFO);

    if (!_countlyState.isInitialized) {
      Countly.log('[DeviceIDModule] setID, "initWithConfig" must be called before "setID"', logLevel: LogLevel.WARNING);
      return;
    }

    if (newDeviceID.isEmpty) {
      Countly.log('[DeviceIDModule] setID, provided device ID cannot be empty', logLevel: LogLevel.WARNING);
      return;
    }

    final args = [];
    args.add(newDeviceID);
    await _countlyState.channel.invokeMethod('setID', <String, dynamic>{'data': json.encode(args)});
  }

  @override
  Future<void> enableTemporaryIDMode() async {
    Countly.log('[DeviceIDModule] Calling "enableTemporaryIDMode"', logLevel: LogLevel.INFO);

    if (!_countlyState.isInitialized) {
      Countly.log('[DeviceIDModule] enableTemporaryIDMode, "initWithConfig" must be called before "enableTemporaryIDMode" or you can use the config method "enableTemporaryDeviceIDMode" to enter temporary device ID mode during init.', logLevel: LogLevel.WARNING);
      return;
    }

    await _countlyState.channel.invokeMethod('enableTemporaryIDMode');
  }
}
