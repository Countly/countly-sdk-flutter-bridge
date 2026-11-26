import 'dart:convert';

import 'package:countly_flutter_lite/countly_flutter_lite.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class TestLogger implements SdkLogger {
  final List<String> logs = [];
  @override
  bool isEnabled(LogLevel level) => true;
  @override
  void log(LogLevel level, String message, {Object? error, StackTrace? stack}) {
    logs.add('[${level.name}] $message');
  }

  /// Number of logs at [level] that contain [text].
  int count(LogLevel level, String text) =>
      logs.where((l) => l.startsWith('[${level.name}]') && l.contains(text)).length;
}

/// Stands in for the Countly servers and records every request they receive.
class FakeServers extends http.BaseClient {
  final List<http.Request> requests = [];

  static const _common = {'app_key', 'device_id', 'sdk_version', 'sdk_name', 'av', 'timestamp', 'hour', 'dow', 'tz', 'rr'};

  /// Decoded body of each request.
  List<Map<String, dynamic>> get params => requests.map((r) => jsonDecode(r.body) as Map<String, dynamic>).toList();

  /// Host, path, app key and what each request carries, for example "server-a.com/i app-key-a events[e1]".
  List<String> describe() => requests.map((request) {
        final params = jsonDecode(request.body) as Map<String, dynamic>;
        final parts = ['${request.url.host}${request.url.path}', '${params['app_key']}'];
        for (final key in params.keys.where((k) => !_common.contains(k)).toList()..sort()) {
          if (key == 'method') {
            parts.add('method=${params[key]}');
          } else if (key == 'events') {
            final events = jsonDecode(params[key] as String) as List<dynamic>;
            final names = events.map((e) => e['key'] == '[CLY]_view' ? 'view:${e['segmentation']['name']}' : e['key']);
            parts.add('events[${names.join(',')}]');
          } else {
            parts.add(key);
          }
        }
        return parts.join(' ');
      }).toList();

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final captured = request as http.Request;
    requests.add(captured);
    final body = (jsonDecode(captured.body) as Map<String, dynamic>)['method'] == 'sc' ? '{"c":{}}' : '{"result":"Success"}';
    return http.StreamedResponse(Stream.value(utf8.encode(body)), 200, headers: {'content-type': 'application/json'});
  }
}

/// Inits lite with server A and app key A, sending every request to [servers].
Future<CountlyInstance> _init(FakeServers servers, {TestLogger? logger, StorageMode storageMode = StorageMode.memory}) async {
  final cfg = CountlyConfig(
    appKey: 'app-key-a',
    serverUrl: 'https://server-a.com',
    deviceId: 'test-device',
    storageMode: storageMode,
    giveConsent: true,
    enableSDKLogs: true,
    logger: logger ?? TestLogger(),
    customRequestHeaders: {'X-Custom': 'kept'},
  );
  final sdk = await http.runWithClient(() => Countly.init(cfg), () => servers);
  addTearDown(() async {
    await Countly.disposeAll();
  });
  return sdk;
}

/// App key of each queued request, in queue order.
List<dynamic> _queuedAppKeys(CountlyInstance sdk) => sdk.debugRequestQueueSnapshot.map((r) => r['app_key']).toList();

