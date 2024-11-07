import 'content_builder.dart';
import 'countly_flutter.dart';
import 'countly_state.dart';

class ContentBuilderInternal implements ContentBuilder {
  ContentBuilderInternal(this._countlyState);

  final CountlyState _countlyState;

  @override
  Future<void> enterContentZone() async {
    if (!_countlyState.isInitialized) {
      Countly.log('enterContentZone, "initWithConfig" must be called before "clear"', logLevel: LogLevel.ERROR);
      return;
    }
    Countly.log('Calling "enterContentZone"');
    await _countlyState.channel.invokeMethod('enterContentZone');
  }

  @override
  Future<void> exitContentZone() async {
    if (!_countlyState.isInitialized) {
      Countly.log('exitContentZone, "initWithConfig" must be called before "clear"', logLevel: LogLevel.ERROR);
      return;
    }
    Countly.log('Calling "exitContentZone"');
    await _countlyState.channel.invokeMethod('exitContentZone');
  }
}