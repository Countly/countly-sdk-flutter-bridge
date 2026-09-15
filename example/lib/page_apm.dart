import 'dart:math';

import 'package:countly_flutter_np/countly_flutter.dart';
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

  void cancelTrace() {
    String traceKey = 'Trace Key';
    Countly.cancelTrace(traceKey);
  }

  void clearAllTraces() {
    Countly.clearAllTraces();
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
    return CountlyPageScaffold(
      title: 'APM',
      sections: [
        CountlySection(
          title: 'Custom Traces',
          children: [
            MyButton(text: 'Start Trace', type: CountlyButtonType.filled, onPressed: startTrace),
            MyButton(text: 'End Trace', type: CountlyButtonType.tonal, onPressed: endTrace),
            MyButton(text: 'Cancel Trace', type: CountlyButtonType.outlined, onPressed: cancelTrace),
            MyButton(text: 'Clear All Traces', type: CountlyButtonType.outlined, onPressed: clearAllTraces),
          ],
        ),
        CountlySection(
          title: 'Network Traces',
          children: [
            MyButton(text: 'Record Network Trace Success', type: CountlyButtonType.filled, onPressed: recordNetworkTraceSuccess),
            MyButton(text: 'Record Network Trace Failure', type: CountlyButtonType.tonal, onPressed: recordNetworkTraceFailure),
          ],
        ),
      ],
    );
  }
}
