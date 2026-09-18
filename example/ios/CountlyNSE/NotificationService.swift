//
//  NotificationService.swift
//  CountlyNSE
//
//  This code is provided under the MIT License.
//
//  Please visit www.count.ly for more information.
//

import CountlyNotificationService
import UserNotifications

/// Notification service extension that lets the Countly SDK decorate an incoming
/// notification with its action buttons and media attachment.
///
/// The SDK owns delivery from here, including its own deadline and a guarantee that
/// the content handler runs exactly once, so there is no expiry handling to add. A
/// local best-attempt copy would never receive the SDK's changes and could only
/// deliver the notification undecorated.
@objc(NotificationService)
class NotificationService: UNNotificationServiceExtension {

    override func didReceive(_ request: UNNotificationRequest,
                             withContentHandler contentHandler: @escaping (UNNotificationContent) -> Void) {
        CountlyNotificationService.didReceive(request, withContentHandler: contentHandler)
    }
}
