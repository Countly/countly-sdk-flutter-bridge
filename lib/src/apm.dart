abstract class Apm {
  /// Start a custom trace that measures how long a process takes.
  /// [String traceKey]: the name of the trace, also used to end or cancel it
  Future<void> startTrace(String traceKey);

  /// End a custom trace and report it.
  /// [String traceKey]: the name the trace was started with
  /// [Map<String, int>? customMetrics]: metrics to report together with the duration
  Future<void> endTrace(String traceKey, [Map<String, int>? customMetrics]);

  /// Cancel a custom trace without reporting it.
  /// [String traceKey]: the name the trace was started with
  Future<void> cancelTrace(String traceKey);

  /// Cancel every custom trace without reporting them.
  Future<void> cancelAllTraces();

  /// Report a network request that already completed.
  /// [String networkTraceKey]: the name of the request, usually its URL without parameters
  /// [int responseCode]: the HTTP status code of the response
  /// [int requestPayloadSize]: the size of the request body in bytes
  /// [int responsePayloadSize]: the size of the response body in bytes
  /// [int startTime]: when the request started, in milliseconds since the epoch
  /// [int endTime]: when the response arrived, in milliseconds since the epoch
  Future<void> recordNetworkTrace(String networkTraceKey, int responseCode, int requestPayloadSize, int responsePayloadSize, int startTime, int endTime);

  /// Tell the SDK the application finished loading, which ends the app start measurement.
  /// Only needed when "enableManualAppLoadedTrigger" is set on "CountlyConfig.apm".
  Future<void> setAppIsLoaded();
}
