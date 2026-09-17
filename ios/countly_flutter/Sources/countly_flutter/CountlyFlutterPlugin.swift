// CountlyFlutterPlugin.swift
//
// This code is provided under the MIT License.
//
// Please visit www.count.ly for more information.

import Countly
import CoreLocation
import Flutter
import Foundation
import UserNotifications

/// Whether this is the no-push flavour. Derived from the compilation condition the
/// manifests set, so the two cannot disagree.
#if COUNTLY_EXCLUDE_PUSHNOTIFICATIONS
let BUILDING_WITH_PUSH_DISABLED = true
#else
let BUILDING_WITH_PUSH_DISABLED = false
#endif

let kCountlyFlutterSDKVersion = "26.8.0"
let kCountlyFlutterSDKName = "dart-flutterb-ios"
let kCountlyFlutterSDKNameNoPush = "dart-flutterbnp-ios"

@objc(CountlyFlutterPlugin)
public class CountlyFlutterPlugin: NSObject, FlutterPlugin {

    static var channel: FlutterMethodChannel?

    // Recreated after every default init, so options an earlier init set do not stick to the next one in the same process.
    private var config = CountlyConfig()
    private var isDebugLogging = false
    /// The widgets each instance last listed, keyed by instance name, so a widget ID is presented on the instance that fetched it.
    private var feedbackWidgetLists: [String: [CountlyFeedbackWidget]] = [:]

