import 'countly_flutter.dart';
import 'countly_state.dart';
import 'sessions.dart';

class SessionsInternal implements Sessions {
  SessionsInternal(this._countlyState);

  final CountlyState _countlyState;
  bool _manualSessionEnabled = false;

  @override
  Future<String?> beginSession() => _sendSessionCall('beginSession');

  @override
  Future<String?> endSession() => _sendSessionCall('endSession');

  @override
  Future<String?> updateSession() => _sendSessionCall('updateSession');

  void enableManualSession() {
    _manualSessionEnabled = true;
  }

  /// Sends a manual session call and hands back what the native side reported, or the reason the call
  /// was not made. Also serves the deprecated static session calls on [Countly].
  Future<String?> _sendSessionCall(String method) async {
    final String? notReady = _countlyState.requireInit('SessionsInternal', method);
    if (notReady != null) {
      return notReady;
    }
    Countly.log('[SessionsInternal] $method, manual session control enabled:[$_manualSessionEnabled]');
    if (!_manualSessionEnabled) {
      final String error = '"$method" will be ignored since manual session control is not enabled';
      Countly.log('[SessionsInternal] $error');
      return error;
    }
    return _countlyState.channel.invokeMethod(method, _countlyState.arguments());
  }
}
