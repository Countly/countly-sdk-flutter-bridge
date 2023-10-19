import 'dart:io';

import 'package:countly_flutter_np/countly_flutter.dart';
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
            MyButton(text: 'setLocation', color: 'violet', onPressed: setLocation),
          ],
        )),
      ),
    );
  }
}
