import 'dart:convert';

import 'countly_flutter.dart';
import 'countly_state.dart';
import 'device_id.dart';

class DeviceIDInternal implements DeviceID {
  DeviceIDInternal(this._countlyState);
  final CountlyState _countlyState;

  @override
  Future<void> changeWithMerge(String newDeviceID) async {
    if (!_countlyState.isInitialized) {
      Countly.log('[DeviceIDInternal] changeWithMerge, "initWithConfig" must be called before "changeWithMerge"', logLevel: LogLevel.ERROR);
      return;
    }
    Countly.log('[DeviceIDInternal] Calling "changeWithMerge":[$newDeviceID]');

    if (newDeviceID.isEmpty) {
      Countly.log('[DeviceIDInternal] changeWithMerge, deviceId cannot be empty');
      return;
    }
    final args = [];
    args.add(newDeviceID);

    await _countlyState.channel.invokeMethod('changeWithMerge', <String, dynamic>{'data': json.encode(args)});
  }

  @override
  Future<void> changeWithoutMerge(String newDeviceID) async {
    if (!_countlyState.isInitialized) {
      Countly.log('[DeviceIDInternal] changeWithoutMerge, "initWithConfig" must be called before "changeWithoutMerge"', logLevel: LogLevel.ERROR);
      return;
    }
    Countly.log('[DeviceIDInternal] Calling "changeWithoutMerge":[$newDeviceID]');

    if (newDeviceID.isEmpty) {
      Countly.log('[DeviceIDInternal] changeWithoutMerge, deviceId cannot be empty', logLevel: LogLevel.ERROR);
      return;
    }
    final args = [];
    args.add(newDeviceID);

    await _countlyState.channel.invokeMethod('changeWithoutMerge', <String, dynamic>{'data': json.encode(args)});
  }

  @override
  Future<String?> getID() async {
    Countly.log('[DeviceIDInternal] Calling "getID"');
    if (!_countlyState.isInitialized) {
      Countly.log('[DeviceIDInternal] getID, "initWithConfig" must be called before "getID"', logLevel: LogLevel.ERROR);
      return null;
    }
    final String? result = await _countlyState.channel.invokeMethod('getID');

    return result;
  }

  @override
  Future<DeviceIdType?> getIDType() async {
    Countly.log('[DeviceIDInternal] Calling "getIDType"');
    if (!_countlyState.isInitialized) {
      Countly.log('[DeviceIDInternal] getIDType, "initWithConfig" must be called before "getIDType"', logLevel: LogLevel.ERROR);
      return null;
    }
    final String? result = await _countlyState.channel.invokeMethod('getIDType');
    if (result == null) {
      Countly.log('[DeviceIDInternal] getIDType, unexpected null value from native side', logLevel: LogLevel.ERROR);
      return null;
    }
    return _getDeviceIdType(result);
  }

  static DeviceIdType _getDeviceIdType(String givenDeviceIDType) {
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
    Countly.log('[DeviceIDInternal] Calling "setID"');
    if (!_countlyState.isInitialized) {
      Countly.log('[DeviceIDInternal] setID, "initWithConfig" must be called before "setID"', logLevel: LogLevel.ERROR);
      return;
    }

    if (newDeviceID.isEmpty) {
      Countly.log('[DeviceIDInternal] setID, deviceId cannot be empty', logLevel: LogLevel.ERROR);
      return;
    }

    final args = [];
    args.add(newDeviceID);
    await _countlyState.channel.invokeMethod('setID', <String, dynamic>{'data': json.encode(args)});
  }

  @override
  Future<void> enableTemporaryIDMode() async {
    Countly.log('[DeviceIDInternal] Calling "enableTemporaryIDMode"');
    if (!_countlyState.isInitialized) {
      Countly.log('[DeviceIDInternal] enableTemporaryIDMode, "initWithConfig" must be called before "enableTemporaryIDMode"', logLevel: LogLevel.ERROR);
      return;
    }

    await _countlyState.channel.invokeMethod('enableTemporaryIDMode');
  }
}
