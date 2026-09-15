import 'dart:io';

import 'package:countly_flutter_np/countly_flutter.dart';
import 'package:countly_flutter_example/helpers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class OthersPage extends StatefulWidget {
  @override
  State<OthersPage> createState() => _OthersPageState();
}

class _OthersPageState extends State<OthersPage> {
  void recordDirectAttribution() {
    String campaignData = '{cid:"[PROVIDED_CAMPAIGN_ID]", cuid:"[PROVIDED_CAMPAIGN_USER_ID]"}';
    Countly.recordDirectAttribution('countly', campaignData);
  }

  void recordIndirectAttribution() {
    Map<String, String> attributionValues = {};
    if (!kIsWeb) {
      if (Platform.isIOS) {
        attributionValues[AttributionKey.IDFA] = 'IDFA';
      } else {
        attributionValues[AttributionKey.AdvertisingID] = 'AdvertisingID';
      }
    }
    Countly.recordIndirectAttribution(attributionValues);
  }

  void askForNotificationPermission() {
    Countly.askForNotificationPermission();
  }

  void setLocation() {
    Countly.setUserLocation(countryCode: 'KR', city: 'Seoul');
    Countly.setUserLocation(gpsCoordinates: '41.0082,28.9784');
    Countly.setUserLocation(ipAddress: '10.2.33.12');
    Countly.setUserLocation(countryCode: 'KR', city: 'Seoul', gpsCoordinates: '41.0082,28.9784', ipAddress: '10.2.33.12');
  }

  void disableLocation() {
    Countly.disableLocation();
  }

  void randomListValues() {
    // string list
    List<String> list = ['value1', 'value2', 'value3'];
    // int list
    List<int> intList = [1, 2, 3];
    // double list
    List<double> doubleList = [1.1, 2.2, 3.3];
    // bool list
    List<bool> boolList = [true, false, true];
    // mixed list
    List<dynamic> mixedList = ['value1', 2, 3.3, true];
    // map list
    List<Map<String, dynamic>> mapList = [
      {'key1': 'value1', 'key2': 2},
      {'key1': 'value2', 'key2': 3},
      {'key1': 'value3', 'key2': 4}
    ];
    // nested list
    List<List<String>> nestedList = [
      ['value1', 'value2'],
      ['value3', 'value4'],
      ['value5', 'value6']
    ];
    var segment = {
      'stringList': list,
      'intList': intList,
      'doubleList': doubleList,
      'boolList': boolList,
      'mixedList': mixedList,
      'mapList': mapList,
      'nestedList': nestedList,
      'normalString': 'normalString',
      'normalInt': 1,
      'normalDouble': 1.1,
      'normalBool': true,
    };

    Countly.startEvent('timed');
    Countly.endEvent({'key': 'timed', 'segmentation': segment});
    Countly.recordEvent({'key': 'value', 'count': 1, 'sum': 3.14, 'segmentation': segment});
    Countly.instance.views.startView('viewName', segment);
    Countly.instance.views.stopAllViews();
  }

  Future<void> checkIsInitialized() async {
    bool result = await Countly.isInitialized();
    if (mounted) {
      showCountlyToast(context, 'isInitialized: $result', null);
    }
  }

  void disablePushNotifications() {
    Countly.disablePushNotifications();
  }

  void replaceAllAppKeys() {
    Countly.replaceAllAppKeysInQueueWithCurrentAppKey();
  }

  void removeDifferentAppKeys() {
    Countly.removeDifferentAppKeysFromQueue();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Other Features'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          CountlySection(
            title: 'SDK Status',
            children: [
              MyButton(text: 'Is Initialized', type: CountlyButtonType.filled, onPressed: checkIsInitialized),
            ],
          ),
          const SizedBox(height: 16),
          CountlySection(
            title: 'Attribution',
            children: [
              MyButton(text: 'Record Direct Attribution', type: CountlyButtonType.tonal, onPressed: recordDirectAttribution),
              MyButton(text: 'Record Indirect Attribution', type: CountlyButtonType.tonal, onPressed: recordIndirectAttribution),
            ],
          ),
          const SizedBox(height: 16),
          CountlySection(
            title: 'Push Notifications',
            children: [
              MyButton(text: 'Ask for Permission', type: CountlyButtonType.filled, onPressed: askForNotificationPermission),
              MyButton(text: 'Disable Push Notifications', type: CountlyButtonType.outlined, onPressed: disablePushNotifications),
            ],
          ),
          const SizedBox(height: 16),
          CountlySection(
            title: 'Location',
            children: [
              MyButton(text: 'Set Location', type: CountlyButtonType.filled, onPressed: setLocation),
              MyButton(text: 'Disable Location', type: CountlyButtonType.outlined, onPressed: disableLocation),
            ],
          ),
          const SizedBox(height: 16),
          CountlySection(
            title: 'Miscellaneous',
            children: [
              MyButton(text: 'Random List Values', type: CountlyButtonType.tonal, onPressed: randomListValues),
              MyButton(text: 'Replace All App Keys In Queue', type: CountlyButtonType.tonal, onPressed: replaceAllAppKeys),
              MyButton(text: 'Remove Different App Keys From Queue', type: CountlyButtonType.outlined, onPressed: removeDifferentAppKeys),
            ],
          ),
        ],
      ),
    );
  }
}
