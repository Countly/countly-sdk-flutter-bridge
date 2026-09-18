import 'dart:convert';

import 'countly_flutter.dart';
import 'countly_state.dart';
import 'location.dart';

class LocationInternal implements Location {
  LocationInternal(this._countlyState);

  final CountlyState _countlyState;

  @override
  Future<String?> setLocation({String? countryCode, String? city, String? gpsCoordinates, String? ipAddress}) async {
    final String? notReady = _countlyState.requireInit('LocationInternal', 'setUserLocation');
    if (notReady != null) {
      return notReady;
    }
    Countly.log('[LocationInternal] setLocation, countryCode:[$countryCode] city:[$city] gpsCoordinates:[$gpsCoordinates] ipAddress:[$ipAddress]');
    // Fields that are not given are left out, a JSON null would reach Android as the string "null".
    final Map<String, String> location = {'countryCode': countryCode, 'city': city, 'gpsCoordinates': gpsCoordinates, 'ipAddress': ipAddress}.map((key, value) => MapEntry(key, value ?? '')).cast<String, String>()..removeWhere((key, value) => value.isEmpty);
    return _countlyState.channel.invokeMethod('setUserLocation', _countlyState.arguments(json.encode([location])));
  }

  @override
  Future<String?> disableLocation() async {
    final String? notReady = _countlyState.requireInit('LocationInternal', 'disableLocation');
    if (notReady != null) {
      return notReady;
    }
    Countly.log('[LocationInternal] disableLocation');
    return _countlyState.channel.invokeMethod('disableLocation', _countlyState.arguments());
  }
}
