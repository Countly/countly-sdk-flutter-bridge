// CountlyFLPushNotifications.swift
//
// This code is provided under the MIT License.
//
// Please visit www.count.ly for more information.

#if !COUNTLY_EXCLUDE_PUSHNOTIFICATIONS

import Countly
import Flutter
import Foundation
import UserNotifications

/// Bridges push notifications to the Dart side.
///
/// The SDK installs itself as the notification centre delegate and chains to
/// whatever delegate was already there, so this object registers first and is
/// reached as that chained delegate. Once the SDK is in front it records the
/// action and opens the notification's URL itself, and this object only forwards
/// the payload to Dart.
///
/// The one thing it owns is the cold launch case. A tap that opens the application
/// is delivered before Dart has had a chance to call init, so the SDK is not the
/// delegate yet and never sees the response. Those responses are held here and
/// handed to the SDK once init has run.
public class CountlyFLPushNotifications: NSObject {

    @objc public static let shared = CountlyFLPushNotifications()

    /// Whether the plugin should turn the SDK's push feature on at init.
    public var enablePushNotifications = true

    private var notificationListener: FlutterResult?
    private var lastStoredNotification: [AnyHashable: Any]?

    /// Responses that arrived before the SDK was started, awaiting replay. Bounded, since an
    /// application that never starts the SDK would otherwise hold every tap for its lifetime.
    private var pendingResponses: [UNNotificationResponse] = []
    private static let pendingResponsesLimit = 10

    /// The delegate this object displaced, kept so the host application and any
    /// other notification plugin still receive what they registered for.
    private weak var previousDelegate: UNUserNotificationCenterDelegate?

    private override init() {
        super.init()
    }

    /// Stops the SDK's push feature being enabled at init.
    public func disablePushNotifications() {
        DispatchQueue.main.async { self.enablePushNotifications = false }
    }

    /// Registers as the notification centre delegate.
    ///
    /// Must run before the SDK starts, so that the SDK chains to this object
    /// rather than replacing it.
    @objc public func startObservingNotifications() {
        let center = UNUserNotificationCenter.current()
        if center.delegate !== self { previousDelegate = center.delegate }
        center.delegate = self
    }

    /// Asks the user for notification permission.
    public func askForNotificationPermission() {
        DispatchQueue.main.async {
            Countly.shared.push.askForNotificationPermission()
        }
    }

    /// Registers the Dart listener that receives notification payloads, and hands
    /// it anything that arrived before it was registered.
    public func registerForNotification(_ result: @escaping FlutterResult) {
        DispatchQueue.main.async {
            self.notificationListener = result
            if let notification = self.lastStoredNotification {
                result(String(describing: notification))
                self.lastStoredNotification = nil
            }
        }
    }

    /// Replays taps that arrived before the SDK was started.
    ///
    /// The SDK's own handling never saw them, because it was not the notification
    /// centre delegate yet. Handing each response over now runs the same path a
    /// live tap takes, including ignoring a dismissal, resolving the tapped
    /// button's URL, and gating that URL on push consent.
    public func recordPushActions() {
        let responses = pendingResponses
        pendingResponses.removeAll()
        for response in responses {
            Countly.handleNotificationResponse(response)
        }
    }

    /// Hands a notification payload to the Dart listener, or holds it until one
    /// registers.
    public func onNotification(_ notification: [AnyHashable: Any]?) {
        guard let notification else { return }
        lastStoredNotification = notification
        if let listener = notificationListener {
            listener([toJSON(notification)])
        }
    }

    /// Forwards the tap to Dart, holding it for replay if the SDK cannot see it yet.
    public func onNotificationResponse(_ response: UNNotificationResponse) {
        // Hold the response only when the SDK cannot have handled it, so a tap is
        // never both handled live and replayed. The SDK installs itself as the
        // notification centre delegate during start and chains back to this object,
        // so still holding the delegate directly is proof that its handling did not
        // run. The started check alone would leave a window between the SDK
        // subscribing and its instance reporting started.
        let isStillFrontDelegate = UNUserNotificationCenter.current().delegate === self
        if isStillFrontDelegate, !Countly.shared.isStarted {
            pendingResponses.append(response)
            if pendingResponses.count > Self.pendingResponsesLimit {
                pendingResponses.removeFirst(pendingResponses.count - Self.pendingResponsesLimit)
            }
        }

        onNotification(response.notification.request.content.userInfo)
    }

    private func toJSON(_ object: Any) -> String {
        guard JSONSerialization.isValidJSONObject(object),
              let data = try? JSONSerialization.data(withJSONObject: object, options: []),
              let string = String(data: data, encoding: .utf8) else { return "{}" }
        return string
    }
}

extension CountlyFLPushNotifications: UNUserNotificationCenterDelegate {

    /// Reached as the SDK's chained delegate once it has started, and directly
    /// before that.
    public func userNotificationCenter(_ center: UNUserNotificationCenter,
                                       didReceive response: UNNotificationResponse,
                                       withCompletionHandler completionHandler: @escaping () -> Void) {
        onNotificationResponse(response)
        forward(center, didReceive: response, completionHandler: completionHandler)
    }

    private func forward(_ center: UNUserNotificationCenter,
                         didReceive response: UNNotificationResponse,
                         completionHandler: @escaping () -> Void) {
        let selector = #selector(UNUserNotificationCenterDelegate.userNotificationCenter(_:didReceive:withCompletionHandler:))
        guard let previous = previousDelegate, previous.responds(to: selector) else {
            completionHandler()
            return
        }
        previous.userNotificationCenter?(center, didReceive: response, withCompletionHandler: completionHandler)
    }

    public func userNotificationCenter(_ center: UNUserNotificationCenter,
                                       willPresent notification: UNNotification,
                                       withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        let userInfo = notification.request.content.userInfo
        onNotification(userInfo)

        let payload = userInfo[CountlyPushKey.countlyPayload] as? [String: Any]
        let notificationID = payload?[CountlyPushKey.notificationID] as? String

        let selector = #selector(UNUserNotificationCenterDelegate.userNotificationCenter(_:willPresent:withCompletionHandler:))
        if let previous = previousDelegate, previous.responds(to: selector) {
            previous.userNotificationCenter?(center, willPresent: notification, withCompletionHandler: completionHandler)
            return
        }

        if notificationID != nil {
            if #available(iOS 14.0, tvOS 14.0, macOS 11.0, watchOS 7.0, *) {
                completionHandler([.list, .banner])
            } else {
                completionHandler([.alert])
            }
        } else {
            completionHandler([])
        }
    }
}

#endif
