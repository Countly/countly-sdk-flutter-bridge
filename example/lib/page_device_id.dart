import 'dart:math';

import 'package:countly_flutter_np/countly_flutter.dart';
import 'package:countly_flutter_example/helpers.dart';
import 'package:flutter/material.dart';

class DeviceIDPage extends StatefulWidget {
  @override
  State<DeviceIDPage> createState() => _DeviceIDPageState();
}

class _DeviceIDPageState extends State<DeviceIDPage> {
  /// To Show the device id type in UI, when user tap on 'Get Device Id Type' button
  String _deviceId = '';
  String _deviceIdType = '';

  String makeid() {
    int code = Random().nextInt(999999);
    String random = code.toString();
    print(random);
    return random;
  }

  Future<void> getID() async {
    String? deviceId = await Countly.instance.deviceId.getID();
    if (deviceId != null) {
      setState(() {
        _deviceId = deviceId.toString();
      });
    }
  }

  Future<void> getIDType() async {
    DeviceIdType? deviceIdType = await Countly.instance.deviceId.getIDType();
    if (deviceIdType != null) {
      setState(() {
        _deviceIdType = deviceIdType.toString();
      });
    }
  }

  void changeWithMerge() {
    Countly.instance.deviceId.changeWithMerge('123456');
  }

  void changeWithoutMerge() {
    Countly.instance.deviceId.changeWithoutMerge(makeid());
  }

  void enableTemporaryIDMode() {
    Countly.instance.deviceId.enableTemporaryIDMode();
  }

  void setID() {
    Countly.instance.deviceId.setID(makeid());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Device ID Management'),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: 3,
        separatorBuilder: (_, __) => const SizedBox(height: 16),
        itemBuilder: (_, index) {
          switch (index) {
            case 0:
              return Card(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Device Info', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Text('ID: '),
                          Expanded(
                            child: Text(
                              _deviceId.isEmpty ? 'N/A' : _deviceId,
                              style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.w500),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Text('Type: '),
                          Expanded(
                            child: Text(
                              _deviceIdType.isEmpty ? 'N/A' : _deviceIdType,
                              style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.w500),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            case 1:
              return CountlySection(
                title: 'Query Device ID',
                children: [
                  MyButton(text: 'Get Device ID', type: CountlyButtonType.filled, onPressed: getID),
                  MyButton(text: 'Get Device ID Type', type: CountlyButtonType.filled, onPressed: getIDType),
                ],
              );
            case 2:
              return CountlySection(
                title: 'Change Device ID',
                children: [
                  MyButton(text: 'Change Device ID With Merge', type: CountlyButtonType.tonal, onPressed: changeWithMerge),
                  MyButton(text: 'Change Device ID Without Merge', type: CountlyButtonType.tonal, onPressed: changeWithoutMerge),
                  MyButton(text: 'Enable Temporary ID Mode', type: CountlyButtonType.outlined, onPressed: enableTemporaryIDMode),
                  MyButton(text: 'Set ID', type: CountlyButtonType.tonal, onPressed: setID),
                ],
              );
            default:
              return const SizedBox.shrink();
          }
        },
      ),
    );
  }
}
