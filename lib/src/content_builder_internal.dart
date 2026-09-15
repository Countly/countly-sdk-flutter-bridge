import 'content_builder.dart';
import 'countly_flutter.dart';
import 'countly_state.dart';

class ContentBuilderInternal implements ContentBuilder {
  ContentBuilderInternal(this._countlyState);

  final CountlyState _countlyState;
  ContentCallback? _contentCallback;

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

  @override
  Future<void> refreshContentZone() async {
    if (!_countlyState.isInitialized) {
      Countly.log('refreshContentZone, "initWithConfig" must be called before "clear"', logLevel: LogLevel.ERROR);
      return;
    }
    Countly.log('Calling "refreshContentZone"');
    await _countlyState.channel.invokeMethod('refreshContentZone');
  }

  @override
  Future<void> previewContent(String contentId) async {
    if (!_countlyState.isInitialized) {
      Countly.log('previewContent, "initWithConfig" must be called before "previewContent"', logLevel: LogLevel.ERROR);
      return;
    }
    if (contentId.isEmpty) {
      Countly.log('previewContent, contentId cannot be null or empty', logLevel: LogLevel.ERROR);
      return;
    }
    Countly.log('Calling "previewContent" with contentId: [$contentId]');
    await _countlyState.channel.invokeMethod('previewContent', {'contentId': contentId});
  }

  void registerContentCallback(ContentCallback callback) {
    _contentCallback = callback;
  }

  void onContentCallback(ContentStatus contentStatus, Map<String, dynamic> contentData) {
    if (_contentCallback != null) {
      _contentCallback!(contentStatus, contentData);
    }
  }
}
