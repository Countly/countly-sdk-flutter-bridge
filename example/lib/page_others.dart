import 'dart:io';

import 'package:countly_flutter/countly_flutter.dart';
import 'package:countly_flutter_example/helpers.dart';
import 'package:flutter/material.dart';

class OthersPage extends StatelessWidget {
  void recordDirectAttribution() {
    String campaignData = '{cid:"[PROVIDED_CAMPAIGN_ID]", cuid:"[PROVIDED_CAMPAIGN_USER_ID]"}';
    Countly.recordDirectAttribution('countly', campaignData);
  }

  void recordIndirectAttribution() {
    Map<String, String> attributionValues = {};
    if (Platform.isIOS) {
      attributionValues[AttributionKey.IDFA] = 'IDFA';
    } else {
      attributionValues[AttributionKey.AdvertisingID] = 'AdvertisingID';
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

    Countly.recordEvent({'key': 'value', 'count': 1, 'sum': 3.14, 'segmentation': segment});
    Countly.instance.views.startView('viewName', segment);
    Countly.instance.views.stopAllViews();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Other Features'),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(15),
        child: Center(
            child: Column(
          children: [
            MyButton(text: 'Record Direct Attribution', color: 'olive', onPressed: recordDirectAttribution),
            MyButton(text: 'Record Indirect Attribution', color: 'olive', onPressed: recordIndirectAttribution),
            MyButton(text: 'Push Notification', color: 'blue', onPressed: askForNotificationPermission),
            MyButton(text: 'Set Location', color: 'violet', onPressed: setLocation),
            MyButton(text: 'Disable Location', color: 'violet', onPressed: disableLocation),
            MyButton(text: 'Random List Values', color: 'violet', onPressed: randomListValues),
          ],
        )),
      ),
    );
  }
}
