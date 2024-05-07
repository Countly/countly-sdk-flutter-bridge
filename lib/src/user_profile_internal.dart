import 'dart:convert';

import 'countly_flutter.dart';
import 'countly_state.dart';
import 'user_profile.dart';

class UserProfileInternal implements UserProfile {
  UserProfileInternal(this._countlyState);

  final CountlyState _countlyState;

  @override
  Future<void> clear() async {
    if (!_countlyState.isInitialized) {
      Countly.log('clear, "initWithConfig" must be called before "clear"', logLevel: LogLevel.ERROR);
      return;
    }
    Countly.log('Calling "clear"');
    await _countlyState.channel.invokeMethod('userProfile_clear');
  }

  @override
  Future<void> increment(String key) async {
    if (!_countlyState.isInitialized) {
      Countly.log('increment, "initWithConfig" must be called before "increment"', logLevel: LogLevel.ERROR);
      return;
    }
    Countly.log('Calling "increment":[$key]');
    if (key.isEmpty) {
      Countly.log('increment, key cannot be empty');
      return;
    }
    List<String> args = [];
    args.add(key);
    await _countlyState.channel.invokeMethod('userProfile_increment', <String, dynamic>{'data': json.encode(args)});
  }

  @override
  Future<void> incrementBy(String key, int value) async {
    if (!_countlyState.isInitialized) {
      Countly.log('incrementBy, "initWithConfig" must be called before "incrementBy"', logLevel: LogLevel.ERROR);
      return;
    }
    Countly.log('Calling "incrementBy":[$key]');
    if (key.isEmpty) {
      Countly.log('incrementBy, key cannot be empty');
      return;
    }
    List<Object> args = [];
    args.add(key);
    args.add(value);
    await _countlyState.channel.invokeMethod('userProfile_incrementBy', <String, dynamic>{'data': json.encode(args)});
  }

  @override
  Future<void> multiply(String key, int value) async {
    if (!_countlyState.isInitialized) {
      Countly.log('multiply, "initWithConfig" must be called before "multiply"', logLevel: LogLevel.ERROR);
      return;
    }
    Countly.log('Calling "multiply":[$key]');
    if (key.isEmpty) {
      Countly.log('multiply, key cannot be empty');
      return;
    }
    List<Object> args = [];
    args.add(key);
    args.add(value);
    await _countlyState.channel.invokeMethod('userProfile_multiply', <String, dynamic>{'data': json.encode(args)});
  }

  @override
  Future<void> pull(String key, String value) async {
    if (!_countlyState.isInitialized) {
      Countly.log('pull, "initWithConfig" must be called before "pull"', logLevel: LogLevel.ERROR);
      return;
    }
    Countly.log('Calling "pull":[$key]');
    if (key.isEmpty) {
      Countly.log('pull, key cannot be empty');
      return;
    }
    List<String> args = [];
    args.add(key);
    args.add(value);
    await _countlyState.channel.invokeMethod('userProfile_pull', <String, dynamic>{'data': json.encode(args)});
  }

  @override
  Future<void> push(String key, String value) async {
    if (!_countlyState.isInitialized) {
      Countly.log('push, "initWithConfig" must be called before "push"', logLevel: LogLevel.ERROR);
      return;
    }
    Countly.log('Calling "push":[$key]');
    if (key.isEmpty) {
      Countly.log('push, key cannot be empty');
      return;
    }
    List<String> args = [];
    args.add(key);
    args.add(value);
    await _countlyState.channel.invokeMethod('userProfile_push', <String, dynamic>{'data': json.encode(args)});
  }

  @override
  Future<void> pushUnique(String key, String value) async {
    if (!_countlyState.isInitialized) {
      Countly.log('pushUnique, "initWithConfig" must be called before "pushUnique"', logLevel: LogLevel.ERROR);
      return;
    }
    Countly.log('Calling "pushUnique":[$key]');
    if (key.isEmpty) {
      Countly.log('pushUnique, key cannot be empty');
      return;
    }
    List<String> args = [];
    args.add(key);
    args.add(value);
    await _countlyState.channel.invokeMethod('userProfile_pushUnique', <String, dynamic>{'data': json.encode(args)});
  }

  @override
  Future<void> save() async {
    if (!_countlyState.isInitialized) {
      Countly.log('save, "initWithConfig" must be called before "save"', logLevel: LogLevel.ERROR);
      return;
    }
    Countly.log('Calling "save"');
    await _countlyState.channel.invokeMethod('userProfile_save');
  }

