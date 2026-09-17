import 'dart:convert';

import 'consent.dart';
import 'countly_flutter.dart';
import 'countly_state.dart';

class ConsentInternal implements Consent {
  ConsentInternal(this._countlyState);

  final CountlyState _countlyState;

  @override
  Future<String?> giveConsent(List<String> consents) => _changeConsent('giveConsent', consents);

  @override
  Future<String?> removeConsent(List<String> consents) => _changeConsent('removeConsent', consents);

  @override
  Future<String?> giveAllConsent() => _changeAllConsent('giveAllConsent');

  @override
  Future<String?> removeAllConsent() => _changeAllConsent('removeAllConsent');

  /// Sends a consent change for this instance and hands back what the native side reported, or the
  /// reason the call was not made.
  /// [String method]: the method channel name of the consent call
  /// [List<String> consents]: the features to change
  Future<String?> _changeConsent(String method, List<String> consents) async {
    final String? notReady = _countlyState.requireInit('ConsentInternal', method);
    if (notReady != null) {
      return notReady;
    }
    if (consents.isEmpty) {
      Countly.log('[ConsentInternal] $method, consents List is empty', logLevel: LogLevel.WARNING);
    }
    Countly.log('[ConsentInternal] $method, consents:[$consents]');
    return _countlyState.channel.invokeMethod(method, _countlyState.arguments(json.encode(consents)));
  }

  /// Sends an all-feature consent change for this instance and hands back what the native side
  /// reported, or the reason the call was not made.
  /// [String method]: the method channel name of the consent call
  Future<String?> _changeAllConsent(String method) async {
    final String? notReady = _countlyState.requireInit('ConsentInternal', method);
    if (notReady != null) {
      return notReady;
    }
    Countly.log('[ConsentInternal] $method');
    return _countlyState.channel.invokeMethod(method, _countlyState.arguments());
  }
}
