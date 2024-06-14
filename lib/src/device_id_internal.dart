import 'dart:convert';

import 'countly_flutter.dart';
import 'countly_state.dart';
import 'device_id.dart';

class DeviceIDInternal implements DeviceID {
  DeviceIDInternal(this._countlyState);
  final CountlyState _countlyState;

  @override
  Future<void> changeDeviceIDWithMerge(String newDeviceID) async {
    if (!_countlyState.isInitialized) {
      const message = '"initWithConfig" must be called before "changeDeviceIDWithMerge"';
      Countly.log('changeDeviceIDWithMerge, $message', logLevel: LogLevel.ERROR);
      return;
    }
    Countly.log('Calling "changeDeviceIDWithMerge":[$newDeviceID]');
    if (newDeviceID.isEmpty) {
      const error = 'changeDeviceIDWithMerge, deviceId cannot be null or empty';
      Countly.log(error);
      return;
    }
    final args = [];
    const onServerString = '1';
    args.add(newDeviceID);
    args.add(onServerString);

    await _countlyState.channel.invokeMethod('changeDeviceId', <String, dynamic>{'data': json.encode(args)});

    return;
  }

  @override
  Future<void> changeDeviceIDWithoutMerge(String newDeviceID) async {
    if (!_countlyState.isInitialized) {
      const message = '"initWithConfig" must be called before "changeDeviceIDWithoutMerge"';
      Countly.log('changeDeviceIDWithoutMerge, $message', logLevel: LogLevel.ERROR);
      return;
    }
    Countly.log('Calling "changeDeviceIDWithoutMerge":[$newDeviceID]');
    if (newDeviceID.isEmpty) {
      const error = 'changeDeviceIDWithoutMerge, deviceId cannot be null or empty';
      Countly.log(error);
      return;
    }
    final args = [];
    const onServerString = '0';
    args.add(newDeviceID);
    args.add(onServerString);

    await _countlyState.channel.invokeMethod('changeDeviceId', <String, dynamic>{'data': json.encode(args)});

    return;
  }

  @override
  Future<String?> getCurrentDeviceID() async {
    Countly.log('Calling "getCurrentDeviceId"');
    if (!_countlyState.isInitialized) {
      String message = '"initWithConfig" must be called before "getCurrentDeviceId"';
      Countly.log('getCurrentDeviceId, $message', logLevel: LogLevel.ERROR);
      return null;
    }
    final String? result = await _countlyState.channel.invokeMethod('getCurrentDeviceId');

    return result;
  }

  @override
  Future<DeviceIdType?> getDeviceIDType() async {
    Countly.log('Calling "getDeviceIDType"');
    if (!_countlyState.isInitialized) {
      Countly.log('getDeviceIDType, "initWithConfig" must be called before "getDeviceIDType"', logLevel: LogLevel.ERROR);
      return null;
    }
    final String? result = await _countlyState.channel.invokeMethod('getDeviceIDType');
    if (result == null) {
      Countly.log('getDeviceIDType, unexpected null value from native side', logLevel: LogLevel.ERROR);
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
    Countly.log('Calling "setID"');
    if (!_countlyState.isInitialized) {
      String message = '"initWithConfig" must be called before "setID"';
      Countly.log('setID, $message', logLevel: LogLevel.ERROR);
      return;
    }

    final args = [];
    args.add(newDeviceID);
    await _countlyState.channel.invokeMethod('setID', <String, dynamic>{'data': json.encode(args)});

    return;
  }
}