void main() {
  group('changeServerUrl', () {
    test('queued and new requests go to the new URL with the same app key, headers and SDK name', () async {
      final logger = TestLogger();
      final servers = FakeServers();
      final sdk = await _init(servers, logger: logger);
      expect(servers.describe(), ['server-a.com/o/sdk app-key-a method=sc', 'server-a.com/i app-key-a hc metrics']);
      expect(sdk.debugRequestQueueLength, 3);
      await sdk.events.record(key: 'before_change');
      servers.requests.clear();

      await sdk.changeServerUrl('https://server-b.com///');

      expect(sdk.config.serverUrl, 'https://server-b.com');
      expect(sdk.config.appKey, 'app-key-a');
      await sdk.events.record(key: 'after_change');
      await sdk.processEventsAndRequests();
      expect(servers.describe(), [
        'server-b.com/o/sdk app-key-a method=sc',
        'server-b.com/i app-key-a consent',
        'server-b.com/i app-key-a location',
        'server-b.com/i app-key-a metrics',
        'server-b.com/i app-key-a consent',
        'server-b.com/i app-key-a events[before_change,after_change]',
      ]);
      expect(servers.params.every((p) => p['sdk_name'] == Countly.sdkName && p['sdk_version'] == Countly.sdkVersion),
          isTrue);
      expect(servers.requests.every((r) => r.headers['X-Custom'] == 'kept'), isTrue);

      servers.requests.clear();
      for (final url in ['', 'not a url', 'ftp://server-c.com', 'http://']) {
        await sdk.changeServerUrl(url);
      }
      expect(sdk.config.serverUrl, 'https://server-b.com');
      expect(logger.count(LogLevel.error, 'changeServerUrl called with'), 4);
      await sdk.events.record(key: 'still_on_b');
      await sdk.processEventsAndRequests();
      expect(servers.describe(), ['server-b.com/i app-key-a events[still_on_b]']);
    });
  });

  group('changeAppKey', () {
    test('the old app is closed with the old key, then new requests carry the new key', () async {
      final logger = TestLogger();
      final servers = FakeServers();
      final sdk = await _init(servers, logger: logger);
      await sdk.processEventsAndRequests();
      await sdk.views.startAutoStoppedView('Home');
      await sdk.events.record(key: 'old_app_event');
      await sdk.users.setProperties({'name': 'Old App User'});
      servers.requests.clear();

      await sdk.changeAppKey('app-key-b');

      expect(sdk.config.appKey, 'app-key-b');
      expect(sdk.config.serverUrl, 'https://server-a.com');
      expect(sdk.debugActiveViewName, isNull);
      expect(sdk.debugEventQueueLength, 0);
      await sdk.events.record(key: 'new_app_event');
      await sdk.processEventsAndRequests();
      expect(servers.describe(), [
        'server-a.com/o/sdk app-key-b method=sc',
        'server-a.com/i app-key-a events[old_app_event]',
        'server-a.com/i app-key-a user_details',
        'server-a.com/i app-key-a events[view:Home]',
        'server-a.com/i app-key-b consent',
        'server-a.com/i app-key-b events[new_app_event]',
      ]);
      expect(servers.params[2]['user_details'], {'name': 'Old App User'});
      expect(servers.params.every((p) => p['device_id'] == 'test-device' && p['sdk_name'] == Countly.sdkName), isTrue);

      await sdk.views.startAutoStoppedView('Second');
      final queued = sdk.debugRequestQueueLength;
      servers.requests.clear();
      for (final key in ['', '   ', 'YOUR_APP_KEY', 'app-key-b', ' app-key-b ']) {
        await sdk.changeAppKey(key);
      }
      expect(sdk.config.appKey, 'app-key-b');
      expect(logger.count(LogLevel.error, 'changeAppKey called with'), 3);
      expect(logger.count(LogLevel.debug, 'changeAppKey called with the current app key'), 2);
      expect(sdk.debugActiveViewName, 'Second');
      expect(sdk.debugRequestQueueLength, queued);
      expect(servers.requests, isEmpty);
    });

    test('changes are kept in memory only, a new init uses the config again', () async {
      SharedPreferences.setMockInitialValues({});
      final logger = TestLogger();
      final servers = FakeServers();
      final sdk = await _init(servers, logger: logger, storageMode: StorageMode.persistent);
      await sdk.changeServerUrl('https://server-b.com');
      await sdk.changeAppKey('app-key-b');
      await Countly.disposeAll();

      final prefs = await SharedPreferences.getInstance();
      final stored = prefs.getKeys().map((k) => '${prefs.get(k)}').toList();
      expect(stored, isNotEmpty);
      expect(stored.any((v) => v.contains('server-b.com') || v.contains('app-key-b')), isFalse);
      await sdk.changeServerUrl('https://server-c.com');
      await sdk.changeAppKey('app-key-c');
      expect(logger.count(LogLevel.warning, 'ignored: instance disposed'), 2);
      expect(sdk.config.serverUrl, 'https://server-b.com');

      servers.requests.clear();
      final again = await _init(servers, storageMode: StorageMode.persistent);
      expect(again.config.serverUrl, 'https://server-a.com');
      expect(again.config.appKey, 'app-key-a');
      await again.processEventsAndRequests();
      expect(servers.requests, isNotEmpty);
      expect(servers.requests.map((r) => '${r.url.host} ${jsonDecode(r.body)['app_key']}').toSet(),
          {'server-a.com app-key-a'});
    });
  });

  group('Queue helpers', () {
    test('requests queued under another app key are moved to the current key or removed', () async {
      final servers = FakeServers();
      final sdk = await _init(servers);
      await sdk.events.record(key: 'old_app_event');
      await sdk.changeAppKey('app-key-b');
      expect(_queuedAppKeys(sdk), ['app-key-a', 'app-key-a', 'app-key-a', 'app-key-a', 'app-key-b']);

      await sdk.replaceAllAppKeysInQueueWithCurrentAppKey();

      expect(_queuedAppKeys(sdk), List.filled(5, 'app-key-b'));
      servers.requests.clear();
      await sdk.processEventsAndRequests();
      expect(servers.describe(), [
        'server-a.com/i app-key-b consent',
        'server-a.com/i app-key-b location',
        'server-a.com/i app-key-b metrics',
        'server-a.com/i app-key-b events[old_app_event]',
        'server-a.com/i app-key-b consent',
      ]);

      await sdk.events.record(key: 'removed_event');
      await sdk.changeAppKey('app-key-c');
      expect(_queuedAppKeys(sdk), ['app-key-b', 'app-key-c']);

      await sdk.removeDifferentAppKeysFromQueue();

      expect(_queuedAppKeys(sdk), ['app-key-c']);
      servers.requests.clear();
      await sdk.processEventsAndRequests();
      expect(servers.describe(), ['server-a.com/i app-key-c consent']);
    });

    test('flushQueues drops queued events and requests, the running view and pending user properties stay', () async {
      final servers = FakeServers();
      final sdk = await _init(servers);
      await sdk.views.startAutoStoppedView('Kept view');
      await sdk.events.record(key: 'flushed_event');
      expect(sdk.debugRequestQueueLength, 3);
      expect(sdk.debugEventQueueLength, 1);

      await sdk.flushQueues();

      expect(sdk.debugRequestQueueLength, 0);
      expect(sdk.debugEventQueueLength, 0);
      expect(sdk.debugActiveViewName, 'Kept view');
      await sdk.users.setProperties({'name': 'Kept user'});
      await sdk.flushQueues();
      servers.requests.clear();
      await sdk.views.endActiveView();
      await sdk.events.record(key: 'new_event');
      await sdk.processEventsAndRequests();
      expect(servers.describe(), [
        'server-a.com/i app-key-a user_details',
        'server-a.com/i app-key-a events[view:Kept view,new_event]',
      ]);
      expect(servers.params.first['user_details'], {'name': 'Kept user'});
    });
  });
}
