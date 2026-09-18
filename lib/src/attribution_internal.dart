import 'dart:convert';

import 'attribution.dart';
import 'countly_flutter.dart';
import 'countly_state.dart';

class AttributionInternal implements Attribution {
  AttributionInternal(this._countlyState);

  final CountlyState _countlyState;

  @override
  Future<String?> recordDirectAttribution(String campaignType, String campaignData) async {
    final String? notReady = _countlyState.requireInit('AttributionInternal', 'recordDirectAttribution');
    if (notReady != null) {
      return notReady;
    }
    if (campaignType.isEmpty) {
      const String error = 'recordDirectAttribution, campaignType cannot be empty';
      Countly.log('[AttributionInternal] $error', logLevel: LogLevel.WARNING);
      return 'Error : $error';
    }
    Countly.log('[AttributionInternal] recordDirectAttribution, campaignType:[$campaignType] campaignData:[$campaignData]');
    return _countlyState.channel.invokeMethod('recordDirectAttribution', _countlyState.arguments(json.encode([campaignType, campaignData])));
  }

  @override
  Future<String?> recordIndirectAttribution(Map<String, String> attributionValues) async {
    final String? notReady = _countlyState.requireInit('AttributionInternal', 'recordIndirectAttribution');
    if (notReady != null) {
      return notReady;
    }
    // Pairs with an empty key are dropped, the native side answers an empty map itself.
    final Map<String, String> values = Map<String, String>.from(attributionValues)..removeWhere((key, value) => key.isEmpty);
    if (values.length != attributionValues.length) {
      Countly.log('[AttributionInternal] recordIndirectAttribution, ignoring the pairs with an empty key', logLevel: LogLevel.WARNING);
    }
    Countly.log('[AttributionInternal] recordIndirectAttribution, values:[$values]');
    return _countlyState.channel.invokeMethod('recordIndirectAttribution', _countlyState.arguments(json.encode([values])));
  }
}