  @override
  Future<void> saveMax(String key, int value) async {
    if (!_countlyState.isInitialized) {
      Countly.log('saveMax, "initWithConfig" must be called before "saveMax"', logLevel: LogLevel.ERROR);
      return;
    }
    Countly.log('Calling "saveMax":[$key]');
    if (key.isEmpty) {
      Countly.log('saveMax, key cannot be empty');
      return;
    }
    List<Object> args = [];
    args.add(key);
    args.add(value);
    await _countlyState.channel.invokeMethod('userProfile_saveMax', <String, dynamic>{'data': json.encode(args)});
  }

  @override
  Future<void> saveMin(String key, int value) async {
    if (!_countlyState.isInitialized) {
      Countly.log('saveMin, "initWithConfig" must be called before "saveMin"', logLevel: LogLevel.ERROR);
      return;
    }
    Countly.log('Calling "saveMin":[$key]');
    if (key.isEmpty) {
      Countly.log('saveMin, key cannot be empty');
      return;
    }
    List<Object> args = [];
    args.add(key);
    args.add(value);
    await _countlyState.channel.invokeMethod('userProfile_saveMin', <String, dynamic>{'data': json.encode(args)});
  }

  @override
  Future<void> setOnce(String key, String value) async {
    if (!_countlyState.isInitialized) {
      Countly.log('setOnce, "initWithConfig" must be called before "setOnce"', logLevel: LogLevel.ERROR);
      return;
    }
    Countly.log('Calling "setOnce":[$key]');
    if (key.isEmpty) {
      Countly.log('setOnce, key cannot be empty');
      return;
    }
    List<String> args = [];
    args.add(key);
    args.add(value);
    await _countlyState.channel.invokeMethod('userProfile_setOnce', <String, dynamic>{'data': json.encode(args)});
  }

  @override
  Future<void> setProperty(String key, Object value) async {
    if (!_countlyState.isInitialized) {
      Countly.log('setProperty, "initWithConfig" must be called before "setProperty"', logLevel: LogLevel.ERROR);
      return;
    }
    Countly.log('Calling "setProperty":[$key]');
    if (key.isEmpty) {
      Countly.log('setProperty, key cannot be empty');
      return;
    }
    List<Object> args = [];
    args.add(key);
    args.add(value);
    await _countlyState.channel.invokeMethod('userProfile_setProperty', <String, dynamic>{'data': json.encode(args)});
  }

  @override
  Future<void> setUserProperties(Map<String, Object> userProperties) async {
    if (!_countlyState.isInitialized) {
      Countly.log('setUserProperties, "initWithConfig" must be called before "setUserProperties"', logLevel: LogLevel.ERROR);
      return;
    }
    Countly.log('Calling "setUserProperties":[$userProperties]');
    if (userProperties.isEmpty) {
      Countly.log('setUserProperties, properties cannot be empty');
      return;
    }
    _predefinedPropertiesToString(userProperties);
    List<Object> args = [];
    args.add(userProperties);
    await _countlyState.channel.invokeMethod('userProfile_setProperties', <String, dynamic>{'data': json.encode(args)});
  }

  void _predefinedPropertiesToString(Map<String, Object> userProperties) {
    if (userProperties.containsKey('name')) {
      userProperties['name'] = userProperties['name'].toString();
    }
    if (userProperties.containsKey('username')) {
      userProperties['username'] = userProperties['username'].toString();
    }
    if (userProperties.containsKey('email')) {
      userProperties['email'] = userProperties['email'].toString();
    }
    if (userProperties.containsKey('organization')) {
      userProperties['organization'] = userProperties['organization'].toString();
    }
    if (userProperties.containsKey('phone')) {
      userProperties['phone'] = userProperties['phone'].toString();
    }
    if (userProperties.containsKey('picture')) {
      userProperties['picture'] = userProperties['picture'].toString();
    }
    if (userProperties.containsKey('picturePath')) {
      userProperties['picturePath'] = userProperties['picturePath'].toString();
    }
    if (userProperties.containsKey('gender')) {
      userProperties['gender'] = userProperties['gender'].toString();
    }
    if (userProperties.containsKey('byear')) {
      userProperties['byear'] = userProperties['byear']!;
    }
  }
}
