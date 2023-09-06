import 'dart:convert';

import 'package:countly_flutter_np/countly_flutter.dart';
import 'package:countly_flutter_np/countly_state.dart';
import 'package:countly_flutter_np/sessions.dart';

class SessionsInternal implements Sessions {
  SessionsInternal(this._cly, this._countlyState);

  final Countly _cly;
  final CountlyState _countlyState;
  bool _manualSessionEnabled = false;

  @override
  Future<void> beginSession() async {
    if (!_countlyState.isInitialized) {
      Countly.log('"initWithConfig" must be called before "beginSession"', logLevel: LogLevel.ERROR);
      return;
    }
    Countly.log('Calling "beginSession", manual session control enabled:[$_manualSessionEnabled]');

    if (!_manualSessionEnabled) {
      Countly.log('"beginSession" will be ignored since manual session control is not enabled');
      return;
    }
    await _countlyState.channel.invokeMethod('beginSession');
  }

  @override
  Future<void> endSession() async {
    if (!_countlyState.isInitialized) {
      Countly.log('"initWithConfig" must be called before "endSession"', logLevel: LogLevel.ERROR);
      return;
    }
    Countly.log('Calling "endSession", manual session control enabled:[$_manualSessionEnabled]');

    if (!_manualSessionEnabled) {
      Countly.log('"endSession" will be ignored since manual session control is not enabled');
      return;
    }
    await _countlyState.channel.invokeMethod('endSession');
  }

  @override
  Future<void> updateSession() async {
    if (!_countlyState.isInitialized) {
      Countly.log('"initWithConfig" must be called before "updateSession"', logLevel: LogLevel.ERROR);
      return;
    }
    Countly.log('Calling "updateSession", manual session control enabled:[$_manualSessionEnabled]');

    if (!_manualSessionEnabled) {
      Countly.log('"updateSession" will be ignored since manual session control is not enabled');
      return;
    }
    await _countlyState.channel.invokeMethod('updateSession');
  }

  void enableManualSession() {
    _manualSessionEnabled = true;
  }
}