    /// Registers the plugin with the Flutter engine.
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "countly_flutter", binaryMessenger: registrar.messenger())
        Self.channel = channel
        registrar.addMethodCallDelegate(CountlyFlutterPlugin(), channel: channel)
    }

    // MARK: - Host application entry points

    /// Registers the plugin as the notification centre delegate.
    ///
    /// Called from the host application's delegate, before the SDK starts, so that
    /// the SDK chains to the plugin rather than replacing it.
    @objc public static func startObservingNotifications() {
        #if !COUNTLY_EXCLUDE_PUSHNOTIFICATIONS
        CountlyFLPushNotifications.shared.startObservingNotifications()
        #endif
    }

    /// Hands a notification payload received by the host application to Dart.
    @objc public static func onNotification(_ notification: [AnyHashable: Any]?) {
        #if !COUNTLY_EXCLUDE_PUSHNOTIFICATIONS
        CountlyFLPushNotifications.shared.onNotification(notification)
        #endif
    }

    /// Hands a notification response received by the host application to Dart.
    @objc public static func onNotificationResponse(_ response: UNNotificationResponse) {
        #if !COUNTLY_EXCLUDE_PUSHNOTIFICATIONS
        CountlyFLPushNotifications.shared.onNotificationResponse(response)
        #endif
    }

    /// Logs a plugin-level message, gated at runtime only. A compile-time guard
    /// would hide these from release builds, where support needs them most.
    private func log(_ message: @autoclosure () -> String) {
        guard isDebugLogging || config.enableDebug else { return }
        NSLog("[CountlyFlutterPlugin] %@", message())
    }

    /// Logs and ignores a method the underlying SDK cannot serve. A FlutterError
    /// would reach Dart as a thrown PlatformException.
    private func unavailable(_ method: String, _ reason: String, _ result: @escaping FlutterResult) {
        let message = "[\(method)] is not available on the iOS SDK and was ignored: \(reason)"
        log(message)
        result(message)
    }

    // MARK: - Argument helpers

    private func string(_ command: [Any], _ index: Int) -> String? {
        guard index < command.count else { return nil }
        if let value = command[index] as? String {
            return value == "null" ? nil : value
        }
        if let value = command[index] as? NSNumber { return value.stringValue }
        return nil
    }

    private func number(_ command: [Any], _ index: Int) -> NSNumber? {
        guard index < command.count else { return nil }
        if let value = command[index] as? NSNumber { return value }
        if let value = command[index] as? String { return NSNumber(value: (value as NSString).doubleValue) }
        return nil
    }

    /// Reads a boolean argument. Dart sends these as JSON booleans or as the
    /// strings "true"/"false", which numeric parsing would turn into false.
    private func boolean(_ command: [Any], _ index: Int) -> Bool? {
        guard index < command.count else { return nil }
        if let value = command[index] as? Bool { return value }
        if let value = command[index] as? NSNumber { return value.boolValue }
        if let value = command[index] as? String { return (value as NSString).boolValue }
        return nil
    }

    /// The argument exactly as sent, with no type coercion.
    private func value(_ command: [Any], _ index: Int) -> Any? {
        guard index < command.count else { return nil }
        return command[index] is NSNull ? nil : command[index]
    }

    private func dictionary(_ command: [Any], _ index: Int) -> [String: Any]? {
        guard index < command.count else { return nil }
        return command[index] as? [String: Any]
    }

    private func array(_ command: [Any], _ index: Int) -> [Any]? {
        guard index < command.count else { return nil }
        return command[index] as? [Any]
    }

    /// Parses the "lat,long" string the Dart side sends into a coordinate.
    private func coordinate(from gpsCoordinate: String?) -> CLLocationCoordinate2D {
        guard let gpsCoordinate, !gpsCoordinate.isEmpty, gpsCoordinate != "null" else {
            return kCLLocationCoordinate2DInvalid
        }
        guard gpsCoordinate.contains(",") else {
            log("[coordinate], Invalid location Coordinates:[\(gpsCoordinate)], lat and long values should be comma separated")
            return kCLLocationCoordinate2DInvalid
        }
        let parts = gpsCoordinate.components(separatedBy: ",")
        if parts.count > 2 {
            log("[coordinate], Invalid location Coordinates:[\(gpsCoordinate)], it should contains only two comma seperated values")
        }
        guard parts.count >= 2 else { return kCLLocationCoordinate2DInvalid }
        let latitude = (parts[0] as NSString).doubleValue
        let longitude = (parts[1] as NSString).doubleValue
        if latitude == 0 || longitude == 0 {
            log("[coordinate], Invalid location Coordinates, One of the values parsed to a 0, double check that given coordinates are correct:[\(gpsCoordinate)]")
        }
        return CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    /// Builds the flat segmentation dictionary from a key, value, key, value tail.
    private func segmentation(from command: [Any], startingAt start: Int) -> [String: Any] {
        var parsed: [String: Any] = [:]
        var index = start
        while index + 1 < command.count {
            if let key = command[index] as? String {
                parsed[key] = command[index + 1]
            }
            index += 2
        }
        return parsed
    }

    /// Turns every performance monitoring tracker on or off together.
    ///
    /// Stands in for the deprecated Objective-C `enablePerformanceMonitoring`, which
    /// was itself only a shorthand for setting these three.
    private func setPerformanceMonitoringEnabled(_ enabled: Bool, on config: CountlyConfig) {
        config.apm.enableForegroundBackgroundTracking = enabled
        config.apm.enableAppStartTimeTracking = enabled
        config.apm.enableManualAppLoadedTrigger = enabled
    }

    /// Adds an init-time feature, keeping the accumulated set on the config.
    private func addCountlyFeature(_ feature: CountlyFeature, on config: CountlyConfig) {
        guard !config.features.contains(feature) else { return }
        config.features.append(feature)
    }

    // MARK: - Conversion helpers

    private func map(_ rcData: CountlyRCData) -> [String: Any] {
        var converted: [String: Any] = ["isCurrentUsersData": rcData.isCurrentUsersData]
        if let value = rcData.value { converted["value"] = value }
        return converted
    }

    private func map(_ values: [String: CountlyRCData]) -> [String: Any] {
        values.mapValues(map)
    }

    /// The code the Dart side expects for a request outcome. Absent for an outcome
    /// it has no code for, which leaves the key out as it always has.
    private func requestResultCode(_ response: RequestResult) -> Int {
        switch response {
        case .success: return 0
        case .networkIssue: return 1
        default: return 2
        }
    }

    /// Reads a string array argument.
    private func stringArray(_ command: [Any], _ index: Int) -> [String] {
        array(command, index)?.compactMap { $0 as? String } ?? []
    }

    private func findFeedbackWidget(_ instanceName: String?, _ widgetID: String) -> CountlyFeedbackWidget? {
        feedbackWidgetLists[instanceName ?? ""]?.first { $0.id == widgetID }
    }

    /// The message returned when the Dart side names a widget that was never fetched.
    private func missingWidget(_ method: String, _ widgetID: String) -> String {
        let message = "[\(method)], No feedbackWidget is found against widget Id : '\(widgetID)', always call 'getFeedbackWidgets' to get updated list of feedback widgets."
        log(message)
        return message
    }

    /// Maps Countly consent wire names onto the SDK enum. An unrecognised name is
    /// logged and skipped rather than discarding the rest of the call.
    private func consentFeatures(from command: [Any]) -> [ConsentFeature] {
        var features: [ConsentFeature] = []
        for entry in command {
            guard let wireName = entry as? String else { continue }
            guard let feature = ConsentFeature(wireName: wireName) else {
                log("unrecognised consent name, it will be ignored: [\(wireName)]")
                continue
            }
            features.append(feature)
        }
        return features
    }

    // MARK: - Callbacks to Dart

    /// Tags a callback payload with the instance it belongs to, so the Dart side can route it.
    /// - Parameters:
    ///   - instanceName: the instance the callback belongs to, or nil for the default instance
    ///   - data: the payload to tag
    /// - Returns: the payload, with the instance name added when there is one
    private static func tagged(_ instanceName: String?, _ data: [String: Any] = [:]) -> [String: Any] {
        guard let instanceName else { return data }
        var tagged = data
        tagged["instanceName"] = instanceName
        return tagged
    }

    private func remoteConfigDownloadCallback(_ callbackID: NSNumber,
                                              instanceName: String?,
                                              result response: RequestResult,
                                              fullValueUpdate: Bool,
                                              error: Error?,
                                              downloadedValues: [String: CountlyRCData]) {
        log("[remoteConfigDownloadCallback], about to notify flutter side callback \(callbackID)")
        if callbackID.intValue == -1 { return }

        var data = Self.tagged(instanceName, ["id": callbackID, "fullValueUpdate": fullValueUpdate])
        data["requestResult"] = requestResultCode(response)
        data["downloadedValues"] = map(downloadedValues)
        if let error { data["error"] = String(describing: error) }

        Self.channel?.invokeMethod("remoteConfigDownloadCallback", arguments: data)
    }

    private func remoteConfigVariantCallback(_ callbackID: NSNumber, instanceName: String?, result response: RequestResult, error: Error?) {
        var data = Self.tagged(instanceName, ["id": callbackID])
        data["requestResult"] = requestResultCode(response)
        if let error { data["error"] = String(describing: error) }

        Self.channel?.invokeMethod("remoteConfigVariantCallback", arguments: data)
    }

    private func feedbackWidgetDataCallback(_ widgetData: [String: Any]?, instanceName: String?, error: String?) {
        var data = Self.tagged(instanceName)
        if let widgetData { data["widgetData"] = widgetData }
        if let error { data["error"] = error }
        Self.channel?.invokeMethod("feedbackWidgetDataCallback", arguments: data)
    }

    // MARK: - Method channel

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        let arguments = call.arguments as? [String: Any]
        let commandString = arguments?["data"] as? String ?? "[]"
        let command = (try? JSONSerialization.jsonObject(with: Data(commandString.utf8))) as? [Any] ?? []

        // Calls from the default instance carry no name, so they keep reaching the shared instance.
        let instanceName = (arguments?["instanceName"] as? String).flatMap { $0.isEmpty || $0 == Countly.defaultInstanceName ? nil : $0 }

        // Answered before an instance is resolved, resolving one would create it as a side effect.
        switch call.method {
        case "removeInstance":
            guard let instanceName else {
                result("removeInstance: the default instance can not be removed")
                return
            }
            feedbackWidgetLists.removeValue(forKey: instanceName)
            Countly.removeInstance(named: instanceName)
            result("removeInstance: success")
            return
        case "haltAllInstances":
            feedbackWidgetLists.removeAll()
            Countly.haltAllInstances(clearStorage: true)
            result("haltAllInstances: success")
            return
        case "isInitialized":
            let existing = instanceName.map { Countly.getInstance(named: $0) } ?? Countly.shared
            result((existing?.isStarted ?? false) ? "true" : "false")
            return
        default:
            break
        }

        let cly = Countly.instance(named: instanceName)

        switch call.method {

        // MARK: Lifecycle

        case "init":
            guard let configMap = dictionary(command, 0) else {
                result("initialization failed!")
                return
            }
            // The default instance keeps the shared config so the deprecated pre-init setters still reach it.
            let instanceConfig = instanceName == nil ? config : CountlyConfig()
            populateConfig(configMap, into: instanceConfig, instanceName: instanceName)
            instanceConfig.internalLogLevel = .verbose
            instanceConfig.instanceName = instanceName

            // The plugin reports itself rather than the underlying native SDK, so that
            // a Flutter integration is attributed to the Flutter SDK on the dashboard.
            instanceConfig.sdkName = BUILDING_WITH_PUSH_DISABLED ? kCountlyFlutterSDKNameNoPush : kCountlyFlutterSDKName
            instanceConfig.sdkVersion = kCountlyFlutterSDKVersion

            #if !COUNTLY_EXCLUDE_PUSHNOTIFICATIONS
            // Push is process wide and stays with the default instance.
            if instanceName == nil && CountlyFLPushNotifications.shared.enablePushNotifications {
                addCountlyFeature(.pushNotifications, on: instanceConfig)
            }
            #endif

            if !instanceConfig.host.isEmpty {
                if instanceName == nil {
                    isDebugLogging = instanceConfig.enableDebug
                    config = CountlyConfig()
                }
                DispatchQueue.main.async {
                    cly.start(with: instanceConfig)
                    #if !COUNTLY_EXCLUDE_PUSHNOTIFICATIONS
                    if instanceName == nil {
                        CountlyFLPushNotifications.shared.recordPushActions()
                    }
                    #endif
                }
                result("initialized.")
            } else {
                result("initialization failed!")
            }

        case "halt":
            // Testing purposes only, like the Android plugin: the instance is torn down and its stored data erased.
            DispatchQueue.main.async {
                cly.halt(clearStorage: true)
                result("halt: success")
            }


        // MARK: Queue introspection (test-only)

        case "getRequestQueue":
            DispatchQueue.main.async { result(cly.requestQueue.queuedRequests()) }

        case "getEventQueue":
            DispatchQueue.main.async { result(cly.events.recordedEvents()) }

        case "storeRequest":
            DispatchQueue.main.async {
                guard let request = self.string(command, 0) else { result("stored request"); return }
                cly.requestQueue.store(request)
                result("stored request")
            }

        case "recordReservedEvent":
            DispatchQueue.main.async {
                guard let key = self.string(command, 0),
                      let event = CountlyReservedEvent(rawValue: key) else {
                    self.unavailable("recordReservedEvent", "not a reserved key a host may record", result)
                    return
                }
                cly.events.recordReservedEvent(event, segmentation: self.dictionary(command, 1))
                result("recordReservedEvent for: " + key)
            }

        case "addDirectRequest":
            DispatchQueue.main.async {
                let requestMap = self.dictionary(command, 0) as? [String: String] ?? [:]
                cly.addDirectRequest(requestMap)
                result("added request to queue")
            }

        case "setServerConfig":
            DispatchQueue.main.async {
                let serverConfig = self.dictionary(command, 0) ?? [:]
                UserDefaults.standard.set(serverConfig, forKey: "kCountlyServerConfigPersistencyKey")
                result("setServerConfig: success")
            }

        case "getServerConfig":
            DispatchQueue.main.async {
                let stored = UserDefaults.standard.object(forKey: "kCountlyServerConfigPersistencyKey") as? [String: Any]
                result(stored ?? [:])
            }

        // MARK: Events

        case "recordEvent":
            DispatchQueue.main.async {
                guard let key = self.string(command, 0) else { result("recordEvent for: "); return }
                let count = self.number(command, 1)?.intValue ?? 1
                let sum = self.number(command, 2)?.doubleValue ?? 0
                let duration = self.number(command, 3)?.doubleValue ?? 0
                let segmentation = self.dictionary(command, 4)
                cly.events.recordEvent(key, segmentation: segmentation, count: count, sum: sum, duration: duration)
                result("recordEvent for: " + key)
            }

        case "startEvent":
            DispatchQueue.main.async {
                if let key = self.string(command, 0) { cly.events.startEvent(key) }
                result("startEvent!")
            }

        case "cancelEvent":
            DispatchQueue.main.async {
                if let key = self.string(command, 0) { cly.events.cancelEvent(key) }
                result("cancelEvent!")
            }

        case "endEvent":
            DispatchQueue.main.async {
                guard let key = self.string(command, 0) else { result("endEvent for: "); return }
                let count = self.number(command, 1)?.intValue ?? 1
                let sum = self.number(command, 2)?.doubleValue ?? 0
                let segmentation = self.dictionary(command, 3)
                cly.events.endEvent(key, segmentation: segmentation, count: count, sum: sum)
                result("endEvent for: " + key)
            }

        case "eventSendThreshold":
            DispatchQueue.main.async {
                if let limit = self.number(command, 0)?.intValue { self.config.eventSendThreshold = limit }
                result("eventSendThreshold!")
            }

        // MARK: Views

        case "recordView":
            DispatchQueue.main.async {
                guard let viewName = self.string(command, 0) else { result("recordView Sent!"); return }
                // The deprecated Objective-C recordView forwarded to startAutoStoppedView.
                cly.views.startAutoStoppedView(viewName, segmentation: self.segmentation(from: command, startingAt: 1))
                result("recordView Sent!")
            }

        case "startView":
            DispatchQueue.main.async {
                guard let viewName = self.string(command, 0) else { result(nil); return }
                result(cly.views.startView(viewName, segmentation: self.dictionary(command, 1)))
            }

        case "startAutoStoppedView":
            DispatchQueue.main.async {
                guard let viewName = self.string(command, 0) else { result(nil); return }
                result(cly.views.startAutoStoppedView(viewName, segmentation: self.dictionary(command, 1)))
            }

        case "stopAllViews":
            DispatchQueue.main.async {
                cly.views.stopAllViews(segmentation: self.dictionary(command, 0))
                result(nil)
            }

        case "stopViewWithID":
            DispatchQueue.main.async {
                if let viewID = self.string(command, 0) {
                    cly.views.stopView(id: viewID, segmentation: self.dictionary(command, 1))
                }
                result(nil)
            }

        case "stopViewWithName":
            DispatchQueue.main.async {
                if let viewName = self.string(command, 0) {
                    cly.views.stopView(name: viewName, segmentation: self.dictionary(command, 1))
                }
                result(nil)
            }

        case "pauseViewWithID":
            DispatchQueue.main.async {
                if let viewID = self.string(command, 0) { cly.views.pauseView(id: viewID) }
                result(nil)
            }

        case "resumeViewWithID":
            DispatchQueue.main.async {
                if let viewID = self.string(command, 0) { cly.views.resumeView(id: viewID) }
                result(nil)
            }

        case "setGlobalViewSegmentation":
            DispatchQueue.main.async {
                cly.views.setGlobalViewSegmentation(self.dictionary(command, 0) ?? [:])
                result(nil)
            }

        case "updateGlobalViewSegmentation":
            DispatchQueue.main.async {
                cly.views.updateGlobalViewSegmentation(self.dictionary(command, 0) ?? [:])
                result(nil)
            }

        case "addSegmentationToViewWithID":
            DispatchQueue.main.async {
                if let viewID = self.string(command, 0) {
                    cly.views.addSegmentation(toViewWithID: viewID, segmentation: self.dictionary(command, 1) ?? [:])
                }
                result(nil)
            }

        case "addSegmentationToViewWithName":
            DispatchQueue.main.async {
                if let viewName = self.string(command, 0) {
                    cly.views.addSegmentation(toViewWithName: viewName, segmentation: self.dictionary(command, 1) ?? [:])
                }
                result(nil)
            }

        // MARK: Sessions

        case "beginSession":
            DispatchQueue.main.async { cly.sessions.beginSession(); result("beginSession!") }

        case "updateSession":
            DispatchQueue.main.async { cly.sessions.updateSession(); result("updateSession!") }

        case "endSession":
            DispatchQueue.main.async { cly.sessions.endSession(); result("endSession!") }

        case "manualSessionHandling":
            DispatchQueue.main.async { self.config.manualSessionHandling = true; result("manualSessionHandling!") }

        case "updateSessionPeriod":
            DispatchQueue.main.async { self.config.updateSessionPeriod = 15; result("updateSessionPeriod!") }

        case "updateSessionInterval":
            DispatchQueue.main.async {
                if let interval = self.number(command, 0)?.doubleValue { self.config.updateSessionPeriod = interval }
                result("updateSessionInterval Success!")
            }

        case "storedRequestsLimit":
            DispatchQueue.main.async { self.config.storedRequestsLimit = 1; result("storedRequestsLimit!") }

        // MARK: Device ID

        case "getID":
            result(cly.deviceID.current)

        case "getIDType":
            switch cly.deviceID.type {
            case .developerSupplied: result("DS")
            case .temporary: result("TID")
            default: result("SG")
            }

        case "setID":
            DispatchQueue.main.async {
                if let deviceID = self.string(command, 0) { cly.deviceID.setID(deviceID) }
                result("setID success!")
            }

        case "enableTemporaryIDMode":
            DispatchQueue.main.async {
                cly.deviceID.enableTemporaryIDMode()
                result("enableTemporaryIDMode success!")
            }

        case "changeWithMerge":
            DispatchQueue.main.async {
                if let deviceID = self.string(command, 0) { cly.deviceID.changeWithMerge(deviceID) }
                result("changeWithMerge!")
            }

        case "changeWithoutMerge":
            DispatchQueue.main.async {
                if let deviceID = self.string(command, 0) { cly.deviceID.changeWithoutMerge(deviceID) }
                result("changeWithoutMerge!")
            }

        // MARK: Networking

        case "setHttpPostForced":
            DispatchQueue.main.async {
                self.config.alwaysUsePOST = (self.boolean(command, 0) ?? false)
                result("setHttpPostForced!")
            }

        case "enableParameterTamperingProtection":
            DispatchQueue.main.async {
                self.config.secretSalt = self.string(command, 0)
                result("enableParameterTamperingProtection!")
            }

        case "setLoggingEnabled":
            DispatchQueue.main.async {
                self.config.enableDebug = (self.boolean(command, 0) ?? false)
                result("setLoggingEnabled!")
            }

        case "attemptToSendStoredRequests":
            DispatchQueue.main.async { cly.requestQueue.attemptToSendStoredRequests() }
            result("attemptToSendStoredRequests: success")

        case "addCustomNetworkRequestHeaders":
            DispatchQueue.main.async {
                cly.addCustomNetworkRequestHeaders(self.dictionary(command, 0) as? [String: String])
                result(nil)
            }

        case "recordMetrics":
            DispatchQueue.main.async {
                cly.recordMetrics(self.dictionary(command, 0) as? [String: String])
                result(nil)
            }

        case "replaceAllAppKeysInQueueWithCurrentAppKey":
            DispatchQueue.main.async { cly.requestQueue.replaceAllAppKeysInQueueWithCurrentAppKey() }
            result("replaceAllAppKeysInQueueWithCurrentAppKey: success")

        case "removeDifferentAppKeysFromQueue":
            DispatchQueue.main.async { cly.requestQueue.removeDifferentAppKeysFromQueue() }
            result("removeDifferentAppKeysFromQueue: success")

        // MARK: Location

        case "setLocationInit":
            DispatchQueue.main.async {
                if let locationString = self.string(command, 2), locationString.contains(",") {
                    let coordinate = self.coordinate(from: locationString)
                    if CLLocationCoordinate2DIsValid(coordinate) { self.config.location = coordinate }
                }
                if let city = self.string(command, 1) { self.config.city = city }
                if let countryCode = self.string(command, 0) { self.config.isoCountryCode = countryCode }
                if let ipAddress = self.string(command, 3) { self.config.ipAddress = ipAddress }
                result("setLocationInit!")
            }

        case "setLocation":
            DispatchQueue.main.async {
                if let latitude = self.string(command, 0), let longitude = self.string(command, 1) {
                    self.config.location = CLLocationCoordinate2D(latitude: (latitude as NSString).doubleValue,
                                                                  longitude: (longitude as NSString).doubleValue)
                }
                result("setLocation!")
            }

        case "setUserLocation":
            DispatchQueue.main.async {
                let location = self.dictionary(command, 0) ?? [:]
                let coordinate = self.coordinate(from: location["gpsCoordinates"] as? String)
                let city = (location["city"] as? String).flatMap { $0.isEmpty ? nil : $0 }
                let countryCode = (location["countryCode"] as? String).flatMap { $0.isEmpty ? nil : $0 }
                let ipAddress = (location["ipAddress"] as? String).flatMap { $0.isEmpty ? nil : $0 }
                cly.location.recordLocation(coordinate, city: city, isoCountryCode: countryCode, ipAddress: ipAddress)
                result("setUserLocation!")
            }

        case "disableLocation":
            DispatchQueue.main.async {
                cly.location.disableLocationInfo()
                result("disableLocation!")
            }

        case "setOptionalParametersForInitialization":
            DispatchQueue.main.async {
                let city = self.string(command, 0)
                let country = self.string(command, 1)
                let latitude = self.string(command, 2)
                let longitude = self.string(command, 3)
                let ipAddress = self.string(command, 4)

                var coordinate = kCLLocationCoordinate2DInvalid
                if let latitude, let longitude {
                    coordinate = CLLocationCoordinate2D(latitude: (latitude as NSString).doubleValue,
                                                        longitude: (longitude as NSString).doubleValue)
                }
                cly.location.recordLocation(coordinate, city: city, isoCountryCode: country, ipAddress: ipAddress)
                result("setOptionalParametersForInitialization!")
            }

        // MARK: Crashes

        case "enableCrashReporting":
            DispatchQueue.main.async {
                self.addCountlyFeature(.crashReporting, on: self.config)
                result("enableCrashReporting!")
            }

        case "addCrashLog":
            DispatchQueue.main.async {
                if let record = self.string(command, 0) { cly.crashes.addCrashBreadcrumb(record) }
                result("addCrashLog!")
            }

        case "logException":
            DispatchQueue.main.async {
                guard let exception = self.string(command, 0) else { result("logException!"); return }
                let isFatal = !(self.boolean(command, 1) ?? false)
                let stackTrace = exception.components(separatedBy: "\n")
                let segmentation = self.segmentation(from: command, startingAt: 2)
                let nsException = NSException(name: NSExceptionName("Exception"), reason: exception, userInfo: nil)
                cly.crashes.recordException(nsException, isFatal: isFatal, stackTrace: stackTrace, segmentation: segmentation)
                result("logException!")
            }

        case "setCustomCrashSegment":
            DispatchQueue.main.async {
                self.config.crashSegmentation = self.segmentation(from: command, startingAt: 0)
            }
            result("setCustomCrashSegment!")

        case "throwNativeException":
            DispatchQueue.main.async {
                NSException(name: NSExceptionName("Native Exception Crash!"), reason: "Throw Native Exception...", userInfo: nil).raise()
            }

        // MARK: User profile, legacy API

        case "setuserdata":
            DispatchQueue.main.async {
                cly.userProfile.setProperties(self.dictionary(command, 0) ?? [:])
                cly.userProfile.save()
                result("setuserdata!")
            }

        case "userData_setProperty":
            DispatchQueue.main.async {
                if let key = self.string(command, 0) {
                    cly.userProfile.setCustomProperty(key, value: self.string(command, 1))
                    cly.userProfile.save()
                }
                result("userData_setProperty!")
            }

        case "userData_increment":
            DispatchQueue.main.async {
                if let key = self.string(command, 0) {
                    cly.userProfile.increment(key)
                    cly.userProfile.save()
                }
                result("userData_increment!")
            }

        case "userData_incrementBy":
            DispatchQueue.main.async {
                if let key = self.string(command, 0) {
                    cly.userProfile.incrementBy(key, value: self.number(command, 1)?.doubleValue ?? 0)
                    cly.userProfile.save()
                }
                result("userData_incrementBy!")
            }

        case "userData_multiply":
            DispatchQueue.main.async {
                if let key = self.string(command, 0) {
                    cly.userProfile.multiply(key, value: self.number(command, 1)?.doubleValue ?? 0)
                    cly.userProfile.save()
                }
                result("userData_multiply!")
            }

        case "userData_saveMax":
            DispatchQueue.main.async {
                if let key = self.string(command, 0) {
                    cly.userProfile.max(key, value: self.number(command, 1)?.doubleValue ?? 0)
                    cly.userProfile.save()
                }
                result("userData_saveMax!")
            }

        case "userData_saveMin":
            DispatchQueue.main.async {
                if let key = self.string(command, 0) {
                    cly.userProfile.min(key, value: self.number(command, 1)?.doubleValue ?? 0)
                    cly.userProfile.save()
                }
                result("userData_saveMin!")
            }

        case "userData_setOnce":
            DispatchQueue.main.async {
                if let key = self.string(command, 0), let value = self.string(command, 1) {
                    cly.userProfile.setOnce(key, value: value)
                    cly.userProfile.save()
                }
                result("userData_setOnce!")
            }

        case "userData_pushUniqueValue":
            DispatchQueue.main.async {
                if let key = self.string(command, 0), let value = self.string(command, 1) {
                    cly.userProfile.pushUnique(key, value: value)
                    cly.userProfile.save()
                }
                result("userData_pushUniqueValue!")
            }

        case "userData_pushValue":
            DispatchQueue.main.async {
                if let key = self.string(command, 0), let value = self.string(command, 1) {
                    cly.userProfile.push(key, value: value)
                    cly.userProfile.save()
                }
                result("userData_pushValue!")
            }

        case "userData_pullValue":
            DispatchQueue.main.async {
                if let key = self.string(command, 0), let value = self.string(command, 1) {
                    cly.userProfile.pull(key, value: value)
                    cly.userProfile.save()
                }
                result("userData_pullValue!")
            }

        // MARK: User profile

        case "userProfile_setProperties":
            DispatchQueue.main.async {
                cly.userProfile.setProperties(self.dictionary(command, 0) ?? [:])
                result(nil)
            }

        case "userProfile_setProperty":
            DispatchQueue.main.async {
                // Passed through uncoerced: the Objective-C NSNumber type was never
                // enforced, so a non-numeric value must not become 0.
                if let key = self.string(command, 0) {
                    cly.userProfile.setCustomProperty(key, value: self.value(command, 1))
                }
                result(nil)
            }

        case "userProfile_increment":
            DispatchQueue.main.async {
                if let key = self.string(command, 0) { cly.userProfile.increment(key) }
                result(nil)
            }

        case "userProfile_incrementBy":
            DispatchQueue.main.async {
                if let key = self.string(command, 0) {
                    cly.userProfile.incrementBy(key, value: self.number(command, 1)?.doubleValue ?? 0)
                }
                result(nil)
            }

        case "userProfile_multiply":
            DispatchQueue.main.async {
                if let key = self.string(command, 0) {
                    cly.userProfile.multiply(key, value: self.number(command, 1)?.doubleValue ?? 0)
                }
                result(nil)
            }

        case "userProfile_saveMax":
            DispatchQueue.main.async {
                if let key = self.string(command, 0) {
                    cly.userProfile.max(key, value: self.number(command, 1)?.doubleValue ?? 0)
                }
                result(nil)
            }

        case "userProfile_saveMin":
            DispatchQueue.main.async {
                if let key = self.string(command, 0) {
                    cly.userProfile.min(key, value: self.number(command, 1)?.doubleValue ?? 0)
                }
                result(nil)
            }

        case "userProfile_setOnce":
            DispatchQueue.main.async {
                if let key = self.string(command, 0), let value = self.value(command, 1) {
                    cly.userProfile.setOnce(key, value: value)
                }
                result(nil)
            }

        case "userProfile_pushUnique":
            DispatchQueue.main.async {
                if let key = self.string(command, 0), let value = self.value(command, 1) {
                    cly.userProfile.pushUnique(key, value: value)
                }
                result(nil)
            }

        case "userProfile_push":
            DispatchQueue.main.async {
                if let key = self.string(command, 0), let value = self.value(command, 1) {
                    cly.userProfile.push(key, value: value)
                }
                result(nil)
            }

        case "userProfile_pull":
            DispatchQueue.main.async {
                if let key = self.string(command, 0), let value = self.value(command, 1) {
                    cly.userProfile.pull(key, value: value)
                }
                result(nil)
            }

        case "userProfile_save":
            DispatchQueue.main.async { cly.userProfile.save(); result(nil) }

        case "userProfile_clear":
            DispatchQueue.main.async { cly.userProfile.clear(); result(nil) }

        // MARK: Consent

        case "setRequiresConsent":
            DispatchQueue.main.async {
                self.config.requiresConsent = (self.boolean(command, 0) ?? false)
                result("setRequiresConsent!")
            }

        case "giveConsentInit":
            DispatchQueue.main.async {
                self.config.consents = self.consentFeatures(from: command)
                result("giveConsentInit!")
            }

        case "giveConsent":
            DispatchQueue.main.async {
                cly.consent.giveConsent(for: self.consentFeatures(from: command))
                result("giveConsent!")
            }

        case "removeConsent":
            DispatchQueue.main.async {
                cly.consent.cancelConsent(for: self.consentFeatures(from: command))
                result("removeConsent!")
            }

        case "giveAllConsent":
            DispatchQueue.main.async { cly.consent.giveAllConsents(); result("giveAllConsent!") }

        case "removeAllConsent":
            DispatchQueue.main.async { cly.consent.cancelAllConsents(); result("removeAllConsent!") }

        // MARK: Remote config

        case "setRemoteConfigAutomaticDownload":
            // Answered right away: the setting only takes effect at start, so waiting for a download would hang a post-start call.
            DispatchQueue.main.async {
                self.config.enableRemoteConfigAutomaticTriggers = true
                result("setRemoteConfigAutomaticDownload: success")
            }

        case "remoteConfigUpdate":
            DispatchQueue.main.async {
                cly.remoteConfig.downloadKeys { _, error, _, _ in
                    result(error.map { "Error :" + String(describing: $0) } ?? "Success!")
                }
            }

        case "updateRemoteConfigForKeysOnly":
            DispatchQueue.main.async {
                let keys = command.compactMap { $0 as? String }
                cly.remoteConfig.downloadSpecificKeys(keys) { _, error, _, _ in
                    result(error.map { "Error :" + String(describing: $0) } ?? "Success!")
                }
            }

        case "updateRemoteConfigExceptKeys":
            DispatchQueue.main.async {
                let keys = command.compactMap { $0 as? String }
                cly.remoteConfig.downloadOmittingKeys(keys) { _, error, _, _ in
                    result(error.map { "Error :" + String(describing: $0) } ?? "Success!")
                }
            }

        case "remoteConfigClearValues", "remoteConfigClearAllValues":
            DispatchQueue.main.async {
                cly.remoteConfig.clearAll()
                result("Success!")
            }

        case "getRemoteConfigValueForKey":
            DispatchQueue.main.async {
                guard let key = self.string(command, 0) else { result("Default Value"); return }
                guard let value = cly.remoteConfig.getValue(key).value else {
                    result("Default Value")
                    return
                }
                result(value as? String ?? String(describing: value))
            }

        case "remoteConfigDownloadValues":
            DispatchQueue.main.async {
                let callbackID = self.number(command, 0) ?? 0
                cly.remoteConfig.downloadKeys { response, error, fullValueUpdate, values in
                    self.remoteConfigDownloadCallback(callbackID, instanceName: instanceName, result: response, fullValueUpdate: fullValueUpdate,
                                                      error: error, downloadedValues: values)
                }
                result("success")
            }

        case "remoteConfigDownloadSpecificValue":
            DispatchQueue.main.async {
                let callbackID = self.number(command, 0) ?? 0
                let keys = self.stringArray(command, 1)
                cly.remoteConfig.downloadSpecificKeys(keys) { response, error, fullValueUpdate, values in
                    self.remoteConfigDownloadCallback(callbackID, instanceName: instanceName, result: response, fullValueUpdate: fullValueUpdate,
                                                      error: error, downloadedValues: values)
                }
                result("Success!")
            }

        case "remoteConfigDownloadOmittingValues":
            DispatchQueue.main.async {
                let callbackID = self.number(command, 0) ?? 0
                let keys = self.stringArray(command, 1)
                cly.remoteConfig.downloadOmittingKeys(keys) { response, error, fullValueUpdate, values in
                    self.remoteConfigDownloadCallback(callbackID, instanceName: instanceName, result: response, fullValueUpdate: fullValueUpdate,
                                                      error: error, downloadedValues: values)
                }
                result("Success!")
            }

        case "remoteConfigGetAllValues":
            DispatchQueue.main.async { result(self.map(cly.remoteConfig.getAllValues())) }

        case "remoteConfigGetValue":
            DispatchQueue.main.async {
                guard let key = self.string(command, 0) else { result(nil); return }
                result(self.map(cly.remoteConfig.getValue(key)))
            }

        case "remoteConfigGetValueAndEnroll":
            DispatchQueue.main.async {
                guard let key = self.string(command, 0) else { result(nil); return }
                result(self.map(cly.remoteConfig.getValueAndEnroll(key)))
            }

        case "remoteConfigGetAllValuesAndEnroll":
            DispatchQueue.main.async { result(self.map(cly.remoteConfig.getAllValuesAndEnroll())) }

        case "remoteConfigEnrollIntoABTestsForKeys":
            DispatchQueue.main.async {
                cly.remoteConfig.enrollIntoABTests(forKeys: self.stringArray(command, 0))
                result("Success!")
            }

        case "remoteConfigExitABTestsForKeys":
            DispatchQueue.main.async {
                cly.remoteConfig.exitABTests(forKeys: self.stringArray(command, 0))
                result("Success!")
            }

        case "remoteConfigTestingGetVariantsForKey":
            DispatchQueue.main.async {
                guard let key = self.string(command, 0) else { result([]); return }
                result(cly.remoteConfig.testingGetVariants(forKey: key))
            }

        case "remoteConfigTestingGetAllVariants":
            DispatchQueue.main.async { result(cly.remoteConfig.testingGetAllVariants()) }

        case "remoteConfigTestingDownloadVariantInformation":
            DispatchQueue.main.async {
                let callbackID = self.number(command, 0) ?? 0
                cly.remoteConfig.testingDownloadVariantInformation { response, error in
                    self.remoteConfigVariantCallback(callbackID, instanceName: instanceName, result: response, error: error)
                }
                result("Success!")
            }

        case "remoteConfigTestingEnrollIntoVariant":
            DispatchQueue.main.async {
                let callbackID = self.number(command, 0) ?? 0
                guard let key = self.string(command, 1), let variantName = self.string(command, 2) else {
                    result("Success!")
                    return
                }
                cly.remoteConfig.testingEnrollIntoVariant(key: key, variantName: variantName) { response, error in
                    self.remoteConfigVariantCallback(callbackID, instanceName: instanceName, result: response, error: error)
                }
                result("Success!")
            }

        case "testingDownloadExperimentInformation":
            DispatchQueue.main.async {
                let callbackID = self.number(command, 0) ?? 0
                cly.remoteConfig.testingDownloadExperimentInformation { response, error in
                    self.remoteConfigVariantCallback(callbackID, instanceName: instanceName, result: response, error: error)
                }
                result("Success!")
            }

        case "testingGetAllExperimentInfo":
            DispatchQueue.main.async {
                let experiments = cly.remoteConfig.testingGetAllExperimentInfo()
                let payload = experiments.values.map { experiment -> [String: Any] in
                    [
                        "experimentID": experiment.experimentID,
                        "experimentName": experiment.experimentName,
                        "experimentDescription": experiment.experimentDescription,
                        "currentVariant": experiment.currentVariant,
                        "variants": experiment.variants,
                    ]
                }
                result(payload)
            }

        // MARK: Star rating, dropped from the Swift SDK

        case "askForStarRating":
            unavailable("askForStarRating", "the star rating dialog is not part of the Swift SDK, use a rating widget instead", result)

        case "setStarRatingDialogTexts":
            unavailable("setStarRatingDialogTexts", "the star rating dialog is not part of the Swift SDK, use a rating widget instead", result)

        // MARK: Feedback

        case "presentRatingWidgetWithID":
            // Like the Android SDK: exactly the rating widget with this ID, or an error, never another widget.
            DispatchQueue.main.async {
                guard let widgetID = self.string(command, 0), !widgetID.isEmpty else {
                    result("presentRatingWidgetWithID failed: no widget id given")
                    return
                }
                cly.feedback.getAvailableFeedbackWidgets { widgets, error in
                    guard error == nil, let widget = widgets?.first(where: { $0.id == widgetID && $0.type == .rating }) else {
                        let message = "presentRatingWidgetWithID failed: " + (error.map { String(describing: $0) } ?? "no rating widget with the id [\(widgetID)]")
                        result(message)
                        Self.channel?.invokeMethod("ratingWidgetCallback", arguments: Self.tagged(instanceName, ["error": message]))
                        return
                    }
                    widget.present(callback: { state in
                        if state == .appeared {
                            Self.channel?.invokeMethod("ratingWidgetCallback", arguments: Self.tagged(instanceName))
                        }
                    })
                    result("presentRatingWidgetWithID success.")
                }
            }

        case "getAvailableFeedbackWidgets":
            DispatchQueue.main.async {
                cly.feedback.getAvailableFeedbackWidgets { widgets, _ in
                    let listed = widgets ?? []
                    self.feedbackWidgetLists[instanceName ?? ""] = listed
                    result(listed.map { ["id": $0.id, "type": $0.type.wireName, "name": $0.name] })
                }
            }

        case "presentFeedbackWidget":
            DispatchQueue.main.async {
                guard let widgetID = self.string(command, 0) else { result(nil); return }
                guard let widget = self.findFeedbackWidget(instanceName, widgetID) else {
                    let message = self.missingWidget("presentFeedbackWidget", widgetID)
                    result(message)
                    return
                }
                widget.present(appearBlock: {
                    Self.channel?.invokeMethod("widgetShown", arguments: Self.tagged(instanceName))
                    result("appeared")
                }, dismissBlock: {
                    Self.channel?.invokeMethod("widgetClosed", arguments: Self.tagged(instanceName))
                    result("dismissed")
                })
            }

        case "presentNPS", "presentSurvey", "presentRating":
            DispatchQueue.main.async {
                let nameIDorTag = self.string(command, 0) ?? ""
                let callback: WidgetCallback = { state in
                    let arguments = Self.tagged(instanceName)
                    if state == .closed {
                        Self.channel?.invokeMethod("feedbackCallback_onClosed", arguments: arguments)
                    } else {
                        Self.channel?.invokeMethod("feedbackCallback_onFinished", arguments: arguments)
                    }
                }
                switch call.method {
                case "presentNPS": cly.feedback.presentNPS(nameIDorTag, callback: callback)
                case "presentSurvey": cly.feedback.presentSurvey(nameIDorTag, callback: callback)
                default: cly.feedback.presentRating(nameIDorTag, callback: callback)
                }
                result("[CountlyFlutterPlugin] \(call.method), success")
            }

        case "getFeedbackWidgetData":
            DispatchQueue.main.async {
                guard let widgetID = self.string(command, 0) else { result(nil); return }
                guard let widget = self.findFeedbackWidget(instanceName, widgetID) else {
                    let message = self.missingWidget("getFeedbackWidgetData", widgetID)
                    result(message)
                    self.feedbackWidgetDataCallback(nil, instanceName: instanceName, error: message)
                    return
                }
                widget.getWidgetData { widgetData, error in
                    if let error {
                        let message = "getFeedbackWidgetData failed: " + String(describing: error)
                        result(message)
                        self.feedbackWidgetDataCallback(nil, instanceName: instanceName, error: message)
                    } else {
                        result(widgetData)
                        self.feedbackWidgetDataCallback(widgetData, instanceName: instanceName, error: nil)
                    }
                }
            }

        case "reportFeedbackWidgetManually":
            DispatchQueue.main.async {
                guard let widgetInfo = self.array(command, 0), let widgetID = widgetInfo.first as? String else {
                    result(nil)
                    return
                }
                guard let widget = self.findFeedbackWidget(instanceName, widgetID) else {
                    let message = self.missingWidget("reportFeedbackWidgetManually", widgetID)
                    result(message)
                    return
                }
                widget.recordResult(self.dictionary(command, 2))
                result(nil)
            }

        // MARK: Performance monitoring

        case "startTrace":
            DispatchQueue.main.async {
                if let traceKey = self.string(command, 0) { cly.performance.startCustomTrace(traceKey) }
            }
            result("startTrace: success")

        case "cancelTrace":
            DispatchQueue.main.async {
                if let traceKey = self.string(command, 0) { cly.performance.cancelCustomTrace(traceKey) }
            }
            result("cancelTrace: success")

        case "clearAllTraces":
            DispatchQueue.main.async { cly.performance.clearAllCustomTraces() }
            result("clearAllTrace: success")

        case "endTrace":
            DispatchQueue.main.async {
                guard let traceKey = self.string(command, 0) else { return }
                let metrics = self.segmentation(from: command, startingAt: 1)
                    .compactMapValues { ($0 as? NSNumber)?.intValue ?? Int(($0 as? String) ?? "") }
                cly.performance.endCustomTrace(traceKey, metrics: metrics)
            }
            result("endTrace: success")

        case "recordNetworkTrace":
            DispatchQueue.main.async {
                guard let traceKey = self.string(command, 0) else { return }
                cly.performance.recordNetworkTrace(
                    traceKey,
                    requestPayloadSize: self.number(command, 2)?.intValue ?? 0,
                    responsePayloadSize: self.number(command, 3)?.intValue ?? 0,
                    responseStatusCode: self.number(command, 1)?.intValue ?? 0,
                    startTime: self.number(command, 4)?.int64Value ?? 0,
                    endTime: self.number(command, 5)?.int64Value ?? 0)
            }
            result("recordNetworkTrace: success")

        case "appLoadingFinished":
            DispatchQueue.main.async { cly.performance.appLoadingFinished() }
            result("appLoadingFinished: success")

        case "enableApm":
            // The deprecated Objective-C master switch only set these three.
            DispatchQueue.main.async { self.setPerformanceMonitoringEnabled(true, on: self.config) }
            result("enableApm: success")

        // MARK: Attribution

        case "recordDirectAttribution":
            DispatchQueue.main.async {
                guard let campaignType = self.string(command, 0), let campaignData = self.string(command, 1) else {
                    result(nil)
                    return
                }
                if cly.isStarted {
                    cly.attribution.recordDirectAttribution(campaignType: campaignType, campaignData: campaignData)
                } else {
                    self.config.campaignType = campaignType
                    self.config.campaignData = campaignData
                }
                result(nil)
            }

        case "recordIndirectAttribution":
            DispatchQueue.main.async {
                let attribution = self.dictionary(command, 0) as? [String: String] ?? [:]
                if cly.isStarted {
                    cly.attribution.recordIndirectAttribution(attribution)
                } else {
                    self.config.indirectAttribution = attribution
                }
                result(nil)
            }

        // MARK: Content

        case "enterContentZone":
            DispatchQueue.main.async { cly.content.enterContentZone(); result(nil) }

        case "exitContentZone":
            DispatchQueue.main.async { cly.content.exitContentZone(); result(nil) }

        case "refreshContentZone":
            DispatchQueue.main.async { cly.content.refreshContentZone(); result(nil) }

        case "previewContent":
            DispatchQueue.main.async {
                let contentID = arguments?["contentId"] as? String ?? ""
                cly.content.previewContent(contentID)
                result(nil)
            }

        // MARK: Push

        case "disablePushNotifications":
            #if !COUNTLY_EXCLUDE_PUSHNOTIFICATIONS
            CountlyFLPushNotifications.shared.disablePushNotifications()
            #endif
            result("disablePushNotifications!")

        case "askForNotificationPermission":
            #if !COUNTLY_EXCLUDE_PUSHNOTIFICATIONS
            CountlyFLPushNotifications.shared.askForNotificationPermission()
            #endif
            result("askForNotificationPermission!")

        case "pushTokenType":
            #if !COUNTLY_EXCLUDE_PUSHNOTIFICATIONS
            DispatchQueue.main.async {
                self.config.sendPushTokenAlways = true
                switch self.string(command, 0) {
                case "1": self.config.pushTestMode = .development
                case "2": self.config.pushTestMode = .testFlightOrAdHoc
                default: self.config.pushTestMode = nil
                }
            }
            #endif
            result("pushTokenType!")

        case "registerForNotification":
            #if !COUNTLY_EXCLUDE_PUSHNOTIFICATIONS
            log("registerForNotification")
            CountlyFLPushNotifications.shared.registerForNotification(result)
            #else
            result(nil)
            #endif

        default:
            result(FlutterMethodNotImplemented)
        }
    }

    // MARK: - Config

    /// Translates the Dart config map onto `CountlyConfig`.
    private func populateConfig(_ configMap: [String: Any], into config: CountlyConfig, instanceName: String?) {
        if let appKey = configMap["appKey"] as? String { config.appKey = appKey }
        if let host = configMap["serverURL"] as? String { config.host = host }

        if let deviceID = configMap["deviceID"] as? String {
            if deviceID == "CLYTemporaryDeviceID" {
                config.temporaryDeviceIDMode = true
            } else {
                config.deviceID = deviceID
            }
        }

        if let loggingEnabled = configMap["loggingEnabled"] as? Bool { config.enableDebug = loggingEnabled }
        if let locationDisabled = configMap["locationDisabled"] as? Bool { config.disableLocation = locationDisabled }
        if let httpPostForced = configMap["httpPostForced"] as? Bool { config.alwaysUsePOST = httpPostForced }
        if let headers = configMap["customNetworkRequestHeaders"] as? [String: String] {
            config.customNetworkRequestHeaders = headers
        }

        if let requiresConsent = configMap["shouldRequireConsent"] as? Bool { config.requiresConsent = requiresConsent }
        if let enableAllConsents = configMap["enableAllConsents"] as? Bool {
            config.enableAllConsents = enableAllConsents
        } else if let consents = configMap["consents"] as? [String] {
            config.consents = consentFeatures(from: consents)
        }

        if let threshold = configMap["eventQueueSizeThreshold"] as? Int { config.eventSendThreshold = threshold }
        if let delay = configMap["sessionUpdateTimerDelay"] as? Int { config.updateSessionPeriod = TimeInterval(delay) }
        if let salt = configMap["tamperingProtectionSalt"] as? String { config.secretSalt = salt }
        if let crashSegmentation = configMap["customCrashSegment"] as? [String: Any] {
            config.crashSegmentation = crashSegmentation
        }

        if let providedUserProperties = configMap["providedUserProperties"] as? [String: Any] {
            config.providedUserProperties = providedUserProperties
        }

        if configMap["starRatingTextMessage"] != nil {
            log("[populateConfig] starRatingTextMessage is ignored, the star rating dialog is not part of the Swift SDK")
        }

        // The deprecated Objective-C master switch only set these three.
        if let recordAppStartTime = configMap["recordAppStartTime"] as? Bool {
            setPerformanceMonitoringEnabled(recordAppStartTime, on: config)
        }
        if let enableForegroundBackground = configMap["enableForegroundBackground"] as? Bool {
            config.apm.enableForegroundBackgroundTracking = enableForegroundBackground
        }
        if let enableManualAppLoaded = configMap["enableManualAppLoaded"] as? Bool {
            config.apm.enableManualAppLoadedTrigger = enableManualAppLoaded
        }
        if let trackAppStartTime = configMap["trackAppStartTime"] as? Bool {
            config.apm.enableAppStartTimeTracking = trackAppStartTime
        }
        if let startTSOverride = configMap["startTSOverride"] as? NSNumber {
            config.apm.appStartTimestampOverride = startTSOverride.int64Value
        }

        if let sdkBehaviorSettings = configMap["sdkBehaviorSettings"] as? String {
            config.sdkBehaviorSettings = sdkBehaviorSettings
        }
        if let backoffDisabled = configMap["backoffMechanismDisabled"] as? Bool, backoffDisabled {
            config.disableBackoffMechanism = true
        }
        if configMap["sdkBehaviorSettingsUpdatesDisabled"] != nil {
            config.disableSDKBehaviorSettingsUpdates = true
        }

        // Internal limits
        if let value = configMap["maxKeyLength"] as? Int { config.sdkInternalLimits.maxKeyLength = value }
        if let value = configMap["maxValueSize"] as? Int { config.sdkInternalLimits.maxValueSize = value }
        if let value = configMap["maxSegmentationValues"] as? Int { config.sdkInternalLimits.maxSegmentationValues = value }
        if let value = configMap["maxBreadcrumbCount"] as? Int { config.sdkInternalLimits.maxBreadcrumbCount = value }
        if let value = configMap["maxStackTraceLineLength"] as? Int { config.sdkInternalLimits.maxStackTraceLineLength = value }
        if let value = configMap["maxStackTraceLinesPerThread"] as? Int { config.sdkInternalLimits.maxStackTraceLinesPerThread = value }

        if let enableUnhandledCrashReporting = configMap["enableUnhandledCrashReporting"] as? Bool, enableUnhandledCrashReporting {
            addCountlyFeature(.crashReporting, on: config)
        }

        if let value = configMap["maxRequestQueueSize"] as? Int { config.storedRequestsLimit = value }
        if let value = configMap["requestDropAgeHours"] as? Int { config.requestDropAgeHours = value }
        if let value = configMap["requestTimeoutDuration"] as? Int { config.requestTimeoutDuration = TimeInterval(value) }

        if let manualSessionEnabled = configMap["manualSessionEnabled"] as? Bool, manualSessionEnabled {
            config.manualSessionHandling = true
        }


        // Captured, so the long-lived callback does not retain the whole config map.
        // The deprecated automatic download callback has one static slot on the Dart side, for the default instance.
        let notifiesDart = configMap["enableRemoteConfigAutomaticDownload"] as? Bool == true && instanceName == nil
        config.remoteConfigRegisterGlobalCallback { [weak self] response, error, fullValueUpdate, downloadedValues in
            guard let self else { return }
            self.remoteConfigDownloadCallback(NSNumber(value: -2), instanceName: instanceName, result: response, fullValueUpdate: fullValueUpdate,
                                              error: error, downloadedValues: downloadedValues)
            if notifiesDart {
                Self.channel?.invokeMethod("remoteConfigCallback", arguments: error.map { String(describing: $0) })
            }
        }

        // Two Dart keys feed one flag; the native SDK ORs them rather than
        // letting the second assignment win.
        let automaticTriggers = configMap["remoteConfigAutomaticTriggers"] as? Bool ?? false
        config.enableRemoteConfigAutomaticTriggers = notifiesDart || automaticTriggers
        if let caching = configMap["remoteConfigValueCaching"] as? Bool {
            config.enableRemoteConfigValueCaching = caching
        }
        if let autoEnroll = configMap["autoEnrollABOnDownload"] as? Bool, autoEnroll {
            config.enrollABOnRCDownload = true
        }

        if let globalViewSegmentation = configMap["globalViewSegmentation"] as? [String: Any] {
            config.globalViewSegmentation = globalViewSegmentation
        }
        if let disableViewRestart = configMap["disableViewRestartForManualRecording"] as? Bool, disableViewRestart {
            config.disableViewRestartForManualRecording = true
        }

        let configuredLocation = coordinate(from: configMap["locationGpsCoordinates"] as? String)
        if CLLocationCoordinate2DIsValid(configuredLocation) { config.location = configuredLocation }
        if let city = configMap["locationCity"] as? String { config.city = city }
        if let countryCode = configMap["locationCountryCode"] as? String { config.isoCountryCode = countryCode }
        if let ipAddress = configMap["locationIpAddress"] as? String { config.ipAddress = ipAddress }

        if let campaignType = configMap["campaignType"] as? String {
            config.campaignType = campaignType
            config.campaignData = configMap["campaignData"] as? String
        }
        if let attributionValues = configMap["attributionValues"] as? [String: String] {
            config.indirectAttribution = attributionValues
        }

        if let visibilityTracking = configMap["visibilityTracking"] as? Bool {
            config.experimental.enableVisibilityTracking = visibilityTracking
        }
        if let previousNameRecording = configMap["previousNameRecording"] as? Bool {
            config.experimental.enablePreviousNameRecording = previousNameRecording
        }

        config.content.globalContentCallback = { status, data in
            let arguments = Self.tagged(instanceName, [
                "contentResult": status == .closed ? 1 : 0,
                "contentData": data,
            ])
            Self.channel?.invokeMethod("contentCallback", arguments: arguments)
        }

        if let zoneTimerInterval = configMap["zoneTimerInterval"] as? Int {
            config.content.zoneTimerInterval = zoneTimerInterval
        }
        if let displayOption = configMap["webviewDisplayOption"] as? String {
            switch displayOption {
            case "IMMERSIVE": config.content.webViewDisplayOption = .immersive
            case "SAFE_AREA": config.content.webViewDisplayOption = .safeArea
            default: break
            }
        }
    }
}
