import UIKit
import Flutter
import countly_flutter

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
     func application(application: UIApplication,  didReceiveRemoteNotification userInfo: [NSObject : AnyObject],  fetchCompletionHandler completionHandler: (UIBackgroundFetchResult) -> Void) {

        // print("Recived: \(userInfo)")
        CountlyFlutterPlugin.onNotification(userInfo);
        completionHandler(.newData);

    }
    @available(iOS 10.0, *)
    override func userNotificationCenter(_ center: UNUserNotificationCenter,  willPresent notification: UNNotification, withCompletionHandler   completionHandler: @escaping (_ options:   UNNotificationPresentationOptions) -> Void) {

        //Called when a notification is delivered to a foreground app.

        let userInfo: NSDictionary = notification.request.content.userInfo as NSDictionary
        // print("\(userInfo)")
        CountlyFlutterPlugin.onNotification(userInfo as? [AnyHashable : Any])
     }

    @available(iOS 10.0, *)
    override func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {

        // Called to let your app know which action was selected by the user for a given notification.
        let userInfo: NSDictionary = response.notification.request.content.userInfo as NSDictionary
        // print("\(userInfo)")
        CountlyFlutterPlugin.onNotification(userInfo as? [AnyHashable : Any])
    }
}
