import 'dart:convert';

import 'package:countly_flutter/countly_flutter.dart';
import 'package:countly_flutter/countly_state.dart';
import 'package:countly_flutter/sessions.dart';

class SessionsInternal implements Sessions {
  SessionsInternal(this._cly, this._countlyState);

  final Countly _cly;
  final CountlyState _countlyState;
  bool _manualSessionEnabled = false;

  @override
  Future<void> beginSession() async {
    if (!_countlyState.isInitialized) {
      String message = '"initWithConfig" must be called before "beginSession"';
      Countly.log('beginSession, $message', logLevel: LogLevel.ERROR);
      return;
    }
    Countly.log('Calling "beginSession", manual session control enabled:[$_manualSessionEnabled]');

    if (!_manualSessionEnabled) {
      String error = '"beginSession" will be ignored since manual session control is not enabled';
      Countly.log(error);
      return;
    }
    await _countlyState.channel.invokeMethod('beginSession');
  }

  @override
  Future<void> endSession() async {
    if (!_countlyState.isInitialized) {
      String message = '"initWithConfig" must be called before "endSession"';
      Countly.log('endSession, $message', logLevel: LogLevel.ERROR);
      return;
    }
    Countly.log('Calling "endSession", manual session control enabled:[$_manualSessionEnabled]');

    if (!_manualSessionEnabled) {
      String error = '"endSession" will be ignored since manual session control is not enabled';
      Countly.log(error);
      return;
    }
    await _countlyState.channel.invokeMethod('endSession');
  }

  @override
  Future<void> updateSession() async {
    if (!_countlyState.isInitialized) {
      String message = '"initWithConfig" must be called before "updateSession"';
      Countly.log('updateSession, $message', logLevel: LogLevel.ERROR);
      return;
    }
    Countly.log('Calling "updateSession", manual session control enabled:[$_manualSessionEnabled]');

    if (!_manualSessionEnabled) {
      String error = '"updateSession" will be ignored since manual session control is not enabled';
      Countly.log(error);
      return;
    }
    await _countlyState.channel.invokeMethod('updateSession');
  }

  void enableManualSession() {
    _manualSessionEnabled = true;
  }
}