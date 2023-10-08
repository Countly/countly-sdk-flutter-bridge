import 'dart:math';

import 'package:countly_flutter/countly_flutter.dart';
import 'package:countly_flutter_example/helpers.dart';
import 'package:flutter/material.dart';

class APMPage extends StatelessWidget {
  // APM Examples
  void startTrace() {
    String traceKey = 'Trace Key';
    Countly.startTrace(traceKey);
  }

  void endTrace() {
    String traceKey = 'Trace Key';
    Map<String, int> customMetric = {'ABC': 1233, 'C44C': 1337};
    Countly.endTrace(traceKey, customMetric);
  }

  final List<int> successCodes = [100, 101, 200, 201, 202, 205, 300, 301, 303, 305];
  final List<int> failureCodes = [400, 402, 405, 408, 500, 501, 502, 505];

  void recordNetworkTraceSuccess() {
    String networkTraceKey = 'api/endpoint.1';
    var rnd = Random();
    int responseCode = successCodes[rnd.nextInt(successCodes.length)];
    int requestPayloadSize = rnd.nextInt(700) + 200;
    int responsePayloadSize = rnd.nextInt(700) + 200;
    int startTime = DateTime.now().millisecondsSinceEpoch;
    int endTime = startTime + 500;
    Countly.recordNetworkTrace(networkTraceKey, responseCode, requestPayloadSize, responsePayloadSize, startTime, endTime);
  }

  void recordNetworkTraceFailure() {
    String networkTraceKey = 'api/endpoint.1';
    var rnd = Random();
    int responseCode = failureCodes[rnd.nextInt(failureCodes.length)];
    int requestPayloadSize = rnd.nextInt(700) + 250;
    int responsePayloadSize = rnd.nextInt(700) + 250;
    int startTime = DateTime.now().millisecondsSinceEpoch;
    int endTime = startTime + 500;
    Countly.recordNetworkTrace(networkTraceKey, responseCode, requestPayloadSize, responsePayloadSize, startTime, endTime);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('APM'),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(15),
        child: Center(
            child: Column(
          children: [
            MyButton(text: 'Start Trace', color: 'brown', onPressed: startTrace),
            MyButton(text: 'End Trace', color: 'brown', onPressed: endTrace),
            MyButton(text: 'Record Network Trace Success', color: 'black', onPressed: recordNetworkTraceSuccess),
            MyButton(text: 'Record Network Trace Failure', color: 'black', onPressed: recordNetworkTraceFailure),
          ],
        )),
      ),
    );
  }
}
